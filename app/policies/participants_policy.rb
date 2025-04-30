class ParticipantsPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    index?
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
