#CRawler#

A small text-based dungeon crawler written in Ruby.
CRawler is designed to be

 - Easily extensible. All game data is supplied via JSON files, with the program
   only handling the game engine.
 - Lightweight. If it can run Ruby, it can run CRawler. After all, there aren't
   even any graphics
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

####`take`####
You take an object from the environment and put it in your bag.

        > take dagger
        You take the Dagger.

You can also take an item from a specific container by adding `from <container>`
after the command.

        > take dagger from here
        You take the Dagger.
        > take gold coin from the area
        You take the Gold Coin.

####`go`####
The `go` command allows you to move around the map, and requires a cardinal
direction after it. If the path in that direction isn't blocked, you'll go
that way.

        > go north
        > go east
        > go s

You don't have to write out `north` or `west` every time either, you can use the
shorthand directions `n`, `e`, `s`, and `w`.