require "application_system_test_case"

class PreferredEmailsTest < ApplicationSystemTestCase
  setup do
    @preferred_email = preferred_emails(:one)
  end

  test "visiting the index" do
    visit preferred_emails_url
    assert_selector "h1", text: "Preferred emails"
  end

  test "should create preferred email" do
    visit preferred_emails_url
    click_on "New preferred email"

    fill_in "Email", with: @preferred_email.email
    fill_in "Subject", with: @preferred_email.subject
    fill_in "User", with: @preferred_email.user_id
    click_on "Create Preferred email"

    assert_text "Preferred email was successfully created"
    click_on "Back"
  end

  test "should update Preferred email" do
    visit preferred_email_url(@preferred_email)
    click_on "Edit this preferred email", match: :first

    fill_in "Email", with: @preferred_email.email
    fill_in "Subject", with: @preferred_email.subject
    fill_in "User", with: @preferred_email.user_id
    click_on "Update Preferred email"

    assert_text "Preferred email was successfully updated"
    click_on "Back"
  end

  test "should destroy Preferred email" do
    visit preferred_email_url(@preferred_email)
    click_on "Destroy this preferred email", match: :first

    assert_text "Preferred email was successfully destroyed"
  end
end
