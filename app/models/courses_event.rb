class CoursesEvent < ApplicationRecord
  belongs_to :course
  belongs_to :event
end
