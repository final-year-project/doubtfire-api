require 'grape'
require 'helpdesk_ticket_serializer'

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
      # POST /helpdesk/tickets
      # ------------------------------------------------------------------------
      desc "Add a new helpdesk ticket"
      params do
        requires :project_id, type: Integer, desc: "The project to assign the ticket to"
        optional :task_definition_id, type: Integer, desc: "Task which the student needs help with"
        optional :description, type: String, desc: "Description associated to the ticket"
      end
      post '/helpdesk/tickets' do
        project = Project.find(params[:project_id])
        task = params[:task_definition_id].nil? ? nil : task = project.task_for_task_definition(params[:task_definition_id])

        unless authorise? current_user, project, :create_ticket
          error!({error: "Not authorised to create a ticket for project #{project.id}"}, 403)
        end

        # Only allow them to create a new ticket if they haven't done so already
        if HelpdeskTicket.user_has_ticket_open? project.user.id
          logger.info "#{current_user.username} tried to create new ticket but already has one open"
          error!({error: "User already has a ticket open"}, 403)
        end

        ticket = HelpdeskTicket.create!({
          project: project,
          task: task,
          description: params[:description]
        })

        logger.info "#{current_user.username} created new ticket #{ticket.id} for #{ticket.unit.name}"
        ticket
      end

      # ------------------------------------------------------------------------
      # GET /helpdesk/tickets/:filter
      # Optional User Id and Filter. Filter default to all.
      # ------------------------------------------------------------------------
      desc "Gets all helpdesk tickets. Optional User Id and Resolved filter."
      params do
        optional :user_id, type: String, desc: "The id of the user to get tickets for."
        optional :filter, type: String, desc: "Filter by resolved, unresolved or all. Defaults to all (unresolved).", default: 'all'
      end
      get '/helpdesk/tickets' do
        unless authorise? current_user, HelpdeskTicket, :get_tickets
          error!({error: 'Not authorised to get tickets'}, 403)
        end

        user_id = params[:user_id]
        filter = params[:filter] || 'all'
        tickets = HelpdeskTicket.all_by_resolved_and_user(filter, user_id)
        ActiveModel::ArraySerializer.new(tickets, each_serializer: ShallowHelpdeskTicketSerializer)
      end

      # ------------------------------------------------------------------------
      # GET /helpdesk/tickets/:id
      # ------------------------------------------------------------------------
      desc "Gets helpdesk ticket with an id"
      params do
        requires :id, type: Integer, desc: "The id of the ticket to get"
      end
      get '/helpdesk/tickets/:id' do
        ticket = HelpdeskTicket.find(params[:id])

        if not authorise? current_user, ticket, :get_details
          error!({error: 'Not authorised to get ticket details'}, 403)
        end

        ticket
      end

      # ------------------------------------------------------------------------
      # PUT /helpdesk/tickets/:id
      # ------------------------------------------------------------------------
      desc "Updates helpdesk ticket with an id"
      params do
        requires :id, type: Integer, desc: "The id to of the ticket to update"
        requires :description, type: String, desc: "The new description of this ticket"
      end
      put '/helpdesk/tickets/:id' do
        unless authorise? current_user, HelpdeskTicket, :get_tickets
          error!({error: "Not authorised to get tickets"}, 403)
        end

        ticket_to_update = HelpdeskTicket.find(params[:id])
        ticket_to_update.description = params[:description]
        ticket_to_update.save!

        logger.info "#{current_user.username} updated ticket #{ticket_to_update.id}"
        ticket_to_update
      end
    end
  end
end
