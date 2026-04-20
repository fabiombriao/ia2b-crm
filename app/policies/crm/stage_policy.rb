class Crm::StagePolicy < ApplicationPolicy
  def create?
    account_user.administrator?
  end

  def update?
    account_user.administrator?
  end
end
