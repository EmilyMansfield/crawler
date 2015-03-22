require_relative 'commands'

class Mode
  @@max_history = 100
  attr_reader :regexp, :modifier_regexp, :commands, :history
  # modifiers should be a single regexp containing the modifiers
  # such as from or at
  def initialize(commands, modifiers = nil)
    @commands = commands
    # Shamelessly long one-liner
    @regexp = Regexp.new("(#{(0...@commands.length).each_with_object("") { |i, s| s << @commands[i][0].source << '|' }.chop})\\s+?(.*)")
    @modifier_regexp = (modifiers ? Regexp.new("(#{modifiers.source})\\s+(.*)") : nil)
    @history = []
  end

  def parse(player, input, &block)
    # Check for history usage via ! syntax and replace input if needed
    # !n    nth command in history. First command is 1, not 0
    # !-n   nth command before this one in history
    # !!    shorthand for !-1
    /!(?:(-){0,1}(\d+))|(?:(!))/ =~ input
    if $1 || $3
      input = @history[-($2 || 1).to_i] # Need parens as nil.to_i == 0
    elsif $2
      input = @history[$2.to_i-1]
    end
    @history << input
    @history.shift if @history.length > @@max_history
    if /history/ =~ input
      @history.each_with_index { |x, i| puts "#{i+1}\t#{x}" }
      return :invalid # System commands shouldn't advance time either
    end

    input = input.downcase.split(@regexp).delete_if { |x| x.empty? }
    input[-1] = input[-1].split(@modifier_regexp).delete_if { |x| x.empty? }
    input.flatten!
    input.map! { |x| x.strip }

    if @commands.none? do |command|
        if command[0] =~ input[0]
          if !input[1] && command.length >= 4
            puts "#{input[0].capitalize} #{command.last || 'what'}?"
            return :invalid
          end
          self.method(command[1]).call(*[player, *eval(command[2] || '')])
          true # Hacky but whatever
        end
      end
      puts "Invalid command."
      return :invalid
    end
    yield if block_given?
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
$mode_explore = Mode.new([
  [/search/, :parse_search, 'input[1]'],
  [/take/, :parse_take, 'input[1..3]', 'what'],
  [/wield|equip|wear/, :parse_equip, 'input[1]', 'what'],
  [/examine|inspect/, :parse_examine, 'input[1]', 'what'],
  [/go/, :parse_go, 'input[1]', 'where'],
  [/look/, :parse_look, 'input[1..2]'],
  [/quit|exit/, :parse_exit]],
  /from|at/
)
$mode_combat = Mode.new([
  [/attack|strike/, :parse_strike],
  [/wield|equip|wear/, :parse_equip, 'input[1]', 'what'],
  [/examine|inspect/, :parse_examine, 'input[1]', 'what']]
)

def parse_explore(player, input)
  $mode_explore.parse(player, input)
end

def parse_combat(player, input)
  outcome = $mode_combat.parse(player, input) do
    enemy = $areas[player.area].creatures.find { |x| x[0] == player.enemy }[1]
    if enemy.hp <= 0
      :enemy_slain
    elsif player.hp <= 0
      :player_slain
    end
  end
end