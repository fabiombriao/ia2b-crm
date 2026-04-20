class Crm::Activity < ApplicationRecord
  self.inheritance_column = :_type_disabled

  ACTIVITY_TYPES = %w[
    task
    call
    meeting
    email
    whatsapp
    note
    follow_up
  ].freeze

  belongs_to :account
  belongs_to :user
  belongs_to :deal, class_name: 'Crm::Deal', optional: true
  belongs_to :contact, optional: true

  validates :activity_type, presence: true, inclusion: { in: ACTIVITY_TYPES }
  validates :subject, presence: true
  validates :account_id, presence: true
  validates :user_id, presence: true
end
