class ParticipantPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    index?
  end

  def destroy?
    admin?
  end

  def export_participants?
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
