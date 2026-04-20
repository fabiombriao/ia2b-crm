class Api::V1::Accounts::Crm::BaseController < Api::V1::Accounts::BaseController
  before_action :ensure_crm_installed!

  private

  def ensure_crm_installed!
    return if crm_enabled?

    render_error_response(CustomExceptions::Crm::NotInstalled.new({}))
  end

  def crm_enabled?
    service = crm_installation_service
    return false if service.blank?

    service.enabled?
  end

  def crm_installation
    crm_installation_service&.installation
  end

  def crm_installation_service
    @crm_installation_service ||= Crm::InstallationService.new(account: Current.account, actor: Current.user)
  end
end
