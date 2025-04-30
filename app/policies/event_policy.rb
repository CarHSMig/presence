class EventPolicy < ApplicationPolicy
  def index?
    admin? || student?
  end

  def show?
    index?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  private

  def admin?
    user.student.nil? && user.admin?
  end

  def student
    user.student.present?
  end
end
