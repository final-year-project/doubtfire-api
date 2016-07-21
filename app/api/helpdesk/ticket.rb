require 'grape'

module Api
  module Helpdesk
    #
    # Helpdesk ticketing system endpoints
    #
    class Ticket < Grape::API
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

        unless authorise? current_user, project, :create_ticket
          error!({"error" => "Not authorised to create a ticket for project #{project.id}"}, 403)
        end

        # Check that task matches the project id
        unless task.nil?
          if task.project.id != project.id then
            error!({"error" => "Task #{task.id} isn't a task under project #{project.id}"}, 403)
          end
        end

        ticket = HelpdeskTicket.new do | t |
          t.project = project
          t.task = task
          t.description = params[:description]
        end

        logger.info "Created new ticket for #{unit.name}"
      end

      # ------------------------------------------------------------------------
      # GET /helpdesk/ticket[?filter=all|resolved|unresolved]
      # By default all
      # ------------------------------------------------------------------------
      desc "Gets all helpdesk tickets"
      params do
        optional :filter, type: String, desc: "Filter by resolved, unresolved or all. Defaults to all.", default: 'all'
      end
      get '/helpdesk/ticket' do
        unless authorise? current_user, HelpdeskTicket, :get_tickets
          error!({"error" => "Not authorised to get tickets"}, 403)
        end

        filter = params[:filter]

        case filter
        when "all"
          HelpdeskTicket.all
        when "resolved"
          HelpdeskTicket.all_resolved
        when "unresolved"
          HelpdeskTicket.all_unresolved
        else
          error!({"error" => "Bad search query #{filter}"}, 404)
        end

      end
      # ------------------------------------------------------------------------
      # GET /helpdesk/ticket/:id
      # ------------------------------------------------------------------------

      # ------------------------------------------------------------------------
      # GET /helpdesk/stats
      # ------------------------------------------------------------------------

    end
  end
end
