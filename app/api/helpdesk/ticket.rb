require 'grape'

module Api

  #
  # Helpdesk ticketing system endpoints
  #
  class HelpdeskTicketing < Grape::API
    helpers AuthHelpers
    helpers AuthorisationHelpers
    helpers LogHelper

    before do
      authenticated?
    end

    # ------------------------------------------------------------------------
    # POST /helpdesk/ticket
    # ------------------------------------------------------------------------
    desc "Add a new helpdesk ticket"
    params do
      requires :project_id, type: Integer, :desc => "The project to assign the ticket to"
      optional :task_id, type: Integer, :desc => "Task which the student needs help with"
      optional :description, type: String, :desc => "Description associated to the ticket"
    end
    post '/project/:project_id/helpdesk/ticket' do
      project = Project.find(params[:project_id])
      task = params[:task_id].nil? ? nil : task = Task.find(params[:task_id])

      if not authorise? current_user, project, :create_ticket
        error!({"error" => "Not authorised to create a ticket for project #{project.id}"}, 403)
      end

      ticket = HelpdeskTicket.new do | t |
        t.project = project
        t.task = task
        t.description = params[:description]
      end

      logger.info "Created new ticket for #{unit.name}"
    end

  end
end
