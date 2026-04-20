json.contact do
  json.partial! 'api/v1/models/contact', formats: [:json], resource: @contact
end

json.deals do
  json.array! @open_deals do |deal|
    json.partial! 'api/v1/models/crm_deal', formats: [:json], resource: deal, with_stage: true
  end
end

json.activities do
  json.array! @pending_activities do |activity|
    json.partial! 'api/v1/models/crm_activity', formats: [:json], resource: activity
  end
end

