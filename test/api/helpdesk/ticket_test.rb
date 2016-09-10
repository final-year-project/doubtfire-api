require 'test_helper'

class TicketsTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  include TestHelpers::AuthHelper
  include TestHelpers::JsonHelper

  def app
    Rails.application
  end

  # POST /helpdesk/tickets
  def test_post_helpdesk_ticket
    project = Randomizer.random_record_for_model(Project)

    # Can't create ticket if this user already has a ticket
    while HelpdeskTicket.user_has_ticket_open? project.user_id
      project = Randomizer.random_record_for_model(Project)
    end

    ticket = {
      project_id: project.id,
      description: Populator.words(5..10),
      task_definition_id: rand > 0.33 ? Randomizer.random_task_def_for_project(project).id : nil
    }

    data_to_post = add_auth_token ticket, project.user

    post_json '/api/helpdesk/tickets', data_to_post

    # Last ticket ids should match
    expected_ticket = HelpdeskTicket.last
    assert_json_matches_model last_response_body, expected_ticket, :id
  end

  # GET /helpdesk/tickets
  def test_get_all_helpdesk_tickets
    get with_auth_token '/api/helpdesk/tickets'
    expect = ActiveModel::ArraySerializer.new(HelpdeskTicket.all, each_serializer: ShallowHelpdeskTicketSerializer)
    assert_json_equal expect, last_response_body
  end

  # GET /helpdesk/tickets
  def test_get_all_unresolved_helpdesk_tickets
    get with_auth_token '/api/helpdesk/tickets?filter=unresolved'
    expect = ActiveModel::ArraySerializer.new(HelpdeskTicket.all_unresolved, each_serializer: ShallowHelpdeskTicketSerializer)
    assert_json_equal expect, last_response_body
  end

  # GET /helpdesk/tickets?filter=resolved
  def test_get_resolved_helpdesk_tickets
    get with_auth_token '/api/helpdesk/tickets?filter=resolved'
    expect = ActiveModel::ArraySerializer.new(HelpdeskTicket.all_resolved, each_serializer: ShallowHelpdeskTicketSerializer)
    assert_json_equal expect, last_response_body
  end

  # GET /helpdesk/tickets?user_id=1&filter=resolved
  def test_get_resolved_helpdesk_tickets_for_user
    id = 1
    get with_auth_token "/api/helpdesk/tickets?user_id=#{id}&filter=resolved"
    expect = ActiveModel::ArraySerializer.new(HelpdeskTicket.all_resolved(id), each_serializer: ShallowHelpdeskTicketSerializer)
    assert_json_equal expect, last_response_body
  end

  # GET /helpdesk/tickets/:id
  # id = 1
  def test_get_helpdesk_ticket_with_id
    id = 1
    get with_auth_token "/api/helpdesk/tickets/#{id}"
    expect = HelpdeskTicketSerializer.new HelpdeskTicket.find(id)
    assert_json_equal expect, last_response_body
  end

  # DELETE /helpdesk/tickets/:id?resolve=false
  def test_delete_a_ticket_by_closing
    ticket = HelpdeskTicket.all_unresolved.first
    delete with_auth_token "/api/helpdesk/tickets/#{ticket.id}"
    # Reload the ticket from DB with updated info
    ticket = HelpdeskTicket.find(ticket.id)
    assert ticket.is_closed
    refute ticket.is_resolved
  end

  # DELETE /helpdesk/tickets/:id?resolve=true
  def test_delete_a_ticket_by_resolving
    ticket = HelpdeskTicket.all_unresolved.first
    delete with_auth_token "/api/helpdesk/tickets/#{ticket.id}?resolve=true"
    # Reload the ticket from DB with updated info
    ticket = HelpdeskTicket.find(ticket.id)
    assert ticket.is_resolved
    assert ticket.is_closed
    dt = DateTime.parse(last_response_body['closed_at']).inspect
    assert dt, ticket.closed_at
  end
end
