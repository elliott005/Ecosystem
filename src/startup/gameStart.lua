function gameStart()
    math.randomseed(os.time())
    love.graphics.setBackgroundColor(26/255, 26/255, 26/255)

    vector = require "libraries/hump-master/vector"
    Camera = require "libraries/hump-master/camera"
    Signal = require "libraries/hump-master/signal"
    Timer = require "libraries/hump-master/timer"
    Gamestate = require "libraries/hump-master/gamestate"
    Class = require "libraries/hump-master/class"
    flux = require "libraries/flux/flux"
    require "libraries/tesound"
    anim8 = require("libraries/anim8/anim8")
    sti = require("libraries/Simple-Tiled-Implementation/sti")
    windfield = require "libraries/windfield"
    lume = require "libraries/lume"
    fpsGraph = require "libraries/FPSGraph"

    world = windfield.newWorld(0, 0, true)

    game = require "src/gamestates/game"
    Gamestate.registerEvents()
    Gamestate.switch(game)
end