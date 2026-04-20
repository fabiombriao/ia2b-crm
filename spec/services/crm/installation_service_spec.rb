require 'rails_helper'

RSpec.describe Crm::InstallationService do
  let(:account) { create(:account) }
  let(:actor) { create(:user, account: account, role: :administrator) }
  let(:service) { described_class.new(account: account, actor: actor) }

  describe '#bootstrap!' do
    it 'is idempotent and creates a default pipeline with stages' do
      expect { service.bootstrap! }
        .to change(Crm::Pipeline, :count).by(1)
        .and change(Crm::Stage, :count).by(described_class::DEFAULT_STAGES.size)

      expect { service.bootstrap! }.not_to change(Crm::Pipeline, :count)
      expect { service.bootstrap! }.not_to change(Crm::Stage, :count)

      pipeline = Crm::Pipeline.find_by!(account_id: account.id, name: described_class::DEFAULT_PIPELINE_NAME)
      expect(pipeline.default).to be(true)

      stage_names = pipeline.stages.pluck(:name)
      expect(stage_names).to match_array(described_class::DEFAULT_STAGES.map { |s| s[:name] })
    end

    it 'ensures the default pipeline flag is set' do
      pipeline = create(:crm_pipeline, account: account, name: described_class::DEFAULT_PIPELINE_NAME, default: false)

      service.bootstrap!

      expect(pipeline.reload.default).to be(true)
    end
  end

  describe '#enable! and #disable!' do
    it 'toggles installation state' do
      expect(service.enabled?).to be(false)

      service.enable!
      expect(service.enabled?).to be(true)

      service.disable!
      expect(service.enabled?).to be(false)
    end
  end
end
