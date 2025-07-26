require 'httparty'
require 'json'
require 'cgi'

class ParseGmailMessageJob < ApplicationJob
  queue_as :default

  def perform(user_id:, message_id:, sender:, subject:, body:, preferred_sender_id:)
    user = User.find(user_id)
    
  
    body = if body.encoding == Encoding::ASCII_8BIT
             body.force_encoding('UTF-8').scrub('')
           else
             body.encode('UTF-8', invalid: :replace, undef: :replace)
           end

    # Remove any remaining invalid characters
    body = CGI.unescapeHTML(body).scrub('')

    prompt = <<~PROMPT
      Analyze this email for academic events and respond with ONLY this JSON format:
      {
        "event_worthy": true/false,
        "title": "Event title",
        "description": "Event description",
        "start_time": "ISO8601 datetime",
        "end_time": "ISO8601 datetime" (optional)
      }

      Today's date: #{Date.current.strftime("%Y-%m-%d")}
      Email subject: #{subject}
      Email body: #{body}
    PROMPT

    # Send request to OpenRouter API
    response = HTTParty.post(
      "https://openrouter.ai/api/v1/chat/completions",
      headers: {
        "Authorization" => "Bearer #{ENV['OPENROUTER_API_KEY']}",
        "HTTP-Referer" => "http://localhost:3000",
        "X-Title" => "Academic Event Parser",
        "Content-Type" => "application/json"
      },
      body: {
        model: "openai/gpt-3.5-turbo",
        messages: [
          {
            role: "system",
            content: <<~SYSTEM_PROMPT
              You extract academic events from emails. Respond ONLY with valid JSON in this format:
              {
                "event_worthy": boolean,
                "title": string,
                "description": string,
                "start_time": "YYYY-MM-DDTHH:MM:SS",
                "end_time": "YYYY-MM-DDTHH:MM:SS" (optional)
              }
              No other text.
            SYSTEM_PROMPT
          },
          { role: "user", content: prompt }
        ],
        temperature: 0.1,
        response_format: { type: "json_object" },
        max_tokens: 300
      }.to_json,
      timeout: 30
    )

    unless response.success?
      Rails.logger.error "OpenRouter API failed: #{response.code} - #{response.body}"
      return
    end

    content = response.dig("choices", 0, "message", "content")
    Rails.logger.info "Raw AI response content: #{content.inspect}"
    return if content.nil?


begin
  json_content = content.gsub(/^```(json)?|```$/, '').strip
  parsed = JSON.parse(json_content)
  Rails.logger.info "Parsed AI response JSON: #{parsed.inspect}"
  event_data = parsed["event"] || parsed

  unless event_data["event_worthy"] && event_data["title"].present? && event_data["start_time"].present?
    Rails.logger.error "Missing fields: #{parsed}"
    return
  end

 
  start_time = Time.parse(event_data["start_time"])
  
  if event_data["title"].downcase.include?("due") || event_data["title"].downcase.include?("deadline") || 
     (event_data["description"] && (event_data["description"].downcase.include?("due") || event_data["description"].downcase.include?("deadline")))
    
    end_time = start_time.end_of_day
  else
    end_time = event_data["end_time"] || (start_time + 30.minutes)
  end

  Event.create!(
    user_id: user.id,
    preferred_email_id: preferred_sender_id,
    title: event_data["title"],
    description: event_data["description"],
    start_time: start_time,
    end_time: end_time
  )

  Rails.logger.info "Event created: #{event_data["title"]} at #{start_time} to #{end_time}"

rescue JSON::ParserError => e
  Rails.logger.error "Invalid JSON: #{content}"
  Rails.logger.error "Error: #{e.message}"

    rescue => e
      Rails.logger.error "Error processing event: #{e.message}"
    end
  end
end