class Api::V1::Accounts::Crm::ActivitiesController < Api::V1::Accounts::Crm::BaseController
  before_action -> { authorize([:crm, :activity]) }
  before_action :fetch_activity, only: [:show, :update, :complete]

  def index
    @activities = preload_activities(apply_filters(policy_scope(Crm::Activity).order(created_at: :desc)))
  end

  def show; end

  def create
    @activity = Crm::Activity.create!(activity_params.merge(account_id: Current.account.id, user_id: resolved_user_id))
  end

  def update
    @activity.update!(activity_params)
  end

  def complete
    @activity.update!(completed: true, completed_at: Time.current)
    render :show
  end

  private

  def fetch_activity
    @activity = policy_scope(Crm::Activity).find(params[:id])
  end

  def resolved_user_id
    activity_params[:user_id].presence || Current.user.id
  end

  def activity_params
    permitted = params.require(:activity).permit(:activity_type, :subject, :description, :due_at, :completed, :deal_id, :contact_id, :user_id)
    permitted[:activity_type] ||= params.dig(:activity, :type)
    permitted
  end

  def apply_filters(activities)
    activities = activities.where(deal_id: params[:deal_id]) if params[:deal_id].present?
    activities = activities.where(contact_id: params[:contact_id]) if params[:contact_id].present?
    activities = activities.where(completed: params[:completed]) if params[:completed].present?
    activities
  end

  def preload_activities(activities)
    activities = activities.includes(:deal) if Crm::Activity.reflect_on_association(:deal).present?
    activities = activities.includes(:contact) if Crm::Activity.reflect_on_association(:contact).present?
    activities = activities.includes(:user) if Crm::Activity.reflect_on_association(:user).present?
    activities
  end
end
