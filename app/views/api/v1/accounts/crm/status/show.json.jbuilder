json.feature_enabled @crm_feature_enabled
json.enabled @crm_enabled

json.installation do
  if @crm_installation.present?
    json.id @crm_installation.id
    json.enabled @crm_installation.enabled
    json.platform_app_id @crm_installation.platform_app_id
    json.account_id @crm_installation.account_id
  end
end

