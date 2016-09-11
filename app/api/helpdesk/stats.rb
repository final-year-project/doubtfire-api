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
      # GET /helpdesk/stats/tickets
      # ------------------------------------------------------------------------
      desc "Gets tickets statistics about the helpdesk for the duration specified"
      params do
        optional :from,     type: DateTime, desc: "The time to start getting statistics (do not provide for all stats)"
        optional :to,       type: DateTime, desc: "The time to stop getting statistics (defaults to current time)", default: DateTime.now
        optional :interval, type: Integer,  desc: "Interval of graph data (in seconds)", default: 30
      end
      get '/helpdesk/stats' do
        unless authorise? current_user, HelpdeskTicket, :get_stats
          error!({error: "Not authorised to get helpdesk stats"}, 403)
        end
        logger.info "#{current_user.username} got ticket helpdesk statistics"

        from = params[:from]
        to   = params[:to] || DateTime.now
        interval = params[:interval] || 30

        # Calculate an acceptable interval for the range given that won't
        # hurt the server. Subtract the from and to dates and work out the
        # number of seconds between them divide by the data limit --
        # that is the minimum interval accepted
        DATA_LIMIT = 30
        min_interval = (((to - from) * 60 * 60 * 24) / DATA_LIMIT).to_f
        if interval < min_interval
          error!({error: "Bad interval - must be greater than #{min_interval} "\
                         "seconds = #{(min_interval / 60).to_i} minutes = "\
                         "#{(min_interval / 60 / 60).to_i} = hours = " \
                         "#{(min_interval / 60 / 60 / 24).to_i} days"}, 403)
        end

        graph_data = { unresolved: [], average_wait_time_in_mins: [] }
        graph_time = from
        graph_interval = interval.seconds

        while graph_time < to
          unix_time = graph_time.to_i
          range_from = graph_time
          range_to   = graph_time + graph_interval
          graph_data[:average_wait_time_in_mins] <<
            [unix_time, HelpdeskTicket.average_wait_time(range_from, range_to)]
          graph_data[:unresolved] <<
            [unix_time, HelpdeskTicket.unresolved_between(range_from, range_to).length]
          graph_time = range_to
        end

        response = {
          graph_data: graph_data
        }

        response[:tickets] = {
          resolved_count:     HelpdeskTicket.resolved_between(from, to).length,
          number_unresolved:  HelpdeskTicket.all_unresolved.length,
          average_wait_time_in_mins:  HelpdeskTicket.average_wait_time(from, to)
        }

        if authorise? current_user, HelpdeskSession, :get_stats
          response[:sessions] = HelpdeskSession.stats_by_staff_id(from, to)
        end

        response
      end
    end
  end
end
