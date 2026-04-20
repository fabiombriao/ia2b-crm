class Api::V1::Accounts::Crm::StagesController < Api::V1::Accounts::Crm::BaseController
  before_action -> { authorize([:crm, :stage]) }
  before_action :fetch_pipeline, only: [:create]
  before_action :fetch_stage, only: [:update]

  def create
    @stage = Crm::Stage.create!(stage_params.merge(pipeline_id: @pipeline.id))
  end

  def update
    @stage.update!(stage_params)
  end

  private

  def fetch_pipeline
    @pipeline = policy_scope(Crm::Pipeline).find(params[:pipeline_id])
  end

  def fetch_stage
    @stage = Crm::Stage.joins(:pipeline).where(crm_pipelines: { account_id: Current.account.id }).find(params[:id])
  end

  def stage_params
    params.require(:stage).permit(:name, :position, :color)
  end
end
