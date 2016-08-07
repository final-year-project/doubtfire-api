require 'grape'

module Api
  module Helpdesk
    #
    # Helpdesk session system endpoints
    #
    class Stats < Grape::API
      helpers AuthHelpers
      helpers AuthorisationHelpers
      helpers LogHelper

      before do
        authenticated?
      end
      # ------------------------------------------------------------------------
      # GET /helpdesk/stats
      # ------------------------------------------------------------------------
      desc "Gets statistics about the helpdesk for the duration specified"
      params do
        requires :from, type: DateTime, desc: "The time to start getting statistics"
        optional :to,   type: DateTime, desc: "The time to stop getting statistics (defaults to current time)", default: DateTime.now
      end
      get '/helpdesk/stats' do
        unless authorise? current_user, HelpdeskTicket, :get_stats
          error!({error: "Not authorised to get helpdesk stats"}, 403)
        end

        logger.info "#{current_user.username} got helpdesk statistics"

        from = params[:from]
        to   = params[:to] || DateTime.now

        {
          tickets_resolved:     HelpdeskTicket.resolved_betweeen(from, to).length,
          average_wait_time:    HelpdeskTicket.average_resolve_time(from, to)
        }
      end
    end
  end
end