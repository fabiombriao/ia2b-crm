json.id resource.id
json.account_id resource.account_id
json.name resource.name
json.default resource.default
json.created_at resource.created_at.to_i if resource[:created_at].present?
json.updated_at resource.updated_at.to_i if resource[:updated_at].present?

if defined?(with_stages) && with_stages.present?
  json.stages do
    json.array! resource.stages do |stage|
      json.partial! 'api/v1/models/crm_stage', formats: [:json], resource: stage
    end
  end
end
