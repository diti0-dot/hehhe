json.extract! preferred_email, :id, :email, :subject, :user_id, :created_at, :updated_at
json.url preferred_email_url(preferred_email, format: :json)
