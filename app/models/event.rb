class Event < ApplicationRecord
   belongs_to :preferred_email, optional: true
  belongs_to :user, optional: true

  validates :preferred_email_id, presence: true, unless: :user_id?
  validates :user_id, presence: true, unless: :preferred_email_id?

  def owner_user
    preferred_email&.user || user
  end

end
