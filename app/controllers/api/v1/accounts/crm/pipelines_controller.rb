class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::Crm::BaseController
  before_action -> { authorize([:crm, :pipeline]) }
  before_action :fetch_pipeline, only: [:update]

  def index
    @pipelines = policy_scope(Crm::Pipeline).includes(:stages).order(:id)
  end

  def create
    @pipeline = Crm::Pipeline.create!(pipeline_params.merge(account_id: Current.account.id))
  end

  def update
    @pipeline.update!(pipeline_params)
  end

  private

  def fetch_pipeline
    @pipeline = policy_scope(Crm::Pipeline).find(params[:id])
  end

  def pipeline_params
    params.require(:pipeline).permit(:name, :default)
  end
end
