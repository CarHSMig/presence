class EventPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.student.present?
        scope.joins(:participants).where(participants: { student_id: user.student.id }).distinct
      else
        scope.all
      end
    end
  end

  def index?
    admin? || student?
  end

  def show?
    admin?
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

  def classrooms_by_courses?
    admin?
  end

  private

  def admin?
    user.student.nil? && user.admin?
  end

  def student?
    user.student.present?
  end
end
