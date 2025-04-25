module StudentManagement
  class Create
    def initialize(params)
      @params = params
    end

    def call
      if @params.present?
        perform
      else
        raise ArgumentError, "Parameters cannot be nil or empty"
      end
    end

    def perform
      ActiveRecord::Base.transaction do
        user = create_user
        student = create_student(user)
        if student.valid?
          UserMailer.with(user: user).welcome_email.deliver_now
        else
          raise ActiveRecord::Rollback
        end
        student
      end
    end

    private

    def create_user
      User.create!(
        name: @params[:name],
        email: @params[:email],
        password: SecureRandom.hex(10),
        admin: false
      )
    end

    def create_student(user = nil)
      Student.create!(
        name: @params[:name],
        ra: @params[:ra],
        class_room_id: @params[:class_room_id],
        user: user
      )
    end
  end
end
