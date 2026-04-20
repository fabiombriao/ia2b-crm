class Crm::Stage < ApplicationRecord
  belongs_to :pipeline, class_name: 'Crm::Pipeline'

  has_many :deals, class_name: 'Crm::Deal', dependent: :nullify

  validates :name, presence: true
  validates :position, presence: true
  validates :pipeline_id, presence: true

  default_scope { order(position: :asc) }
end
