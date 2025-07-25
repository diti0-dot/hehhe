require 'google/apis/gmail_v1'
require 'googleauth'


class GmailWatchJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(user)
    Rails.logger.info "Setting up Gmail watch for user #{user.id}"
    
    service = GmailService.new(user)
    
    watch_request = Google::Apis::GmailV1::WatchRequest.new(
      topic_name: "projects/#{ENV['GOOGLE_CLOUD_PROJECT']}/topics/gmail-message-triggers",
      label_ids: ['INBOX'],
      label_filter_action: 'include'
    )
    
    begin
      response = service.watch_user('me', watch_request)
      Rails.logger.info "Gmail watch response: #{response.inspect}"
      
      # Convert expiration to Time object
      expiration_time = Time.at(response.expiration.to_i / 1000)
      user.update!(last_watch_expiration: expiration_time)
      
      Rails.logger.info "Gmail watch set up successfully, expires at: #{expiration_time}"
    rescue => e
      Rails.logger.error "Failed to set up Gmail watch: #{e.message}"
      raise
    end
  end
end