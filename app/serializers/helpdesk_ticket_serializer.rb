class HelpdeskTicketSerializer < ActiveModel::Serializer
  attributes :id,
             :student,
             :task,
             :task_definition_id,
             :tutorial,
             :target_grade,
             :description,
             :is_resolved,
             :is_closed,
             :project_id,
             :created_at,
             :resolved_at,
             :minutes_to_resolve

  has_one :task, serializer: ShallowTaskSerializer

  def project_id
    object.project.id
  end

  def student
    ShallowUserSerializer.new object.student
  end

  def tutorial
    TutorialSerializer.new object.project.tutorial
  end

  def target_grade
    object.project.target_grade
  end

  def task_definition_id
    task = object.task
    task.task_definition_id if task
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
             :resolved_at,
             :minutes_to_resolve

  def task_definition_id
    task = object.task
    task.task_definition_id if task
  end
end
