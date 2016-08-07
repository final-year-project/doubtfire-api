class CreateHelpdeskSessions < ActiveRecord::Migration
  def change
    create_table :helpdesk_sessions do |t|
      t.references :user, null: false
      t.datetime :clock_on_time, null: false
      t.datetime :clock_off_time, null: false
      t.timestamps
    end
    add_index :helpdesk_sessions, :user_id
  end
end
