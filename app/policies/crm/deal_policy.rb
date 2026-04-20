class Crm::DealPolicy < ApplicationPolicy
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

  def move?
    true
  end

  def mark_won?
    true
  end

  def mark_lost?
    true
  end

  class Scope < Scope
    def resolve
      scope.where(account_id: account.id)
    end
  end
end
