#!/usr/bin/ruby
require_relative 'modes'
require_relative 'entities'
require_relative 'saving'
require_relative 'utility'

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
    outcome = $mode_combat.parse($player, gets.chomp!)
    redo if outcome == :invalid || outcome == :change_mode
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
      # Enemy will flee if the player is sufficiently strong
      # Move to a random area like the player? Currently just delete
      if $player.strength >= 2*enemy.strength && rand(4) == 0
        puts "The #{enemy.name} flees."
        # No experience :(
        $areas[$player.area].creatures.delete_at(enemy_index)
        $mode = :explore
        next
      end
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