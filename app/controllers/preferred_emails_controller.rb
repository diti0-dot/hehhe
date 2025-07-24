class PreferredEmailsController < ApplicationController
   include ActionView::RecordIdentifier
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

 def create
  @preferred_email = current_user.preferred_emails.new(preferred_email_params)

  respond_to do |format|
    if @preferred_email.save
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.prepend('preferred_emails_list', partial: 'preferred_emails/preferred_email', locals: { preferred_email: @preferred_email }),
          turbo_stream.replace('preferred_email_form', partial: 'preferred_emails/form', locals: { preferred_email: PreferredEmail.new }),
          turbo_stream.append('flash', partial: 'shared/flash', locals: { notice: 'Preferred email created!' }) # optional flash
        ]
      end
      format.html { redirect_to @preferred_email, notice: "Preferred email was successfully created." }
      format.json { render :show, status: :created, location: @preferred_email }
    else
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace('preferred_email_form', partial: 'preferred_emails/form', locals: { preferred_email: @preferred_email })
      end
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @preferred_email.errors, status: :unprocessable_entity }
    end
  end
end


def update
  @preferred_email = PreferredEmail.find(params[:id])
  if @preferred_email.update(preferred_email_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to preferred_emails_path, notice: "Updated!" }
    end
  else
    render partial: "preferred_emails/form", status: :unprocessable_entity
  end
end


 def destroy
  @preferred_email = PreferredEmail.find(params[:id])
  @preferred_email.destroy

  respond_to do |format|
    format.turbo_stream do 
      render turbo_stream: [
        turbo_stream.remove(dom_id(@preferred_email)),
      ]
    end
    format.html { redirect_to preferred_emails_path, notice: "Deleted!" }
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
