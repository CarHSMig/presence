User.create!(
  name: 'Admin',
  email: 'admin@university.presence',
  password: '123456',
  password_confirmation: '123456',
  admin: true
)
User.create!(
  name: 'Alan',
  email: 'alan@university.presence',
  password: '123456',
  password_confirmation: '123456',
  admin: true
)

course = Course.create(name: 'Análise e Desenvolvimento de Sistemas', periods: 6)
Course.create(name: 'Direito', periods: 10)
Course.create(name: 'Enfermagem', periods: 10)

class_room = ClassRoom.create!(name: 'Turma A', course: course, period: 2)

Student.create!([
                  { name: 'Sofia Duarte Moreira', ra: '900025-1', class_room: class_room },
                  { name: 'Camila Nogueira Barbosa', ra: '900007-1', class_room: class_room }
                ])

student = Student.last

User.create!(
  name: 'Estudante',
  email: 'student@university.presence',
  password: '123456',
  password_confirmation: '123456',
  admin: false,
  student: student
)

puts 'Seed concluido com sucesso!'
