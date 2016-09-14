require 'grape'

module Api
  module Helpdesk
    #
    # Helpdesk ticket stats endpoints
    #
    class Stats < Grape::API
      helpers AuthHelpers
      helpers AuthorisationHelpers
      helpers LogHelper

      before do
        authenticated?
      end

      # ------------------------------------------------------------------------
      # GET /helpdesk/stats/tickets
      # ------------------------------------------------------------------------
      desc 'Gets tickets stats for helpdesk within the duration specified'
      params do
        optional :from, type: DateTime, desc: 'The time to start getting statistics (do not provide for all stats)'
        optional :to,   type: DateTime, desc: 'The time to stop getting statistics (defaults to current time)', default: DateTime.now
      end
      get '/helpdesk/stats/tickets' do
        unless authorise? current_user, HelpdeskTicket, :get_ticket_stats
          error!({error: 'Not authorised to get helpdesk ticket stats'}, 403)
        end

        logger.info "#{current_user.username} got ticket helpdesk statistics"

        from     = params[:from]
        to       = params[:to] || DateTime.now

        {
          resolved_count:             HelpdeskTicket.resolved_between(from, to).length,
          number_unresolved:          HelpdeskTicket.all_unresolved.length,
          average_wait_time_in_mins:  HelpdeskTicket.average_wait_time(from, to)
        }
      end

      # ------------------------------------------------------------------------
      # GET /helpdesk/stats/dashgraph
      # ------------------------------------------------------------------------
      desc 'Gets dashboard graph data for the helpdesk (last 3 hours)'
      get '/helpdesk/stats/dashgraph' do
        unless authorise? current_user, HelpdeskTicket, :get_ticket_stats
          error!({error: 'Not authorised to get helpdesk ticket stats'}, 403)
        end

        logger.info "#{current_user.username} got ticket helpdesk dash graph data"

        # Work from now downto 3 hours ago
        graph_range = 3.hours.ago.to_i..DateTime.now.to_i
        graph_data = {}
        # Collect data every minute going backwards -- stats for every min in
        # last 180 mins
        interval = 1.minute.to_i
        graph_range.first.step(graph_range.last, interval) do |unix_t|
          # Range is the time between graph_time less time mins ago
          # to graph_time
          range = Time.at(unix_t + interval).utc..Time.at(unix_t).utc
          # Stats to include
          avg_wait   = HelpdeskTicket.average_wait_time(range.first, range.last)
          unresolved = HelpdeskTicket.unresolved_between(range.first, range.last)
          # Insert at this time the stats there were
          graph_data[unix_t] = {
            average_wait_time_in_mins:    avg_wait,
            number_of_unresolved_tickets: unresolved.length # count only
          }
        end
        graph_data
      end
    end
  end
end
