class Crm::InstallationService
  PLATFORM_APP_NAME = 'ia2b_crm'.freeze

  DEFAULT_PIPELINE_NAME = 'Padrão'.freeze
  DEFAULT_STAGES = [
    { name: 'Novo', color: '#3B82F6' },
    { name: 'Qualificado', color: '#6366F1' },
    { name: 'Proposta', color: '#10B981' },
    { name: 'Negociação', color: '#F59E0B' },
    { name: 'Ganho', color: '#22C55E' },
    { name: 'Perdido', color: '#EF4444' }
  ].freeze

  def initialize(account:, actor: nil)
    @account = account
    @actor = actor
  end

  def platform_app
    @platform_app ||= PlatformApp.find_or_create_by!(name: PLATFORM_APP_NAME)
  end

  def installation
    @installation ||= PlatformAppInstallation.find_or_create_by!(platform_app_id: platform_app.id, account_id: @account.id)
  end

  def enabled?
    installation.enabled?
  end

  def enable!
    ActiveRecord::Base.transaction do
      installation.update!(enabled: true, installed_by: @actor)
      bootstrap!
    end

    installation
  end

  def disable!
    installation.update!(enabled: false, installed_by: @actor)
    installation
  end

  def bootstrap!
    pipeline = Crm::Pipeline.find_or_create_by!(account_id: @account.id, name: DEFAULT_PIPELINE_NAME) do |p|
      p.default = true
    end
    pipeline.update!(default: true) unless pipeline.default?

    DEFAULT_STAGES.each_with_index do |stage, index|
      Crm::Stage.find_or_create_by!(pipeline_id: pipeline.id, position: index + 1) do |s|
        s.name = stage[:name]
        s.color = stage[:color]
      end
    end

    pipeline
  end
end
