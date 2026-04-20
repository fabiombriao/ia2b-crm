class PlatformAppInstallation < ApplicationRecord
  belongs_to :platform_app
  belongs_to :account
  belongs_to :installed_by, class_name: 'User', optional: true

  validates :platform_app, presence: true
  validates :account, presence: true
  validates :platform_app_id, uniqueness: { scope: :account_id }
end
