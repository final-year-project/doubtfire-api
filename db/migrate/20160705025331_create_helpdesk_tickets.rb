class CreateHelpdeskTickets < ActiveRecord::Migration
  def change
    create_table :helpdesk_tickets do |t|
      t.references :project, null: false
      t.references :task, null: true

      t.string :comments, null: true
      t.boolean :is_resolved, null: false, default: false

      t.timestamps
    end
    add_index :helpdesk_tickets, :project_id
    add_index :helpdesk_tickets, :task_id
  end
end
