#CRawler#

A small text-based dungeon crawler written in Ruby.

CRawler is designed to be

- Extensible. All game data is supplied via JSON files, with the program
  only handling the game engine.
- Lightweight. If it can run Ruby, it can run CRawler. After all, there aren't
  even any graphics!
- Short. If the documentation is longer than the source code, we're doing
  something right.
- Natural. No 'choose option 1 to take the dagger', CRawler uses natural
  language processing to understand simple commands, such as 'take dagger from
  my bag'.
^
        ----------------------------------------
        You are in a meadow surrounded by trees.
        There is a Cave to the North here.
        > search
        There is a Gold Coin, and a Dagger here.
        > take dagger
        You take the Dagger.
        > take gold coin from here
        You take the Gold Coin.
        > search my bag
        There is a Dagger, and a Gold Coin here.
        > wield dagger
        You wield the Dagger
        > examine gold coin
        You examine the Gold Coin.
        > look
        You are in a meadow surrounded by trees.
        There is a Cave to the North here.
        > go north
        You head North through the Cave.
        ----------------------------------------
        You are in a small cave.
        There is a Opening to the South here.
        There is a Rat here.
        The Rat attacks!
        ~ strike rat
        The Rat evades your attack.
        The Rat strikes you for 1 damage.
        ~

##Gameplay##

CRawler has two modes - `explore`, and `combat`, distinguished by their prompts
`> ` and `~ ` respectively. In the `explore` mode you can move around and
interact with the environment, and in `combat` you are restricted in your
location and instead must stand and fight whatever has deemed you it's lunch. If
you overcome your foe or manage to escape then you'll end up back in the
`explore` mode, ready to fight another day.

The commands available in each mode differ, although some such as `wield` are
common to both modes, in which case their behaviour is largely identical.

###Exploring###

The default and most commonly used mode in CRawler is the `explore` mode. When
in this mode you can move around the game world which is split into sections
called areas. When you first enter an area a description of the area and its
immediately visible contents will be shown.

        ----------------------------------------
        You are in a meadow surrounded by trees.
        There is a Cave to the North here.
        > 

You will then be presented with the `explore` prompt which understands a variety
of commands. To `search` the area for items or hidden objects you can use the
`search` command.

        > search
        There is a Gold Coin, and a Dagger here.
        > 

In this case you find a gold coin and a dagger. This is just a notification of
their existence though, you need to `take` the items to be able to use them.

        > take dagger
        You take the Dagger.
        > take gold coin
        You take the Gold Coin.
        > 

`take`-ing an item adds it to your bag, a catch-all term for the various storage
locations you might have on your person. `search`-ing the area will now turn up
nothing, but `search`-ing your bag will reveal the items.

        > search
        There is nothing here.
        > search my bag
        There is a Dagger, and a Gold Coin here.
        > 

To take a closer look at that gold coin, you can `examine` or `inspect` it.

        > examine gold coin
        A golden disk an inch in diameter. It's heavy, and probably worth something.
        > 

Enlightening. That dagger would come in useful in a fight, so it would pay to
`equip` or `wield` it.

        > wield dagger
        You wield the Dagger
        > 

Weapon in hand, you will now do more damage to enemies in combat. Now where were
the exits again? `look`-ing around would help.

        > look
        You are in a meadow surrounded by trees.
        There is a Cave to the North here.
        > 

To move around the world use the `go` command, which requires a cardinal direction
such as `north`. You could also use the shorthand `n` if you're feeling lazy.

        > go north
        You head North through the Cave.
        ----------------------------------------
        You are in a small cave.
        There is a Opening to the South here.
        There is a Rat here.
        The Rat attacks!
        ~ 

The `go` command takes you to a new area, and so a new description is printed.
There's the southern exit we would expect, but also a rat which appears to be
quite hostile. To combat!

###Combat###

The `combat` mode is the second mode in CRawler and is distinguished by its `~`
prompt. In this mode the selection of possible commands is different, notably
`go`, `search`, and `take` from before are absent.

        The Rat attacks!
        ~ 

A swift `strike` with the dagger should do the trick.

        ~ strike
        You strike the Rat for 2 damage.
        The Rat strikes you for 1 damage.
        ~ 

Without a weapon you do a single point of damage when attacking, but with the
dagger this is increased. After that attack the rat fought back, dealing some
damage of its own. Let's take a closer look at that dagger

        ~ examine dagger
        A small blade, probably made of iron. Keep the sharp end away from your body.
        The Rat strikes you for 1 damage.
        ~ 

