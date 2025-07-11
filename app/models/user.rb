class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers:[:google_oauth2]
          has_many :preferred_emails
            has_many :professor_events, through: :preferred_emails, source: :events
            has_many :personal_events, -> { where(preferred_email: nil) }, class_name: 'Event'
  
  def all_events
    Event.where(
      "(preferred_email_id IN (?) OR user_id = ?)", 
      preferred_email_ids, 
      id
    )
  end

      def self.from_omniauth(auth)
  return nil if auth.credentials.refresh_token.nil?
  
  user = where(uid: auth.uid).first_or_initialize
  
  if user.persisted?
    # Update existing user
    user.access_token = auth.credentials.token
    user.refresh_token = auth.credentials.refresh_token
    user.expire_at = Time.at(auth.credentials.expires_at) if auth.credentials.expires_at
  else
    # Create new user
    user.uid = auth.uid
    user.email = auth.info.email
    user.password = Devise.friendly_token[0, 20]
    user.access_token = auth.credentials.token
    user.refresh_token = auth.credentials.refresh_token
    user.expire_at = Time.at(auth.credentials.expires_at) if auth.credentials.expires_at
  end
  
  user.save!
  user
end
end
