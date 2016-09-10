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
      :get_tickets,
      :get_stats,
      :close_ticket
    ]
    # What can tutors|convenors|admins do with all tickets?
    tutor_role_permissions = convenor_role_permissions = admin_role_permissions = [
      :get_tickets,
      :get_details,
      :get_stats,
      :close_ticket,
      :resolve_ticket
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

  # Returns true if a used has a ticket open
  def self.user_has_ticket_open?(user_id)
    !all_unresolved(user_id).empty?
  end

  # Returns back all unresolved tickets, optionally limit to a user
  def self.all_unresolved(user_id = nil)
    all_by_state(:unresolved, user_id)
  end

  # Returns back all resolved tickets, optionally limit to a user
  def self.all_resolved(user_id = nil)
    all_by_state(:resolved, user_id)
  end

  # Returns back all closed tickets, optionally limit to a user
  def self.all_closed(user_id = nil)
    all_by_state(:closed, user_id)
  end

  # Finds tickets of a particular status, optionally limit to a user
  def self.all_by_state(resolved_filter, user_id = nil)
    tickets =
      case resolved_filter
      when :resolved
        where(is_resolved: true)
      when :unresolved
        where(is_closed: false)
      when :closed
        where(is_closed: true, is_resolved: false)
      else
        all
      end

    unless user_id.nil?
      user = User.find(user_id)
      project = Project.for_user(user, false) # see app/models/project.rb:76
      tickets = tickets.where(project: project) # limits the scope of tickets down to those with the project provided
    end

    tickets.order(:created_at)
  end

  # Get all tickets resolved between two dates
  def self.resolved_between(from = nil, to = DateTime.now)
    to ||= DateTime.now # if nil is passed in
    from ? all_resolved.where(closed_at: from..to) : all_resolved
  end

  # Calculates the average time to resolve a ticket from the duration
  # provided (i.e., between from and now). If no arguments are provided,
  # all resolved tickets will be used regardless of when they were resolved.
  # Where no tickets are found within the period, nil is returned.
  def self.average_resolve_time_between(from = nil, to = DateTime.now)
    tickets = resolved_between(from, to)
    resolved_between(from, to).average(:minutes_to_resolve).to_f unless tickets.empty?
  end

  #
  # Determines the current average wait time for a ticket
  #
  def self.average_wait_time(from, to)
    avg_resolve = HelpdeskTicket.average_resolve_time_between(from, to) || 0
    avg_resolve * HelpdeskTicket.all_unresolved.length
  end

  # Resolves the ticket
  def resolve
    unless is_closed
      # Resolving closes the ticket
      close
      self.is_resolved = true
      self.minutes_to_resolve = ((closed_at - created_at) / 60).to_f.round(2)
      save!
    end
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
  def task?
    !task.nil?
  end

  # Prematurely closes a ticket
  def close
    unless is_closed
      self.is_closed = true
      self.closed_at = DateTime.now
      save!
    end
  end
end