Interesting information I'm sure, but the rat took advantage of your dithering
and attacked! Most commands in the `combat` mode take up an action, and for
every action you take the enemy gets one too. The main exception to this is if
the command you try to issue fails for some reason

        ~ examine foo
        You can't see a Foo anywhere.
        ~ 

You don't have a foo and there isn't one lying around so this command doesn't
work, and therefore doesn't take up an action. Getting back in the fight,

        ~ strike
        The Rat evades your attack.
        The Rat strikes you for 1 damage.
        ~ 

but the rat dodges your valiant swing! You are not guaranteed an hit with each
`strike`, sometimes your (or your opponent's) attacks will miss. Nevertheless,

        ~ strike
        You strike the Rat for 2 damage.
        The Rat dies.
        > 

and with another attack the rat is slain. Hurrah! Combat is over so its back to
the `explore` mode, shown by the change in prompt.

##Commands##

###`explore` Mode###

####`take <item>`####
You take an object from the environment and put it in your bag.

        > take dagger
        You take the Dagger.

The `take` command accepts the `from` keyword, which changes the container you
are taking the item from.

        > take dagger from here
        You take the Dagger.
        > take gold coin from the area
        You take the Gold Coin.

If the `from` keyword is not given then `take` will assume you are trying to
`take` an item from the active container, which is the area by default but may
be changed by certain commands e.g. `search`.

####`go <direction>`####
The `go` command allows you to move around the map, and requires a cardinal
direction after it. If the path in that direction isn't blocked, you'll go
that way.

        > go north
        > go east
        > go s

You don't have to write out `north` or `west` every time either, you can use the
shorthand directions `n`, `e`, `s`, and `w`.

####`equip <item>`####
The behaviour of the `equip` command depends on the target, which should be an
item in your possession. If the target is a weapon then this command acts like
`wield`, if it is armor then this command acts like `wear`, and if it is just an
item then this command acts like `examine`.

        > equip dagger
        You wield the Dagger.

####`wield <weapon>`####
The `wield` command puts away your current weapon and draws the new one.
If the weapon is not a weapon but another type of item, this command is a
synonym for `equip`.

        > wield dagger
        You wield the Dagger.

####`wear <armor>`####
The `wear` command removes your currently worn armor and puts on the new set.
If the armor is not armor but instead another type of item, this command is a
synonym for `equip`.

        > wear leather armor
        You put on the Leather Armor

####`examine <item>`####
Examines the specified item and displays a short description of it.

        > examine dagger
        A small blade, probably made of iron. Keep the sharp end away from your body.

####`inspect <item>`####
A synonym for `examine`.

####`look`####
The `look` command gives a description of the area around you, and lists the
`doors` and `creatures` nearby. This command is run automatically when you first
enter an area.

        > look
        You are in a meadow surrounded by trees.
        There is a Cave to the North here.

####`search <container>`####
Searches the specified container for items, and lists what you find. If a
container is not given then your immediate vicinity - items that are lying
around and not in barrels or hidden away - is searched instead.

        > search
        There is a Gold Coin, and a Dagger here.
        > search my bag
        There is nothing here.

Note that `search` does not pick up the items, you must use `take` for that.
Also note that `search` changes the active container, so that any `take`
commands issued after a `search` and up to another container change will assume
you are trying to `take` an item from that container.

###`combat` Mode###

####`strike`####
Attack your current foe. `wield`ing a weapon will increase the amount of damage
you do, without a weapon your attacks do `1` damage. You are not guaranteed to
hit, there is a small chance that your enemy will evade the attack. See the
section on combat for more information.

        ~ strike
        The Rat evades your attack.
        The Rat strikes you for 1 damage.
        ~ strike
        You strike the Rat for 2 damage.
        The Rat dies.

####`attack`####
Synonym for `strike`.

####`equip <item>`####
Same behaviour as in the `explore` mode. Takes a combat action if you have the
specified item.

####`wield <weapon>`####
Same behaviour as in the `explore` mode. Takes a combat action if you have the
specified weapon.

####`wear <armor>`####
Same behaviour as in the `explore` mode. Takes a combat action if you have the
specified armor.

####`examine <item>`####
Same behaviour as in the `explore` mode. Takes a combat action if you have the
specified item.

####`inspect <item>`####
A synonym for `examine`.