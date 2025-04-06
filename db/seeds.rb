User.create!(
  name: "Admin",
  email: "admin@university.presence",
  password: "123456",
  password_confirmation: "123456",
  admin: true
)
User.create!(
  name: "Alan",
  email: "alan@university.presence",
  password: "123456",
  password_confirmation: "123456",
  admin: true
)

course = Course.create(name:"Análise e Desenvolvimento de Sistemas", periods: 3)
Course.create(name:"Direito", periods: 10)
Course.create(name:"Enfermagem", periods: 10)

class_room = ClassRoom.create!(name: "Turma A", course: course)

Student.create!([
  { name: "Bruno Rezende Esteves", ra: "900007-1", class_room: class_room },
  { name: "Igor Lacerda Vasconcelos", ra: "900025-1", class_room: class_room }
])

puts "Seed concluido com sucesso!"
