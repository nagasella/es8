# ES8 - A tiny entity system for PICO-8

ES8 is a 128-lines-of-code ECS framework for [PICO-8](https://www.lexaloffle.com/pico-8.php). It was designed with the goal to be compact, fun and easy to use. Although ECS frameworks are normally targeting performance, ES8 is more about making the process of writing games intuitive and flexible.

## Made with ES8

I used ES8 in my first PICO-8 release, [The Test](https://www.lexaloffle.com/bbs/?tid=150953). More games to come (hopefully) in the future...

## Using ES8 in your PICO-8 project

You can use ES8 by downloading the file `es8.lua` in the same directory as your `.p8` game, and including it like this:

```lua
#include es8.lua
```

Or, you can copy-paste the code in the file directly in the PICO-8 code editor.

## Basic idea

The main building blocks of the framework are the same as any ECS - entities, components and systems:
- Entities can be thought of as the game objects, and are implemented as lua tables
- Components, in this specific framework, are the keys of each game object table
- Systems are objects that process entities that possess certain components (keys)

## Entities

Entities are just lua tables:

```lua
entity = {
    x = 0,
    y = 0,
    vx = 1,
    vy = 1
}
```

The keys `x`, `y`, `vx` and `vy` can all be thought of as components. The entity can be added to `es8` by using:

```lua
es8:addentity(entity)
```

When you do this, the entity will be [registered to each system](#systems) that can process it. You can delete the entity at any moment using:

```lua
es8:delentity(entity)
```

## Systems

Systems implement the logic of the game. Each system takes care of processing entities that own a certain set of keys (components). Here is an example of a system that moves an entity based on its velocity, and draws a sprite on screen for it:

```lua
-- system definition
SysMovement = es8.system({ "x", "y", "vx", "vy" })

-- update logic
function SysMovement:update()
    for e in all(self.entities) do
        e.x += e.vx
        e.y += e.vy
    end
end

-- draw logic
function SysMovement:draw()
    for e in all(self.entities) do
        spr(0, e.x, e.y)
    end
end
```

The system will work on all the entities that have the four listed keys (`x`, `y`, `vx`, `vy`). If an entity has only `x`, `y` and `vx`, it will NOT be processed by this system. 

If a system does not list ANY key, it won't process ANY entity (but it can still execute logic that is not related to entities).

Then, you can integrate the system in a PICO-8 program like this:

```lua
function _init()
    -- add system and give it a name
    es8:addsystem("SysMovement", SysMovement)
    -- run init() for all systems that implement it
    es8:init()

    -- add an entity that will be processed by the system above
    es8:addentity({
        x = 0,
        y = 0,
        vx = 1,
        vy = 1
    })
end

function _update()
    -- run update() for all systems that implement it
    es8:update()
end

function _draw()
    cls(0)
    -- run draw() for all systems that implement it
    es8:draw()
end
```

You can add as many systems as you want. Note that a name has to be assigned to each system when it is added to ES8.

## Systems functions

Each system can implement the following functions (although none is mandatory):
* `init()`: called when `es8:init()` is called, or when there is a [game state change](#game-states)
* `update()`: called when `es8:udpate()` is called
* `draw()`: called when `es8:draw()` is called
* `clear()`: called when `es8:clear()` is called, or when there is a [game state change](#game-states)
* `ask(msg, info)`: allows to handle messages sent from outside the system

`update()` and `draw()` were explained in the previous section. `init()` and `clear()` are used to initialize and clear a system (`es8:clear()` will delete all the entities currently in ES8, and call `clear()` for every system).

The `ask` function is the most interesting and it allows different systems to communicate to one another.  For example, let's say that we have a system that implements the `ask` function as follows:

```lua
function MySystem:ask(msg, info)
    -- first type of message
    if msg == "ResetAllPositions" then
        for e in all(self.entities) do
            e.x = 0
            e.y = 0
        end
    -- second type of message
    elseif msg == "GetEntities" then
        return self.entities
    end
end
```

Then, we can send messages to this system from anywhere else in the program like this:

```lua
es8:ask("MySystem", "ResetAllPositions")
```

Which will reset the position of every entity processed by the system to `(0, 0)`. Or:

```lua
system_entities = es8:ask("MySystem", "GetEntities")
```

To obtain an array that contains all the entites currently processed by the system. Like this, systems can communicate with each other very easily.

## Game states

You can have different game states handled by ES8 for you. Here is an example of program that uses two game states (supposing we have defined the systems `Sys1`, `Sys2`, `Sys3` and `Sys4`):

```lua
function _init()
    -- systems for game state TitleScreen
    es8:addsystem("Sys1", Sys1, "TitleScreen")
    es8:addsystem("Sys2", Sys2, "TitleScreen")
    -- systems for game state GameScreen
    es8:addsystem("Sys3", Sys3, "GameScreen")
    es8:addsystem("Sys4", Sys4, "GameScreen")

    -- set title screen game state as first game state
    -- init() will be ran for Sys1 and Sys2
    es8:setgamestate("TitleScreen")
end

function _update()
    -- update all systems of the current game state
    es8:update()

    -- change game state if button pressed
    if es8.gamestate == "TitleScreen" and btnp(4) then
        es8:setgamestate("GameScreen")
    end
end

function _draw()
    cls(0)
    -- draw everything for the current game state
    es8:draw()
end
```

In the beginning, we set the game state to `TitleScreen`. This will call `init()` for all the systems registerd to the `TitleScreen` game state (in the example above, `Sys1` and `Sys2`). Also, from this moment `es8:update()` and `es8:draw()` will only process those two systems.

Then, when `btnp(4)` is pressed, we change state to `GameScreen` using `es8:setgamestate("GameScreen")`. This will:
- Delete all the entities that were created in the `TitleScreen`
- Call `clear()` on `Sys1` and `Sys2` (if implemented)
- Change the game state to `GameScreen`
- Call `init()` on every system of the `GameScreen` state (in the example above, `Sys3` and `Sys4`)

After that, the game loop will continue running normally, and ES8 will keep running `update()` and `draw()` on all the systems of the `GameScreen` (`Sys3` and `Sys4`). 

You can implement in the same way as many game states as you want. If you want a system to be processed in all game states, you can use:

```lua
es8:addsystem("System", System, "all") -- all = processed in every game state
```

## ES8 information print

The last function to cover is:

```lua
es8:printinfo(x, y, color)
```

This will print on screen, at the coordinates `x` and `y` (and using the PICO-8 color palette index `color` for the text) some information about:
- The memory and CPU usage (from `stat(0)` and `stat(1)` PICO-8 standard functions)
- The name of all the systems in the current game state
- The number of entities processed by each system

It is a handy way to monitor the performance and state of your game for debug purposes! Remember to place it at the end of the `_draw()` function in order to print on top of all the other elements on screen.