class AddIsClosedToHelpdeskTicket < ActiveRecord::Migration
  def change
    add_column :helpdesk_tickets, :is_closed, :boolean, :default => false
  end
end
