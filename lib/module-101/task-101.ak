pub type Rolplayer{
  Policeman
  Citizen
  Thief
  Animal 
}

type Character {
    rol: Rolplayer,
    age: Int,
    name: String
}

test m101_task_trace_Rolplayer_Citizen() {
  let player1 = Character{rol: Citizen, age: 30, name: @"estADA"}
  let is_citizen = player1.rol == Citizen
  trace @"Testing m101_task is_citizen:"
  is_citizen?
}

test m101_task_trace_Rolplayer_Not_Citizen() {
  let player1 = Character{rol: Policeman, age: 30, name: @"estADA"}
  let is_citizen = player1.rol == Citizen
  trace @"Testing m101_task is_not_citizen:"
  !is_citizen?
}