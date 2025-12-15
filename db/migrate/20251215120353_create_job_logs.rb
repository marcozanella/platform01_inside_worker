class CreateJobLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :job_logs do |t|
      t.string :name, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :job_logs, :name, unique: true
    add_index :job_logs, :status
    add_index :job_logs, :created_at
  end
end
