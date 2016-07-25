class AddResolvedAtToHelpdeskTicket < ActiveRecord::Migration
  def change
    add_column :helpdesk_tickets, :resolved_at, :datetime
  end
end
