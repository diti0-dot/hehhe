class Event < ApplicationRecord
   belongs_to :preferred_email, optional: true
  belongs_to :user, optional: true

  validates :preferred_email_id, presence: true, unless: :user_id?
  validates :user_id, presence: true, unless: :preferred_email_id?
  
   validate :end_time_cannot_be_in_the_past
  validate :end_time_after_start_time

  def end_time_cannot_be_in_the_past
    if end_time.present? && end_time < Time.current
      errors.add(:end_time, "can't be in the past")
    end
  end

  def end_time_after_start_time
    if end_time.present? && start_time.present? && end_time < start_time
      errors.add(:end_time, "must be after the start time")
    end
  end
  
  def owner_user
    preferred_email&.user || user
  end

end
