#!/usr/bin/ruby
require 'json'

require_relative 'modes'
require_relative 'entities'
require_relative 'saving'

# Prints the contents of the array using the format string fmt_str but adds
# natural english connectives. fmt_str must use self as the interpolation
# variable, and should be escaped accordingly
def format_list(array, fmt_str)
  str = ""
  array.each.with_index do |x, i|
    if array.length == 1
      x.instance_eval("str << \"#{fmt_str}\"")
    elsif i == array.length - 1
      x.instance_eval("str << \"and #{fmt_str}\"")
    else
      x.instance_eval("str << \"#{fmt_str}, \"")
    end
  end
  str
end

# Convert the command target into an actual object
def convert_command_target(player, target, containers_only = false)
  case target
  when 'here', 'the area', 'my surroundings'
    $areas[player.area]
  when 'me', 'myself', 'my bag'
    player
  else
    return $areas[player.area] if containers_only
    # Target type priority is
    # - Creature in the area
    # - Item in the player's surroundings
    # - Item in the player's current container
    # If still the target is not found, return nil
    if (creature = $areas[player.area].creatures.find { |x| x[1].name.downcase == target })
      creature[1]
    elsif (item = $areas[player.area].items.find { |x| $items[x[0]].name.downcase == target  })
      $items[item[0]]
    elsif (item = player.items.find { |x| $items[x[0]].name.downcase == target })
      $items[item[0]]
    else
      $areas[player.area]
    end
  end
end

# Load game data and player
load_data
puts "What's your name?"
$player = load(gets.chomp)

# explore - Movement and environment interaction
# combat - Fighting an enemy
$mode = :explore

$displayed_description = false
loop do
  if $player.hp <= 0
    puts "You die."
    exit
  end

  case $mode
  when :explore
    unless $displayed_description
      puts '-'*40
      parse_look($player)
      $areas[$player.area].modified = true
      $displayed_description = true
    end
    unless $areas[$player.area].creatures.empty?
      if (index = $areas[$player.area].creatures.index { |x| x[1].hostile })
        # Get the ID of enemy
        $player.enemy = $areas[$player.area].creatures[index][0]
        puts "The #{$creatures[$player.enemy].name} attacks!"
        $mode = :combat
        next
      end
    end
    print "> "
    redo if $mode_explore.parse($player, gets.chomp!) == :invalid
  when :combat
    print "~ "
    redo if $mode_combat.parse($player, gets.chomp!) == :invalid
    enemy_index = $areas[$player.area].creatures.index { |x| x[0] == $player.enemy }
    enemy = $areas[$player.area].creatures[enemy_index][1]
    # Enemy dies
    if enemy.hp <= 0
      puts "The #{enemy.name} dies."
      # Grant experience
      puts "You gain #{enemy.xp} experience."
      $player.increase_xp(enemy.xp)
      # Remove the dead enemy
      $areas[$player.area].creatures.delete_at(enemy_index)
      $mode = :explore
      next
    # Combat still ongoing
    else
      # Enemy attacks the player so deal damage
      damage = enemy.strike($player)
      if damage
        puts "The #{enemy.name} strikes you for #{damage} damage."
      else
        puts "You evade the attack."
      end
    end
  end
end