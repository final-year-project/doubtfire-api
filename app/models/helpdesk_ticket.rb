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
      :get_details
    ]
    # What can tutors do with all tickets?
    tutor_role_permissions = [
      :get_tickets,
      :get_details
    ]
    # What can convenors do with all tickets?
    convenor_role_permissions = [
      :get_tickets,
      :get_details
    ]
    # What can admins do with all tickets?
    admin_role_permissions = [
      :get_tickets,
      :get_details
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

  def role_for(user)
    if user == project.user
      Role.student
    elsif user.role != Role.student
      user.role
    else
      nil
    end
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

  # Get all tickets resolved between two dates
  def self.resolved_betweeen(from = nil, to = DateTime.now)
    to ||= DateTime.now # if nil is passed in
    from ? all_resolved.where(resolved_at: from..to) : all_resolved
  end

  # Calculates the average time to resolve a ticket from the duration
  # provided (i.e., between from and now). If no arguments are provided,
  # all resolved tickets will be used regardless of when they were resolved.
  # Where no tickets are found within the period, nil is returned.
  def self.average_resolve_time(from = nil, to = DateTime.now)
    tickets = resolved_betweeen(from, to)
    resolved_betweeen(from, to).average(:minutes_to_resolve).to_f unless tickets.empty?
  end

  # Resolves the ticket
  def resolve
    self.is_resolved = true
    self.resolved_at = DateTime.now
    self.minutes_to_resolve = ((resolved_at - created_at) / 60).to_f.round(2)
    save!
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
