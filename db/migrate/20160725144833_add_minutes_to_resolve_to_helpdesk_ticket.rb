class AddMinutesToResolveToHelpdeskTicket < ActiveRecord::Migration
  def change
    add_column :helpdesk_tickets, :minutes_to_resolve, :float
  end
end
