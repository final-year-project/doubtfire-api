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

  # Clock on time is only set on creation of the session
  attr_readonly :clock_on_time

  # Always initialise clock_on_time to when the session is created (now)
  after_initialize :set_clock_on_time_to_now
  def set_clock_on_time_to_now
    self.clock_on_time = DateTime.now
  end

  #
  # Override the clock off time to set it to now
  #
  def clock_off
    self.clock_off_time = DateTime.now
    save!
  end
end
