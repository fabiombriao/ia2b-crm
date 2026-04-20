json.id resource.id
json.account_id resource.account_id
json.activity_type resource.activity_type
json.subject resource.subject
json.description resource.description
json.due_at resource.due_at&.to_i
json.completed resource.completed
json.completed_at resource.completed_at&.to_i
json.deal_id resource.deal_id
json.contact_id resource.contact_id
json.user_id resource.user_id
json.created_at resource.created_at.to_i if resource[:created_at].present?
json.updated_at resource.updated_at.to_i if resource[:updated_at].present?
