class CreateJobLogDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :job_log_details do |t|
      t.references :job_log, null: false, foreign_key: true
      t.text :message, null: false

      t.timestamps
    end
    add_index :job_log_details, :created_at
  end
end
