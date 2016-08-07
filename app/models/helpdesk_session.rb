#
# Tracking for sessions of staff working at the helpdesk.
#
class HelpdeskSession < ActiveRecord::Base
  # Model associations
  belongs_to :user

  # Model constratins/validation
  validates :user, presence: true
  validates :clock_on_time, presence: true
  validates :clock_off_time, presence: true

  # Validates that a clock off time is always after the clock on time
  validates_presence_of :clock_on_time, if: :clock_off_must_be_after_clock_on
  def clock_off_must_be_after_clock_on
    if clock_off_time && clock_off_time < clock_on_time
      errors.add(:clock_off_time, "can't be before :clock_on_time")
    end
  end

  # Validates that the user for a session is not a student
  validates_presence_of :user, if: :user_is_not_student
  def user_is_not_student
    if user && user.role == Role.student
      errors.add(:user, 'must not be a student')
    end
  end

  #
  # Permissions around helpdesk sessions
  #
  def self.permissions
    # What can students do with sessions?
    student_role_permissions = [
      :get_all_current_session_users
    ]
    # What can tutors do with sessions?
    tutor_role_permissions = [
      :create_session,
      :clock_off_session,
      :get_all_current_session_users
    ]
    # What can convenors do with sessions?
    convenor_role_permissions = [
      :create_session,
      :clock_off_session,
      :get_all_current_session_users
    ]
    # What can admins do with sessions?
    admin_role_permissions = [
      :create_session,
      :clock_off_session,
      :get_all_current_session_users
    ]
    # What can nil users do with sessions?
    nil_role_permissions = [
    ]

    # Return permissions hash
    {
      :admin    => admin_role_permissions,
      :convenor => convenor_role_permissions,
      :tutor    => tutor_role_permissions,
      :student  => student_role_permissions,
      :nil      => nil_role_permissions
    }
  end

  def self.role_for(user)
    user.role
  end

  def role_for(user)
    # If the user provided is the user registered to the session, then
    # they can do whatever they want with it. Convenors and admins can
    # override this
    if user == self.user || [Role.convenor, Role.admin].include?(user.role)
      user.role
    end
  end
  #
  # Override the clock off time to set it to now
  #
  def clock_off
    self.clock_off_time = DateTime.now
    save!
  end

  #
  # Returns all currently active sessions
  #
  def self.active_sessions
    where('clock_off_time > ?', DateTime.now)
  end

  #
  # Returns all users currently working now
  #
  def self.users_working_now
    active_sessions.map(&:user)
  end

  #
  # Returns true if this session is clocked off
  #
  def clocked_off?
    clock_off_time < DateTime.now
  end

  #
  # Returns true if this session is clocked on
  #
  def clocked_on?
    !clocked_off?
  end

  #
  # Checks if the user provided is currently clocked off
  #
  def self.user_clocked_off?(user)
    # Should have no sessions clocked on thus nothing found clocked on
    user.helpdesk_sessions.find(&:clocked_on?).nil?
  end

  #
  # Checks if the user provided is currently clocked on
  #
  def self.user_clocked_on?(user)
    !user_clocked_off(user)
  end
end
