require 'project_serializer'
require 'task_definition_serializer'

class HelpdeskTicketSerializer < ActiveModel::Serializer
  attributes :id,
             :project,
             :task_definition,
             :description,
             :is_resolved,
             :is_closed,
             :created_at,
             :closed_at,
             :minutes_to_resolve

  def project
    ShallowProjectSerializer.new object.project
  end

  def task_definition
    task = object.task
    ShallowTaskDefinitionSerializer.new task.task_definition if task
  end
end

class ShallowHelpdeskTicketSerializer < ActiveModel::Serializer
  attributes :id,
             :project_id,
             :task_definition_id,
             :description,
             :is_resolved,
             :is_closed,
             :created_at,
             :closed_at,
             :minutes_to_resolve

  def task_definition_id
    task = object.task
    task.task_definition_id if task
  end
end
