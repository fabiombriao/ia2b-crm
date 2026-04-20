class Crm::PipelinePolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    account_user.administrator?
  end

  def update?
    account_user.administrator?
  end

  class Scope < Scope
    def resolve
      scope.where(account_id: account.id)
    end
  end
end
