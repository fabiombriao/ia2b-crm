json.payload do
  json.array! @pipelines do |pipeline|
    json.partial! 'api/v1/models/crm_pipeline', formats: [:json], resource: pipeline, with_stages: true
  end
end

