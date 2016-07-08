#
# Tracking for tickets logged at the helpdesk.
#
class HelpdeskTicket < ActiveRecord::Base
  # Model associations
  belongs_to :project
  belongs_to :task

  # Model constratins/validation
  validates :project, presence: true # Must always be associated to a project

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

  # Returns true iff ticket is associated with a task
  def has_task?
    !task.nil?
  end
end
