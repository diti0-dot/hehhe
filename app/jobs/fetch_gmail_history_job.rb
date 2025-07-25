require 'google/apis/gmail_v1'
require 'googleauth'
require 'cgi'

class FetchGmailHistoryJob < ApplicationJob
  queue_as :default
  retry_on Google::Apis::AuthorizationError, wait: :exponentially_longer, attempts: 3

  def perform(user_id, start_history_id)
    user = User.find(user_id)
    preferred_senders = user.preferred_emails
    service = GmailService.new(user)

    begin
      response = service.list_history('me', start_history_id: start_history_id)

      message_ids = []
      response.history&.each do |h|
        h.messages_added&.each { |msg| message_ids << msg.message.id }
      end

      message_ids.each do |msg_id|
        message = service.get_message('me', msg_id)

        # Extract sender and subject
        headers = message.payload.headers
        from = headers.find { |h| h.name.downcase == 'from' }&.value.to_s.downcase
        subject = headers.find { |h| h.name.downcase == 'subject' }&.value.to_s
        body = extract_body_from_payload(message.payload)

        matched_sender = preferred_senders.find { |s| from.include?(s.email.downcase) }

        if matched_sender
          ParseGmailMessageJob.perform_later(
            user_id: user_id,
            message_id: msg_id,
            sender: from,
            subject: subject,
            body: body, 
            preferred_sender_id: matched_sender.id
          )
        end
      end
    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error "Auth error: #{e.message}"
      raise
    rescue => e
      Rails.logger.error "Fetch error: #{e.message}"
      raise
    end
  end

  private

  def extract_body_from_payload(payload)
    if payload.parts.blank?
      extract_part_body(payload)
    else
      # Look for HTML part first, then plain text
      html_part = find_part(payload.parts, 'text/html')
      text_part = find_part(payload.parts, 'text/plain') unless html_part
      
      part = html_part || text_part
      part ? extract_part_body(part) : ''
    end
  end

  def find_part(parts, mime_type)
    part = parts.find { |p| p.mime_type == mime_type }
    
    # Recursively check nested parts if not found
    if part.nil?
      parts.each do |p|
        if p.parts.present?
          part = find_part(p.parts, mime_type)
          break if part
        end
      end
    end
    
    part
  end

  def extract_part_body(part)
    return '' unless part&.body&.data

    # Handle encoding conversion
    body_data = if part.body.data.encoding == Encoding::ASCII_8BIT
                  part.body.data.force_encoding('UTF-8')
                else
                  part.body.data.encode('UTF-8')
                end

    # Handle Base64 decoding if needed (check for Base64 pattern)
    decoded_body = if body_data =~ %r{[A-Za-z0-9+/]+={0,2}}
                    begin
                      Base64.urlsafe_decode64(body_data).force_encoding('UTF-8')
                    rescue ArgumentError
                      body_data
                    end
                  else
                    body_data
                  end

    # Clean up HTML entities and encoding
    cleaned_body = decoded_body
                  .gsub(/\r\n|\r|\n/, ' ')
                  .gsub(/\xC2\xA0/, ' ') # Replace non-breaking spaces
                  .gsub(/\s+/, ' ')      # Collapse multiple spaces
                  .strip

    # Unescape HTML entities and ensure valid UTF-8
    CGI.unescapeHTML(cleaned_body).scrub('')
  end
end