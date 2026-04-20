class UpdateCrmTablesForCrmV2 < ActiveRecord::Migration[7.1]
  def change
    return unless table_exists?(:crm_deals) && table_exists?(:crm_activities)

    change_table :crm_deals, bulk: true do |t|
      t.string :status, null: false, default: 'open' unless column_exists?(:crm_deals, :status)
      t.string :currency unless column_exists?(:crm_deals, :currency)
      t.date :expected_close_date unless column_exists?(:crm_deals, :expected_close_date)
      t.datetime :closed_at unless column_exists?(:crm_deals, :closed_at)
      t.text :lost_reason unless column_exists?(:crm_deals, :lost_reason)
      t.string :source unless column_exists?(:crm_deals, :source)
      t.integer :position unless column_exists?(:crm_deals, :position)
    end

    rename_column :crm_activities, :type, :activity_type if column_exists?(:crm_activities, :type) && !column_exists?(:crm_activities, :activity_type)

    change_table :crm_activities, bulk: true do |t|
      t.datetime :completed_at unless column_exists?(:crm_activities, :completed_at)
      t.boolean :completed, default: false unless column_exists?(:crm_activities, :completed)
    end

    add_index :crm_deals, [:account_id, :status] unless index_exists?(:crm_deals, [:account_id, :status])
    add_index :crm_deals, [:stage_id, :position] unless index_exists?(:crm_deals, [:stage_id, :position])
    add_index :crm_deals, [:user_id, :status] unless index_exists?(:crm_deals, [:user_id, :status])
    add_index :crm_deals, :contact_id unless index_exists?(:crm_deals, :contact_id)

    add_index :crm_activities, [:account_id, :due_at] unless index_exists?(:crm_activities, [:account_id, :due_at])
    add_index :crm_activities, [:account_id, :completed] unless index_exists?(:crm_activities, [:account_id, :completed])
  end
end
