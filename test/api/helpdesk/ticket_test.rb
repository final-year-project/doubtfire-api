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

    ticket = {
      project_id: project.id,
      description: Populator.words(5..10),
      task_definition_id: rand > 0.33 ? Randomizer.random_task_def_for_project(project).id : nil
    }

    data_to_post = add_auth_token ticket, project.user

    post_json "/api/helpdesk/tickets", data_to_post

    expected_ticket = HelpdeskTicket.last
    assert_json_equal expected_ticket, last_response_body
  end

  # GET /helpdesk/tickets
  def test_get_unresolved_helpdesk_tickets
    get with_auth_token "/api/helpdesk/tickets"
    assert_json_equal HelpdeskTicket.all_unresolved, last_response_body
  end

  # GET /helpdesk/tickets?filter=resolved
  def test_get_resolved_helpdesk_tickets
    get with_auth_token "/api/helpdesk/tickets?filter=resolved"
    assert_json_equal HelpdeskTicket.all_resolved, last_response_body
  end

  # GET /helpdesk/user/tickets?
  def test_get_resolved_helpdesk_tickets
    id = 1
    get with_auth_token "/api/helpdesk/user/#{id}/tickets"
    puts "HERE:::"
    puts last_response_body
  end

  # GET /helpdesk/tickets/:id
  # id = 1
  def test_get_helpdesk_ticket_with_id
    id = 1
    get with_auth_token "/api/helpdesk/tickets/#{id}"
    assert_json_equal HelpdeskTicket.find(id), last_response_body
  end
end
