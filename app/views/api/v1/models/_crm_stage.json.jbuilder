json.id resource.id
json.pipeline_id resource.pipeline_id
json.name resource.name
json.position resource.position
json.color resource.color
json.created_at resource.created_at.to_i if resource[:created_at].present?
json.updated_at resource.updated_at.to_i if resource[:updated_at].present?
