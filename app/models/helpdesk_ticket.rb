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
      :get_details,
      :get_stats
    ]
    # What can tutors|convenors|admins do with all tickets?
    tutor_role_permissions = convenor_role_permissions = admin_role_permissions = [
      :get_tickets,
      :get_details,
      :get_stats
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

  def self.user_has_ticket_open?(user_id)
    not all_resolved(user_id).empty?
  end

  # Returns back all unresolved tickets, optionally limit to a user
  def self.all_unresolved(user_id = nil)
    all_by_resolved_and_user('unresolved', user_id)
  end

  # Returns back all resolved tickets, optionally limit to a user
  def self.all_resolved(user_id = nil)
    all_by_resolved_and_user('resolved', user_id)
  end

  # Finds tickets of a particular resolved status, optionally limit to a user
  def self.all_by_resolved_and_user(resolved_filter, user_id = nil)
    tickets = nil

    case resolved_filter
    when "resolved"
      tickets = where(is_resolved: true)
    when "unresolved"
      tickets = where(is_resolved: false)
    else
      tickets = all
    end

    unless user_id.nil?
      user = User.find(user_id)
      project = Project.for_user(user, false) # see app/models/project.rb:76
      tickets = tickets.where(project: project) # limits the scope of tickets down to those with the project provided
    end

    tickets
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
  def self.average_resolve_time_between(from = nil, to = DateTime.now)
    tickets = resolved_betweeen(from, to)
    resolved_betweeen(from, to).average(:minutes_to_resolve).to_f unless tickets.empty?
  end
  def self.average_resolve_time
    average_resolve_time_between
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
