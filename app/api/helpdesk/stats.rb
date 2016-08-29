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
        optional :from, type: DateTime, desc: "The time to start getting statistics (do not provide for all stats)"
        optional :to,   type: DateTime, desc: "The time to stop getting statistics (defaults to current time)", default: DateTime.now
      end
      get '/helpdesk/stats' do
        unless authorise? current_user, HelpdeskTicket, :get_stats
          error!({error: "Not authorised to get helpdesk stats"}, 403)
        end

        logger.info "#{current_user.username} got helpdesk statistics"

        from = params[:from]
        to   = params[:to] || DateTime.now

        avg_resolve = HelpdeskTicket.average_resolve_time_between(from, to) || 0
        avg_wait = avg_resolve * HelpdeskTicket.all_unresolved.length

        response = {
          tickets: {
            resolved_count:     HelpdeskTicket.resolved_betweeen(from, to).length,
            number_unresolved:  HelpdeskTicket.all_unresolved.length,
            average_wait_time:  avg_wait
          }
        }

        if authorise? current_user, HelpdeskSession, :get_stats
          response[:sessions] = {
            all_session_count:            HelpdeskSession.sessions_between(from, to).length,
            session_count_by_staff_id:    HelpdeskSession.session_count_by_staff_between(from, to),
            avg_session_time_by_staff_id: HelpdeskSession.average_session_time_by_staff_between(from, to)
          }
        end

        response
      end
    end
  end
end
