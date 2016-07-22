require 'grape'

module Api
  module Helpdesk
    #
    # Helpdesk session system endpoints
    #
    class Session < Grape::API
      helpers AuthHelpers
      helpers AuthorisationHelpers
      helpers LogHelper

      before do
        authenticated?
      end

      # ------------------------------------------------------------------------
      # POST /helpdesk/session
      # ------------------------------------------------------------------------
      desc "Begin a new session at the helpdesk as current user"
      params do
        requires :clock_off_time, type: DateTime, :desc => "The estimated clock off time when the user ends working"
        optional :user_id, type: Integer, :desc => "The user who is about to begin working (if blank, posting user is used)"
      end
      post '/helpdesk/session' do
        unless authorise? current_user, HelpdeskSession, :create_session
          error!({"error" => "Not authorised to create a helpdesk session"}, 403)
        end
        user = params[:user_id] ? User.find(params[:user_id]) : current_user
        # TODO: Doesn't this mean I can create a session on another person's behalf?
        #       Is this what we want?
        if HelpdeskSession.user_clocked_off?(user)
          session = HelpdeskSession.create(
            user: user,
            clock_on_time: DateTime.now, # Clock on immediately when ticket is created
            clock_off_time: params[:clock_off_time]
          )
          logger.info "#{current_user.username} created new helpdesk session (id=#{session.id})"
        else
          error!({"error" => "#{user.username} is already clocked on at the helpdesk"}, 403)
        end
        session
      end

      # ------------------------------------------------------------------------
      # DELETE /helpdesk/session/:id
      # ------------------------------------------------------------------------
      desc "Prematurely clock off an existing helpdesk session"
      params do
        requires :id, type: Integer, :desc => "The session to clock off"
      end
      delete '/helpdesk/session/:id' do
        session = HelpdeskSession.find(params[:id])
        unless authorise? current_user, session, :clock_off_session
          error!({"error" => "Not authorised to clock off a helpdesk session"}, 403)
        end
        # TODO: Does this mean I can clock off other users? Is that what we want?
        #       Or do we validate that current_user is the session user?
        unless session.clocked_off?
          session.clock_off
          logger.info "#{current_user.username} prematurely clocked off helpdesk session (id=#{session.id})"
        else
          logger.info "#{current_user.username} attempted to clock off already clocked off helpdesk session (id=#{session.id})"
        end
        session
      end

      # ------------------------------------------------------------------------
      # GET /helpdesk/session/tutors
      # ------------------------------------------------------------------------
      desc "Get a list of all currently tutors working at the helpdesk"
      get '/helpdesk/session/tutors' do
        unless authorise? current_user, HelpdeskSession, :get_all_current_session_users
          error!({"error" => "Not authorised view current helpdesk staff"}, 403)
        end
        logger.info "#{current_user.username} requested all currently working helpdesk staff"
        HelpdeskSession.users_working_now
      end
    end
  end
end
