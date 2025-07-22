class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:gmail_notification]

  def gmail_notification
    # Log raw params for debugging
    Rails.logger.info "📬 Raw Gmail webhook params: #{params.inspect}"
    
    # Respond immediately to Google
    render plain: "OK" and return unless params[:message]&.dig(:data)

    begin
      encoded_data = params[:message][:data]
      decoded_json = JSON.parse(Base64.decode64(encoded_data))
      Rails.logger.info "📬 Gmail webhook decoded data: #{decoded_json}"

      email_address = decoded_json["emailAddress"]
      new_history_id = decoded_json["historyId"].to_i

      user = User.find_by(email: email_address)

      if user
        # Store the old history_id before updating
        old_history_id = user.last_history_id
        
        # Update stored history_id first
        user.update!(last_history_id: new_history_id)
        
        # Only fetch history if we have a previous history_id
        if old_history_id
          FetchGmailHistoryJob.perform_later(user.id, old_history_id)
        else
          Rails.logger.warn "No previous history_id for user #{user.id}, skipping history fetch"
        end
      else
        Rails.logger.warn "No user found for Gmail address: #{email_address}"
      end

    rescue => e
      Rails.logger.error "Error processing Gmail webhook: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end

    head :ok
  end
end