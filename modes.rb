require_relative 'commands'

# Each array entry is a new command, with a regexp to match
# the command against, a symbol for the function that the
# command should call, an optional string containing the
# arguments, and an optional string containing the interrogative
# of the error message if the arguments are not specified but
# should be. This string should be present if the arguments are
# compulsory, and should be absent otherwise. Would probably be
# easier with objects instead of arrays, but ah well. TODO?
EXPLORE_COMMANDS = [
  [/search/, :parse_search, 'input[1]'],
  [/take/, :parse_take, 'input[1..3]', 'what'],
  [/wield|equip|wear/, :parse_equip, 'input[1]', 'what'],
  [/examine|inspect/, :parse_examine, 'input[1]', 'what'],
  [/go/, :parse_go, 'input[1]', 'where'],
  [/look/, :parse_look, 'input[1..2]'],
  [/quit|exit/, :parse_exit]
]
COMBAT_COMMANDS = [
  [/attack|strike/, :parse_strike],
  [/wield|equip|wear/, :parse_equip, 'input[1]', 'what'],
  [/examine|inspect/, :parse_examine, 'input[1]', 'what']
]
EXPLORE_REGEX = /(search|take|wield|equip|wear|examine|inspect|go|look|quit|exit)\s+?(.*)/
COMBAT_REGEX = /(attack|strike|wield|equip|wear|examine|inspect)\s+?(.*)/

def parse_explore(player, input)
  # Can't figure out the single regex with no internet so I'm cheating and
  # splitting it up. Besides, it works well enough
  input = input.downcase.split(EXPLORE_REGEX).delete_if { |x| x.empty? }
  input[-1] = input[-1].split(/(from|at)\s+/).delete_if { |x| x.empty? }
  input.flatten!
  input.map! { |x| x.strip }
  area = $areas[player.area]

  if EXPLORE_COMMANDS.none? do |command|
      if command[0] =~ input[0]
        if !input[1] && command.length >= 4
          puts "#{input[0].capitalize} #{command.last || 'what'}?"
          break
        end
        self.method(command[1]).call(*[player, *eval(command[2] || '')])
        true # Hacky but whatever
      end
    end
    puts "Invalid command."
  end
end

def parse_combat(player, input)
  input = input.downcase.split(COMBAT_REGEX).delete_if { |x| x.empty? }
  enemy = $areas[player.area].creatures.find { |x| x[0] == player.enemy }[1]

  outcome = nil

  if COMBAT_COMMANDS.none? do |command|
      if command[0] =~ input[0]
        if !input[1] && command.length >= 4
          puts "#{input[0].capitalize} #{command.last || 'what'}?"
          outcome = :invalid
          break
        end
        self.method(command[1]).call(*[player, *eval(command[2] || '')])
        true
      end
    end
    puts "Invalid command."
    outcome = :invalid
  end

  if enemy.hp <= 0
    outcome = :enemy_slain
  elsif player.hp <= 0
    outcome = :player_slain
  end

  return outcome
end