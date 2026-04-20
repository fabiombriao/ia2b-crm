class CreatePlatformAppInstallations < ActiveRecord::Migration[7.1]
  def change
    create_table :platform_app_installations do |t|
      t.bigint :platform_app_id, null: false
      t.integer :account_id, null: false
      t.boolean :enabled, default: false, null: false
      t.jsonb :settings, default: {}, null: false
      t.bigint :installed_by_id

      t.timestamps
    end

    add_index :platform_app_installations, [:platform_app_id, :account_id], unique: true,
                                                                            name: 'index_platform_app_installations_on_app_and_account'
    add_index :platform_app_installations, :account_id
    add_index :platform_app_installations, :platform_app_id
  end
end
