require 'test_helper'

class TicketsTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  include TestHelpers::AuthHelper
  include TestHelpers::JsonHelper

  def app
    Rails.application
  end

  # POST /helpdesk/ticket
  def test_post_helpdesk_ticket
    project_id = Project.first.id
    description = "jake renzella's comment :)"

    post with_auth_token "/api/helpdesk/ticket?project_id=#{project_id}&description=#{description}", Project.first.user

    actual_ticket = JSON.parse(last_response.body)[0]
  end

  # GET /helpdesk/ticket
  def test_get_unresolved_helpdesk_tickets
    get with_auth_token "/api/helpdesk/ticket"
    assert_json_equal HelpdeskTicket.all_unresolved, last_response_body
  end

  # GET /helpdesk/ticket?filter=resolved
  def test_get_resolved_helpdesk_tickets
    get with_auth_token "/api/helpdesk/ticket?filter=resolved"
    assert_json_equal HelpdeskTicket.all_resolved, last_response_body
  end

  # GET /helpdesk/ticket/:id
  # id = 1
  def test_get_helpdesk_ticket_with_id
    id = 1
    get with_auth_token "/api/helpdesk/ticket/#{id}"
    assert_json_equal HelpdeskTicket.find(id), last_response_body
  end
end
