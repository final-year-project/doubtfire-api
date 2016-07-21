#
# Tracking for tickets logged at the helpdesk.
#
class HelpdeskTicket < ActiveRecord::Base
  # Model associations
  belongs_to :project
  belongs_to :task

  # Model constratins/validation
  validates :project, presence: true # Must always be associated to a project

  #
  # Permissions around group data
  #
  def self.permissions
    # What can students do with all tickets?
    student_role_permissions = [
    ]
    # What can tutors do with all tickets?
    tutor_role_permissions = [
      :get_tickets
    ]
    # What can convenors do with all tickets?
    convenor_role_permissions = [
      :get_tickets
    ]
    # What can admins do with all tickets?
    admin_role_permissions = [
      :get_tickets
    ]
    # What can nil users do with all tickets?
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

  # Returns back all unresolved tickets
  def self.all_unresolved
    where(is_resolved: false)
  end

  # Returns back all resolved tickets
  def self.all_resolved
    where(is_resolved: true)
  end

  # Resolves the ticket
  def resolve
    self.is_resolved = true
    self.save!
  end

  # Unit for ticket
  def unit
    project.unit
  end

  # Student for ticket
  def student
    project.student
  end

  # Returns true if ticket is associated with a task
  def has_task?
    !task.nil?
  end
end
