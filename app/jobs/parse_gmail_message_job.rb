require 'httparty'
require 'json'
require 'cgi'

class ParseGmailMessageJob < ApplicationJob
  queue_as :default

  def perform(user_id:, message_id:, sender:, subject:, body:, preferred_sender_id:)
    user = User.find(user_id)
    body = CGI.unescapeHTML(body)

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

    # Handle error responses
    unless response.success?
      Rails.logger.error "OpenRouter API failed: #{response.code} - #{response.body}"
      return
    end

    content = response.dig("choices", 0, "message", "content")
    return if content.nil?

    # Parse and validate response JSON
    begin
      json_content = content.gsub(/^```(json)?|```$/, '').strip
      parsed = JSON.parse(json_content)
      event_data = parsed["event"] || parsed

      unless event_data["event_worthy"] && event_data["title"].present? && event_data["start_time"].present?
        Rails.logger.error "Missing fields: #{parsed}"
        return
      end

      end_time = event_data["end_time"] ||
                 (Time.parse(event_data["start_time"]) + 30.minutes).iso8601

      Event.create!(
        user_id: user.id,
        preferred_email_id: preferred_sender_id,
        title: event_data["title"],
        description: event_data["description"],
        start_time: event_data["start_time"],
        end_time: end_time
      )

      Rails.logger.info "Event created: #{event_data["title"]} at #{event_data["start_time"]}"

    rescue JSON::ParserError => e
      Rails.logger.error "Invalid JSON: #{content}"
      Rails.logger.error "Error: #{e.message}"
    end

  rescue HTTParty::Error => e
    Rails.logger.error "HTTP error: #{e.message}"
    retry_job(wait: 5.minutes) if e.message.include?("429")

  rescue => e
    Rails.logger.error "Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
