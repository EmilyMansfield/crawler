require_relative 'commands'

class Mode
  attr_reader :regexp, :commands
  def initialize(*commands)
    @commands = commands
    # Shamelessly long one-liner
    @regexp = Regexp.new("(#{(0...@commands.length).each_with_object("") { |i, s| s << @commands[i][0].source << '|' }.chop})\\s+?(.*)")
  end
end
# Each array entry is a new command, with a regexp to match
# the command against, a symbol for the function that the
# command should call, an optional string containing the
# arguments, and an optional string containing the interrogative
# of the error message if the arguments are not specified but
# should be. This string should be present if the arguments are
# compulsory, and should be absent otherwise. Would probably be
# easier with objects instead of arrays, but ah well. TODO?
$mode_explore = Mode.new(
  [/search/, :parse_search, 'input[1]'],
  [/take/, :parse_take, 'input[1..3]', 'what'],
  [/wield|equip|wear/, :parse_equip, 'input[1]', 'what'],
  [/examine|inspect/, :parse_examine, 'input[1]', 'what'],
  [/go/, :parse_go, 'input[1]', 'where'],
  [/look/, :parse_look],
  [/quit|exit/, :parse_exit]
)
$mode_combat = Mode.new(
  [/attack|strike/, :parse_strike],
  [/wield|equip|wear/, :parse_equip, 'input[1]', 'what'],
  [/examine|inspect/, :parse_examine, 'input[1]', 'what']
)

def parse_explore(player, input)
  # Can't figure out the single regex with no internet so I'm cheating and
  # splitting it up. Besides, it works well enough
  input = input.downcase.split($mode_explore.regexp).delete_if { |x| x.empty? }
  input[-1] = input[-1].split(/\s+(from)\s+(.*)/).delete_if { |x| x.empty? }
  input.flatten!
  area = $areas[player.area]

  if $mode_explore.commands.none? do |command|
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
  input = input.downcase.split($mode_combat.regexp).delete_if { |x| x.empty? }
  enemy = $areas[player.area].creatures.find { |x| x[0] == player.enemy }[1]

  outcome = nil

  if $mode_combat.commands.none? do |command|
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