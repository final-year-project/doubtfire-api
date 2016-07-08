class ChangeHelpdeskTicketCommentToDescription < ActiveRecord::Migration
  def change
    rename_column :helpdesk_tickets, :comments, :description
    change_column :helpdesk_tickets, :description, :string, :limit => 2048
  end
end
