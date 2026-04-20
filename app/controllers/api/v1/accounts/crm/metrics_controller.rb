class Api::V1::Accounts::Crm::MetricsController < Api::V1::Accounts::Crm::BaseController
  before_action -> { authorize([:crm, :metrics]) }

  def show
    deals = policy_scope(Crm::Deal)

    @open_deals_count = deals.where(status: 'open').count
    @open_value = deals.where(status: 'open').sum(:value)
    @won_value = deals.where(status: 'won').sum(:value)

    @overdue_activities_count = policy_scope(Crm::Activity).where(completed: false).where('due_at < ?', Time.current).count
  end
end
