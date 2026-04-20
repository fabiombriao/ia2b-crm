class Api::V1::Accounts::Crm::StatusController < Api::V1::Accounts::BaseController
  def show
    authorize([:crm, :status])

    installation_service = Crm::InstallationService.new(account: Current.account)
    @crm_feature_enabled = Current.account.feature_enabled?('crm_v2')
    @crm_enabled = installation_service.enabled?
    @crm_installation = installation_service.installation
  end
end
