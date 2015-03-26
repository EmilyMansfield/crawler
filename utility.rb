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
      nil
    end
  end
end
