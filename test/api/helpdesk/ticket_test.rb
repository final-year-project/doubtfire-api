require 'test_helper'

class TicketsTest < ActiveSupport::TestCase
  include Rack::Test::Methods
  include TestHelpers::AuthHelper
  include TestHelpers::JsonHelper

  def app
    Rails.application
  end

  def setup
    @auth_token = get_auth_token()
  end

  # --------------------------------------------------------------------------- #
  # --- Endpoint testing for:
  # ------- /helpdesk/tickets.json
  # ------- GET

  # --------------------------------------------------------------------------- #
  # POST tests

  # GET tests
  # Test GET for all tickets
  def test_get_helpdesk_tickets
    get with_auth_token "/api/helpdesk/ticket.json"
    actual_ticket = JSON.parse(last_response.body)[0]
  end

  # Test GET for a ticket with and id
  def test_get_helpdesk_ticket_with_id
    id = 0;
    get "/api/helpdesk/ticket/#{id}.json?auth_token=#{@auth_token}"
    actual_ticket = JSON.parse(last_response.body)[0]
  end

  # Test POST for a ticket with and id
  def test_post_helpdesk_ticket
    @auth_token = auth_token_for(Project.first.user)
    project_id = Project.first.id
    description = "jake renzella's comment :)"

    post "/api/helpdesk/ticket.json?project_id=#{project_id}?description=#{description}?auth_token=#{@auth_token}"

    actual_ticket = JSON.parse(last_response.body)[0]
  end
end
