class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
  user = User.from_omniauth(request.env["omniauth.auth"])
  
  if user.nil?
    redirect_to new_user_registration_path, alert: "Error: Please try connecting your Gmail again"
  else
    sign_in(user)
    redirect_to root_path, notice: "Successfully signed in!"
  end
end
end
