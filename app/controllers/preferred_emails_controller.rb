class PreferredEmailsController < ApplicationController
  before_action :set_preferred_email, only: %i[ show edit update destroy ]
  before_action :authenticate_user!

  # GET /preferred_emails or /preferred_emails.json
  def index
    @preferred_emails = current_user.preferred_emails

  end

  # GET /preferred_emails/1 or /preferred_emails/1.json
  def show
  end

  # GET /preferred_emails/new
  def new
    @preferred_email = PreferredEmail.new
  end

  # GET /preferred_emails/1/edit
  def edit
  end

  # POST /preferred_emails or /preferred_emails.json
  def create
    @preferred_email = PreferredEmail.new(preferred_email_params)
     @preferred_email.user = current_user
    respond_to do |format|
      if @preferred_email.save
        format.html { redirect_to @preferred_email, notice: "Preferred email was successfully created." }
        format.json { render :show, status: :created, location: @preferred_email }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @preferred_email.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /preferred_emails/1 or /preferred_emails/1.json
  def update
    respond_to do |format|
      if @preferred_email.update(preferred_email_params)
        format.html { redirect_to @preferred_email, notice: "Preferred email was successfully updated." }
        format.json { render :show, status: :ok, location: @preferred_email }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @preferred_email.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /preferred_emails/1 or /preferred_emails/1.json
  def destroy
    @preferred_email.destroy!

    respond_to do |format|
      format.html { redirect_to preferred_emails_path, status: :see_other, notice: "Preferred email was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_preferred_email
      @preferred_email = PreferredEmail.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def preferred_email_params
      params.expect(preferred_email: [ :email, :subject, :user_id ])
    end
end
