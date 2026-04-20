FactoryBot.define do
  factory :crm_stage, class: 'Crm::Stage' do
    pipeline { create(:crm_pipeline) }
    name { "Stage #{SecureRandom.hex(4)}" }
    position { 1 }
    color { '#3B82F6' }
  end
end
