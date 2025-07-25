require 'google/apis/gmail_v1'
require 'googleauth'
require 'signet/oauth_2/client'

class GmailService
  def initialize(user)
    @user = user
    @service = Google::Apis::GmailV1::GmailService.new
    @service.authorization = get_authorization
  end

  def get_user_profile(user_id = 'me')
    @service.get_user_profile(user_id)
  end

  def watch_user(user_id = 'me', watch_request)
    @service.watch_user(user_id, watch_request)
  end

  def list_history(user_id = 'me', start_history_id:)
    @service.list_user_histories(user_id, start_history_id: start_history_id, history_types: ['messageAdded'])
  end

  def get_message(user_id = 'me', message_id)
    @service.get_user_message(user_id, message_id)
  end

  def list_messages(user_id = 'me', max_results: 10)
    @service.list_user_messages(user_id, max_results: max_results)
  end

  private

  def get_authorization
    # Refresh the token if it's expired or missing
    if @user.expire_at.nil? || @user.expire_at < Time.now + 1.minute
      @user.refresh_google_token!
    end

    Google::Auth::UserRefreshCredentials.new(
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      refresh_token: @user.refresh_token,
      access_token: @user.access_token,
      scope: ['https://www.googleapis.com/auth/gmail.readonly']
    )
  end
end