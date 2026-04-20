class UpdateCrmTablesForCrmV2 < ActiveRecord::Migration[7.1]
  def change
    return unless table_exists?(:crm_deals) && table_exists?(:crm_activities)

    update_deals_columns
    rename_activity_type_column
    update_activities_columns
    add_deals_indexes
    add_activities_indexes
  end

  private

  def update_deals_columns
    change_table :crm_deals, bulk: true do |t|
      add_deal_column(t, :string, :status, null: false, default: 'open')
      add_deal_column(t, :string, :currency)
      add_deal_column(t, :date, :expected_close_date)
      add_deal_column(t, :datetime, :closed_at)
      add_deal_column(t, :text, :lost_reason)
      add_deal_column(t, :string, :source)
      add_deal_column(t, :integer, :position)
    end
  end

  def add_deal_column(table, type, column_name, **)
    return if column_exists?(:crm_deals, column_name)

    table.public_send(type, column_name, **)
  end

  def rename_activity_type_column
    return unless column_exists?(:crm_activities, :type)
    return if column_exists?(:crm_activities, :activity_type)

    rename_column :crm_activities, :type, :activity_type
  end

  def update_activities_columns
    change_table :crm_activities, bulk: true do |t|
      t.datetime :completed_at unless column_exists?(:crm_activities, :completed_at)
      t.boolean :completed, default: false, null: false unless column_exists?(:crm_activities, :completed)
    end
  end

  def add_deals_indexes
    add_index :crm_deals, [:account_id, :status] unless index_exists?(:crm_deals, [:account_id, :status])
    add_index :crm_deals, [:stage_id, :position] unless index_exists?(:crm_deals, [:stage_id, :position])
    add_index :crm_deals, [:user_id, :status] unless index_exists?(:crm_deals, [:user_id, :status])
    add_index :crm_deals, :contact_id unless index_exists?(:crm_deals, :contact_id)
  end

  def add_activities_indexes
    add_index :crm_activities, [:account_id, :due_at] unless index_exists?(:crm_activities, [:account_id, :due_at])
    add_index :crm_activities, [:account_id, :completed] unless index_exists?(:crm_activities, [:account_id, :completed])
  end
end
