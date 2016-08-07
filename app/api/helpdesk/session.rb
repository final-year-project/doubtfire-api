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
      # GET /helpdesk/sessions?user_id=[id]&is_active=[true|false]
      # ------------------------------------------------------------------------
      desc "Get helpdesk sessions"
      params do
        optional :user_id,   type: Integer, :desc => "Filter by specific user id"
        optional :is_active, type: Boolean, :desc => "Filter to only active sessions"
      end
      get '/helpdesk/sessions' do
        unless authorise? current_user, HelpdeskSession, :get_sessions
          error!({"error" => "Not authorised get helpdesk sessions"}, 403)
        end
        if params.empty?
          logger.info "#{current_user.username} requested all helpdesk sessions"
          HelpdeskSession.all
        else
          user_id = params[:user_id]
          is_active = params[:is_active]
          logger.info "#{current_user.username} requested all #{is_active ? 'active' : ''} helpdesk sessions" << (!user_id.nil? ? " for user_id #{user_id}" : '')
          sessions = is_active ? HelpdeskSession.active_sessions : HelpdeskSession.all
          sessions = user_id.nil? ? sessions : sessions.where(user_id: user_id)
          sessions
        end
      end

      # ------------------------------------------------------------------------
      # POST /helpdesk/sessions
      # ------------------------------------------------------------------------
      desc "Begin a new session at the helpdesk as current user"
      params do
        requires :clock_off_time, type: DateTime, :desc => "The estimated clock off time when the user ends working"
        optional :user_id, type: Integer, :desc => "The user who is about to begin working (if blank, posting user is used)"
      end
      post '/helpdesk/sessions' do
        unless authorise? current_user, HelpdeskSession, :create_session
          error!({"error" => "Not authorised to create a helpdesk session"}, 403)
        end
        user = params[:user_id] ? User.find(params[:user_id]) : current_user
        # TODO: if current_user != user_id passed in then require PIN
        if HelpdeskSession.user_clocked_off?(user)
          session = HelpdeskSession.create!(
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
      # DELETE /helpdesk/sessions/:id
      # ------------------------------------------------------------------------
      desc "Prematurely clock off an existing helpdesk session"
      params do
        requires :id, type: Integer, :desc => "The session to clock off"
      end
      delete '/helpdesk/sessions/:id' do
        session = HelpdeskSession.find(params[:id])
        unless authorise? current_user, session, :clock_off_session
          error!({"error" => "Not authorised to clock off helpdesk session (id=#{session.id})"}, 403)
        end
        # TODO: if current_user != session.user then require PIN
        if session.clocked_off?
          logger.info "#{current_user.username} attempted to clock off already clocked off helpdesk session (id=#{session.id})"
        else
          session.clock_off
          logger.info "#{current_user.username} prematurely clocked off helpdesk session (id=#{session.id})"
        end
        session
      end

      # ------------------------------------------------------------------------
      # GET /helpdesk/sessions/tutors
      # ------------------------------------------------------------------------
      desc "Get a list of all currently tutors working at the helpdesk"
      get '/helpdesk/sessions/tutors' do
        unless authorise? current_user, HelpdeskSession, :get_all_current_session_users
          error!({"error" => "Not authorised view current helpdesk staff"}, 403)
        end
        logger.info "#{current_user.username} requested all currently working helpdesk staff"
        HelpdeskSession.users_working_now
      end
    end
  end
end
