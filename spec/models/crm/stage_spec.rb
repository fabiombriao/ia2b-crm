require 'rails_helper'

RSpec.describe Crm::Stage do
  describe 'associations' do
    it { is_expected.to belong_to(:pipeline) }
    it { is_expected.to have_many(:deals).dependent(:nullify) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:position) }
  end
end
