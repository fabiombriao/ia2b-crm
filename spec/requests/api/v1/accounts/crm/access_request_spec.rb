require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Crm access', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/crm/status' do
    it 'returns crm status even when disabled' do
      get "/api/v1/accounts/#{account.id}/crm/status",
          headers: admin.create_new_auth_token

      expect(response).to have_http_status(:success)
      json_response = response.parsed_body
      expect(json_response).to include('feature_enabled', 'enabled', 'installation')
      expect(json_response['enabled']).to be(false)
      expect(json_response['feature_enabled']).to be(false)
      expect(json_response['installation']).to include('account_id' => account.id, 'enabled' => false)
    end

    it 'reflects feature flag state' do
      account.enable_features('crm_v2')

      get "/api/v1/accounts/#{account.id}/crm/status",
          headers: admin.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['feature_enabled']).to be(true)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/crm/deals' do
    it 'returns forbidden when CRM is not installed/enabled' do
      Crm::InstallationService.new(account: account).disable!

      get "/api/v1/accounts/#{account.id}/crm/deals",
          headers: admin.create_new_auth_token

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq({ 'message' => I18n.t('errors.crm.not_installed') })
    end
  end
end
