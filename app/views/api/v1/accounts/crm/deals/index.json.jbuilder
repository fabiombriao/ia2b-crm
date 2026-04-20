json.payload do
  json.array! @deals do |deal|
    json.partial! 'api/v1/models/crm_deal', formats: [:json], resource: deal, with_stage: true
  end
end
