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
common to both modes.

##Commands##

###Explore###

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