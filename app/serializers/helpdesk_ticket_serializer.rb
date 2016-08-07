class HelpdeskTicketSerializer < ActiveModel::Serializer
  attributes :id,
             :student,
             :task,
             :tutorial,
             :target_grade,
             :description,
             :is_resolved,
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
end
