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
      # GET /helpdesk/tickets?filter={resolved,unresolved,closed,all}&user_id={id}
      # Optional User Id and Filter. Filter default to all.
      # ------------------------------------------------------------------------
      desc "Gets all helpdesk tickets. Optional User Id and Resolved filter."
      params do
        optional :user_id, type: String, desc: "The id of the user to get tickets for."
        optional :filter, type: String, desc: "Filter by resolved, unresolved, closed or all. Defaults to all.", default: 'all'
        optional :shallow, type: Boolean, desc: "Use shallow serializer vs detailed serializer", default: true
      end
      get '/helpdesk/tickets' do
        unless authorise? current_user, HelpdeskTicket, :get_tickets
          error!({error: 'Not authorised to get tickets'}, 403)
        end

        user_id = params[:user_id]
        filter = params[:filter] || 'all'
        tickets = HelpdeskTicket.all_by_state(filter.to_sym, user_id)

        serializer = params[:shallow] ? ShallowHelpdeskTicketSerializer : HelpdeskTicketSerializer
        ActiveModel::ArraySerializer.new(tickets, each_serializer: serializer)
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
      # DELETE /helpdesk/tickets/:id?[resolve=true|false]
      # ------------------------------------------------------------------------
      desc "Updates helpdesk ticket with an id"
      params do
        requires :id, type: Integer, desc: "The id to of the ticket to delete"
        optional :resolve, type: Boolean, desc: "Mark the ticket as resolved"
      end
      delete '/helpdesk/tickets/:id' do
        ticket = HelpdeskTicket.find(params[:id])

        if params[:resolve] == true
          unless authorise? current_user, ticket, :resolve_ticket
            error!({error: "Not authorised to resolve ticket #{params[:id]}"}, 403)
          end
          ticket.resolve
          logger.info "#{current_user.username} resolved ticket #{ticket.id}"
        else
          unless authorise? current_user, ticket, :close_ticket
            error!({error: "Not authorised to close ticket #{params[:id]}"}, 403)
          end
          ticket.close
          logger.info "#{current_user.username} closed ticket #{ticket.id}"
        end

        ticket
      end
    end
  end
end
