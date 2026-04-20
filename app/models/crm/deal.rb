class Crm::Deal < ApplicationRecord
  STATUSES = %w[open won lost].freeze

  belongs_to :account
  belongs_to :stage, class_name: 'Crm::Stage'
  belongs_to :contact, optional: true
  belongs_to :user, optional: true

  has_many :activities, class_name: 'Crm::Activity', dependent: :nullify

  validates :title, presence: true
  validates :account_id, presence: true
  validates :stage_id, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :value, numericality: true, allow_nil: true

  validate :stage_belongs_to_account

  private

  def stage_belongs_to_account
    return if stage.blank?
    return if stage.pipeline&.account_id == account_id

    errors.add(:stage_id, 'is invalid')
  end
end
