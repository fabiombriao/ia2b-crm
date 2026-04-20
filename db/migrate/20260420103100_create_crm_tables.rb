class CreateCrmTables < ActiveRecord::Migration[7.1]
  def change
    create_pipelines
    create_stages
    create_deals
    create_activities
  end

  private

  def create_pipelines
    create_table :crm_pipelines, if_not_exists: true do |t|
      t.string :name, null: false
      t.integer :account_id, null: false
      t.boolean :default, default: false, null: false
      t.timestamps
    end
  end

  def create_stages
    create_table :crm_stages, if_not_exists: true do |t|
      t.string :name, null: false
      t.integer :position, null: false
      t.integer :pipeline_id, null: false
      t.string :color, default: '#3B82F6'
      t.timestamps
    end
  end

  def create_deals
    create_table :crm_deals, if_not_exists: true do |table|
      add_deal_core_columns(table)
      add_deal_status_columns(table)
      add_deal_association_columns(table)
      table.timestamps
    end
  end

  def add_deal_core_columns(table)
    table.string :title, null: false
    table.text :description
    table.decimal :value, precision: 10, scale: 2, default: 0.0
  end

  def add_deal_status_columns(table)
    table.string :status, null: false, default: 'open'
    table.string :currency
    table.date :expected_close_date
    table.datetime :closed_at
    table.text :lost_reason
    table.string :source
  end

  def add_deal_association_columns(table)
    table.integer :position
    table.integer :stage_id, null: false
    table.integer :company_id
    table.integer :account_id, null: false
    table.integer :contact_id
    table.integer :user_id
  end

  def create_activities
    create_table :crm_activities, if_not_exists: true do |table|
      add_activity_columns(table)
      table.timestamps
    end
  end

  def add_activity_columns(table)
    table.string :activity_type, null: false
    table.string :subject, null: false
    table.text :description
    table.datetime :due_at
    table.boolean :completed, default: false, null: false
    table.datetime :completed_at
    table.integer :account_id, null: false
    table.integer :deal_id
    table.integer :contact_id
    table.integer :user_id, null: false
  end
end
