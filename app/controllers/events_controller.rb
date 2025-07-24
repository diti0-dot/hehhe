class EventsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!
  before_action :set_event, only: [:show, :edit, :update, :destroy]

  def index
    @events = current_user.all_events
    @event = Event.new
  end

  def show
  end

  def new
    @event = Event.new
  end

  def edit
  end

  def create
    @event = current_user.events.new(event_params)

    respond_to do |format|
      if @event.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend('events_list', partial: 'events/event', locals: { event: @event }),
            turbo_stream.replace('event_form', partial: 'events/form', locals: { event: Event.new }),
            turbo_stream.replace('calendar', partial: 'events/calendar', locals: { events: current_user.all_events })
          ]
        end
        format.html { redirect_to events_path, notice: "Event was successfully created." }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('event_form', partial: 'events/form', locals: { event: @event })
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @event.update(event_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("event_#{@event.id}", partial: 'events/event', locals: { event: @event }),
            turbo_stream.replace('calendar', partial: 'events/calendar', locals: { events: current_user.all_events }),
             turbo_stream.replace('event_form', partial: 'events/form', locals: { event: Event.new })
          ]
        end
        format.html { redirect_to @event, notice: "Event was successfully updated." }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(dom_id(@event), partial: 'events/form', locals: { event: @event })
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @event.destroy
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(dom_id(@event)),
          turbo_stream.replace('calendar', partial: 'events/calendar', locals: { events: current_user.all_events })
        ]
      end
      format.html { redirect_to events_url, notice: "Event was successfully destroyed." }
    end
  end

  private

  def set_event
    @event = current_user.events.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :description, :start_time, :end_time, :preferred_email_id)
  end
end
