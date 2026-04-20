require 'rails_helper'

RSpec.describe Crm::Pipeline do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:stages).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    it 'validates uniqueness of name scoped to account' do
      account = create(:account)
      create(:crm_pipeline, account: account, name: 'Default')

      duplicate = build(:crm_pipeline, account: account, name: 'Default')
      expect(duplicate.valid?).to be(false)
      expect(duplicate.errors[:name]).to be_present
    end
  end
end
