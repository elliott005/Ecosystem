function love.load()
    debugMode = false
    profiling = false
    love.window.setMode(800, 600)

    if profiling then
        PROF_CAPTURE = true
        prof = require("jprof")
    end
        
    require "src/startup/gameStart"
    gameStart()
end

function love.quit()
    if profiling then
        prof.write("prof.mpack")
    end
end