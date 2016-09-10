class RenameResolvedAtToClosedAt < ActiveRecord::Migration
  def change
    rename_column :helpdesk_tickets, :resolved_at, :closed_at
  end
end
