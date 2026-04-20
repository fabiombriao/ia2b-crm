class CreateCrmTables < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_pipelines, if_not_exists: true do |t|
      t.string :name, null: false
      t.integer :account_id, null: false
      t.boolean :default, default: false
      t.timestamps
    end

    create_table :crm_stages, if_not_exists: true do |t|
      t.string :name, null: false
      t.integer :position, null: false
      t.integer :pipeline_id, null: false
      t.string :color, default: '#3B82F6'
      t.timestamps
    end

    create_table :crm_deals, if_not_exists: true do |t|
      t.string :title, null: false
      t.text :description
      t.decimal :value, precision: 10, scale: 2, default: 0.0
      t.string :status, null: false, default: 'open'
      t.string :currency
      t.date :expected_close_date
      t.datetime :closed_at
      t.text :lost_reason
      t.string :source
      t.integer :position
      t.integer :stage_id, null: false
      t.integer :company_id
      t.integer :account_id, null: false
      t.integer :contact_id
      t.integer :user_id
      t.timestamps
    end

    create_table :crm_activities, if_not_exists: true do |t|
      t.string :activity_type, null: false
      t.string :subject, null: false
      t.text :description
      t.datetime :due_at
      t.boolean :completed, default: false
      t.datetime :completed_at
      t.integer :account_id, null: false
      t.integer :deal_id
      t.integer :contact_id
      t.integer :user_id, null: false
      t.timestamps
    end
  end
end
