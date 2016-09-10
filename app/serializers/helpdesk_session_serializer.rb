require 'user_serializer'

class HelpdeskSessionSerializer < ActiveModel::Serializer
  attributes :id,
             :user,
             :clocked_on?,
             :clock_on_time,
             :clock_off_time

  has_one :user, serializer: HelpdeskUserSerializer

  def clocked_on?
    object.clocked_on?
  end
end
