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
        optional :task_definition_id, type: Integer, :desc => "Task which the student needs help with"
        optional :description, type: String, :desc => "Description associated to the ticket"
      end
      post '/helpdesk/ticket' do
        project = Project.find(params[:project_id])
        task = params[:task_definition_id].nil? ? nil : task = project.task_for_task_definition(find(params[:task_definition_id]))

        unless authorise? current_user, project, :create_ticket
          error!({"error" => "Not authorised to create a ticket for project #{project.id}"}, 403)
        end

        ticket = HelpdeskTicket.new do | t |
          t.project = project
          t.task = task
          t.description = params[:description]
        end

        logger.info "#{current_user.username} created new ticket #{t.id} for #{ticket.unit.name}"
        ticket
      end

      # ------------------------------------------------------------------------
      # GET /helpdesk/ticket[?filter=all|resolved|unresolved]
      # By default all
      # ------------------------------------------------------------------------
      desc "Gets all helpdesk tickets"
      params do
        optional :filter, type: String, desc: "Filter by resolved, unresolved or all. Defaults to all (unresolved).", default: 'all'
      end
      get '/helpdesk/ticket/:filter' do
        unless authorise? current_user, HelpdeskTicket, :get_tickets
          error!({"error" => "Not authorised to get tickets"}, 403)
        end

        filter = params[:filter] || "all"

        if filter == "resolved"
          HelpdeskTicket.all_resolved
        else
          HelpdeskTicket.all_unresolved
        end
      end

      # ------------------------------------------------------------------------
      # GET /helpdesk/ticket/:id
      # ------------------------------------------------------------------------
      desc "Gets helpdesk ticket with an id"
      params do
        requires :id, type: Integer, :desc => "The id to of the ticket to get"
      end
      get '/helpdesk/ticket/:id' do
        ticket = HelpdeskTicket.find(params[:id])

        if not authorise? current_user, ticket, :get_details
          error!({"error" => "Not authorised to get ticket details"}, 403)
        end

        ticket
      end

      # ------------------------------------------------------------------------
      # PUT /helpdesk/ticket/:id
      # ------------------------------------------------------------------------
      desc "PUTS helpdesk ticket with an id"
      params do
        requires :id, type: Integer, :desc => "The id to of the ticket to get"
        requires :description, type: String, :desc => "The new description of this ticket"
      end
      put '/helpdesk/ticket/:id' do
        unless authorise? current_user, HelpdeskTicket, :get_tickets
          error!({"error" => "Not authorised to get tickets"}, 403)
        end

        ticket_to_update = HelpdeskTicket.find(params[:id])
        ticket_to_update.description = params[:description]
        ticket_to_update.save!

        logger.info "#{current_user.username} updated ticket #{ticket_to_update.id}"
        ticket_to_update
      end

      # ------------------------------------------------------------------------
      # GET /helpdesk/stats
      # ------------------------------------------------------------------------

    end
  end
end
