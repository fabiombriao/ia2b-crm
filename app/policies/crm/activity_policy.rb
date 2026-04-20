class Crm::ActivityPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    true
  end

  def complete?
    true
  end

  class Scope < Scope
    def resolve
      scope.where(account_id: account.id)
    end
  end
end
