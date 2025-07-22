require 'google/apis/gmail_v1'
require 'googleauth'

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

        matched_sender = preferred_senders.find { |s| from.include?(s.email.downcase) }

        if matched_sender
          ParseGmailMessageJob.perform_later(
            user_id: user_id,
            message_id: msg_id,
            sender: from,
            subject: subject,
            body: '', # optional: can skip sending full body
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
end
