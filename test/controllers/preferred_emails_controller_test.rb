require "test_helper"

class PreferredEmailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @preferred_email = preferred_emails(:one)
  end

  test "should get index" do
    get preferred_emails_url
    assert_response :success
  end

  test "should get new" do
    get new_preferred_email_url
    assert_response :success
  end

  test "should create preferred_email" do
    assert_difference("PreferredEmail.count") do
      post preferred_emails_url, params: { preferred_email: { email: @preferred_email.email, subject: @preferred_email.subject, user_id: @preferred_email.user_id } }
    end

    assert_redirected_to preferred_email_url(PreferredEmail.last)
  end

  test "should show preferred_email" do
    get preferred_email_url(@preferred_email)
    assert_response :success
  end

  test "should get edit" do
    get edit_preferred_email_url(@preferred_email)
    assert_response :success
  end

  test "should update preferred_email" do
    patch preferred_email_url(@preferred_email), params: { preferred_email: { email: @preferred_email.email, subject: @preferred_email.subject, user_id: @preferred_email.user_id } }
    assert_redirected_to preferred_email_url(@preferred_email)
  end

  test "should destroy preferred_email" do
    assert_difference("PreferredEmail.count", -1) do
      delete preferred_email_url(@preferred_email)
    end

    assert_redirected_to preferred_emails_url
  end
end
