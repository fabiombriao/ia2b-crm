class Api::V1::Accounts::Crm::ContactsController < Api::V1::Accounts::Crm::BaseController
  before_action -> { authorize([:crm, :contact_context]) }
  before_action :fetch_contact

  def context
    @open_deals = policy_scope(Crm::Deal).where(contact_id: @contact.id, status: 'open').includes(:stage).order(created_at: :desc)
    @pending_activities = policy_scope(Crm::Activity).where(contact_id: @contact.id, completed: false).order(due_at: :asc)
  end

  private

  def fetch_contact
    @contact = Current.account.contacts.find(params[:id])
  end
end
