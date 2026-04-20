class Crm::Pipeline < ApplicationRecord
  belongs_to :account

  has_many :stages, class_name: 'Crm::Stage', dependent: :destroy

  validates :name, presence: true
  validates :account_id, presence: true
  validates :name, uniqueness: { scope: :account_id }
end
