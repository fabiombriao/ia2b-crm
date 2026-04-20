json.id resource.id
json.account_id resource.account_id
json.title resource.title
json.description resource.description
json.value resource.value
json.status resource.status
json.currency resource.currency
json.expected_close_date resource.expected_close_date
json.closed_at resource.closed_at&.to_i
json.lost_reason resource.lost_reason
json.source resource.source
json.position resource.position
json.stage_id resource.stage_id
json.contact_id resource.contact_id
json.user_id resource.user_id
json.created_at resource.created_at.to_i if resource[:created_at].present?
json.updated_at resource.updated_at.to_i if resource[:updated_at].present?

if defined?(with_stage) && with_stage.present? && resource.respond_to?(:stage) && resource.stage.present?
  json.stage do
    json.partial! 'api/v1/models/crm_stage', formats: [:json], resource: resource.stage
  end
end
