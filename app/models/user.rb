class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :preferred_emails
  has_many :professor_events, through: :preferred_emails, source: :events
  has_many :personal_events, -> { where(preferred_email: nil) }, class_name: 'Event'
has_many :events

  # Combine all events from professors and personal
  def all_events
    Event.where("(preferred_email_id IN (?) OR user_id = ?)", preferred_email_ids, id)
  end

  # Called when user logs in via Google
  def self.from_omniauth(auth)
    user = where(uid: auth.uid).first_or_initialize

    user.email ||= auth.info.email
    user.password ||= Devise.friendly_token[0, 20]
    user.access_token = auth.credentials.token
    user.expire_at = Time.at(auth.credentials.expires_at) if auth.credentials.expires_at

    if auth.credentials.refresh_token.present?
      user.refresh_token = auth.credentials.refresh_token
    elsif user.refresh_token.blank?
      return nil  # cannot proceed if no refresh token
    end

    user.save!
    GmailWatchJob.perform_later(user)
    user
  end

  # Used by GmailService to build Signet credentials
  def google_credentials
    {
      access_token: access_token,
      refresh_token: refresh_token,
      expires_at: expire_at.to_i,
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      token_credential_uri: 'https://oauth2.googleapis.com/token'
    }
  end

  # Refresh the access token if expired or about to expire
  def refresh_google_token!
    return unless refresh_token.present?

    client = Signet::OAuth2::Client.new(
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      token_credential_uri: 'https://oauth2.googleapis.com/token',
      refresh_token: refresh_token
    )

    client.fetch_access_token!

    update(
      access_token: client.access_token,
      expire_at: Time.now + client.expires_in
    )
  end
end
