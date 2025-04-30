class StudentPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin_or_owner?
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

  def import?
    admin?
  end

  def template?
    admin?
  end

  private

  def admin?
    user.student.nil? && user.admin?
  end

  def student
    user.student?
  end
end
