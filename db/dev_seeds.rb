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

Event.create!([
  {
    name: "Aula de Algoritmos",
    description: "Aula de Algoritmos",
    event_start: Time.current,
    event_end: Time.current + 1.hour,
    course: course,
    class_rooms: [class_room],
    location: {
      amenity: "Universidade Paranaense UNIPAR",
      road: "Rua São Mateus",
      town: "Francisco Beltrão",
      municipality: "Região Geográfica Imediata de Francisco Beltrão",
      state_district: "Região Geográfica Intermediária de Cascavel",
      state: "Paraná",
      "ISO3166-2-lvl4": "BR-PR",
      region: "Região Sul",
      postcode: "85605-000",
      country: "Brasil",
      country_code: "br"
    },
    latitude: -26.08671845,
    longitude: -48.548038
  }
])

Student.create!([
  { name: "Bruno Rezende Esteves", ra: "900007-1", class_room: class_room },
  { name: "Igor Lacerda Vasconcelos", ra: "900025-1", class_room: class_room }
])

puts "Seed concluido com sucesso!"
