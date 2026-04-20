class Api::V1::Accounts::Crm::DealsController < Api::V1::Accounts::Crm::BaseController
  before_action -> { authorize([:crm, :deal]) }
  before_action :fetch_deal, only: [:show, :update, :move, :mark_won, :mark_lost]

  def index
    @deals = preload_deals(apply_filters(policy_scope(Crm::Deal).order(created_at: :desc)))
  end

  def show; end

  def create
    @deal = Crm::Deal.create!(deal_params.merge(account_id: Current.account.id))
  end

  def update
    @deal.update!(deal_params)
  end

  def move
    stage = stage_scope.find(params.require(:stage_id))
    @deal.update!(stage_id: stage.id, position: params[:position])
    render :show
  end

  def mark_won
    @deal.update!(status: 'won', closed_at: Time.current)
    render :show
  end

  def mark_lost
    @deal.update!(status: 'lost', closed_at: Time.current, lost_reason: params[:lost_reason])
    render :show
  end

  private

  def fetch_deal
    @deal = policy_scope(Crm::Deal).find(params[:id])
  end

  def deal_params
    params.require(:deal).permit(:title, :description, :value, :currency, :expected_close_date, :source, :position, :stage_id, :contact_id, :user_id)
  end

  def apply_filters(deals)
    deals = deals.where(filter_params) if filter_params.present?

    deals = deals.where(stage_id: stage_ids_for_pipeline(params[:pipeline_id])) if params[:pipeline_id].present?

    deals
  end

  def filter_params
    @filter_params ||= params.permit(:status, :stage_id, :contact_id, :user_id).to_h.compact_blank
  end

  def stage_ids_for_pipeline(pipeline_id)
    stage_scope.where(pipeline_id: pipeline_id).select(:id)
  end

  def stage_scope
    Crm::Stage.joins(:pipeline).where(crm_pipelines: { account_id: Current.account.id })
  end

  def preload_deals(deals)
    deals = deals.includes(:stage) if Crm::Deal.reflect_on_association(:stage).present?
    deals = deals.includes(:contact) if Crm::Deal.reflect_on_association(:contact).present?
    deals = deals.includes(:user) if Crm::Deal.reflect_on_association(:user).present?
    deals
  end
end
