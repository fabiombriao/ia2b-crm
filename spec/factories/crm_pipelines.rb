FactoryBot.define do
  factory :crm_pipeline, class: 'Crm::Pipeline' do
    account
    name { "Pipeline #{SecureRandom.hex(4)}" }
    default { false }
  end
end
