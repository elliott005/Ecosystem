local game = {}

function game:enter()
    require "src/player/Player"

    notTheseAnimals = {"Cat"}

    animalTypes = {}
    for i, v in ipairs(love.filesystem.getDirectoryItems("src/animals")) do
        require("src/animals/" .. v:sub(1, -5))
        table.insert(animalTypes, v:sub(1, -5))
    end
    lume.remove(animalTypes, "AnimalBase")
    for i, v in ipairs(notTheseAnimals) do
        lume.remove(animalTypes, v)
    end

    require "src/levels/loadMap"
    local pathToMap = "Tiled/Exports/base_medium.lua"
    local numAnimals = 30
    loadMap(pathToMap)

    player = Player(0, 0)

    animalClasses = {
        ["Fox"] = Fox,
        ["Cat"] = Cat,
        ["Chicken"] = Chicken
    }
    for i, v in ipairs(notTheseAnimals) do
        animalClasses[v] = nil
    end
    animalClassesProbabilities = {
        ["Fox"] = 2,
        ["Cat"] = 2,
        ["Chicken"] = 4
    }
    for i, v in ipairs(notTheseAnimals) do
        animalClassesProbabilities[v] = nil
    end
    animals = {}
    -- world:update(0.1)
    while #animals < numAnimals do
        local animalType = lume.weightedchoice(animalClassesProbabilities)
        local pos = vector(lume.random(20, gameMap.width * gameMap.tilewidth - 20), lume.random(20, gameMap.height * gameMap.tileheight - 20))
        if #world:queryCircleArea(pos.x, pos.y, 16, {"All"}) < 1 then
            table.insert(animals, animalClasses[animalType](pos.x, pos.y))
        end
    end
    --[[ table.insert(animals, Fox(100, 50))
    table.insert(animals, Fox(150, 200))
    table.insert(animals, Cat(120, 150))
    table.insert(animals, Chicken(20, 20)) ]]

    groups = 2
    currentGroup = 1
    previousDeltaTimes = {}
    for _=1,groups - 1 do
        table.insert(previousDeltaTimes, 0.0)
    end

    frameCount = 0
    FPStotal = 0

    timeBetweenCaptures = 1.0
    captureTimer = Timer.new()
    averageGenesOverTime = {}
    animalPopulationOverTime = {}
    for i, v in ipairs(animalTypes) do
        animalPopulationOverTime[v] = {}
        averageGenesOverTime[v] = {}
    end
    captureGenes()
end

function captureGenes()
    local animalsGenes = {}
    for i, v in ipairs(animalTypes) do
        animalsGenes[v] = {}
    end
    for i, v in ipairs(animals) do
        table.insert(animalsGenes[v.animalType], v.genes)
    end

    local averageGenes = {}
    for animalType, animalGroup in pairs(animalsGenes) do
        averageGenes[animalType] = {}
        table.insert(animalPopulationOverTime[animalType], #animalGroup)
        for i, animalGenes in ipairs(animalGroup) do
            for k, gene in pairs(animalGenes) do
                if averageGenes[animalType][k] then
                    averageGenes[animalType][k] = averageGenes[animalType][k] + gene / #animalGroup
                else
                    averageGenes[animalType][k] = gene / #animalGroup
                end
            end
        end
    end
    for animalType, animalGroup in pairs(averageGenes) do
        table.insert(averageGenesOverTime[animalType], animalGroup)
    end
    captureTimer:after(timeBetweenCaptures, captureGenes)
end

function game:update(dt)
    if profiling then
        prof.push("frame")
    end

    if player.showAverageGenes then return end

    if profiling then
        prof.push("update")
    end

    frameCount = frameCount + 1
    FPStotal = FPStotal + love.timer.getFPS()

    dt = dt * player.gameSpeedFactor

    gameMap:update(dt)
    player:update(dt)

    captureTimer:update(dt)

    if profiling then
        prof.push("animals update")
    end
    cumulativeDeltaTime = dt
    for i, v in ipairs(previousDeltaTimes) do
        cumulativeDeltaTime = cumulativeDeltaTime + v
    end
    local slice = lume.slice(animals, math.floor((currentGroup - 1) * (#animals / groups) + 1), math.floor(currentGroup * (#animals / groups)))
    for i, animal in ipairs(slice) do
        if profiling and i == 1 then
            prof.push("animal 1 update")
        end
        animal:update(cumulativeDeltaTime)
        if profiling and i == 1 then
            prof.pop("animal 1 update")
        end
    end
    if currentGroup < groups then
        currentGroup = currentGroup + 1
    else
        currentGroup = 1
    end
    previousDeltaTimes[#previousDeltaTimes + 1] = dt
    table.remove(previousDeltaTimes, 1)
    if profiling then
        prof.pop("animals update")
    end

    if profiling then
        prof.push("world update")
    end
    world:update(dt)
    if profiling then
        prof.pop("world update")
    end

    if profiling then
        prof.pop("update")
    end
end

function game:draw()
    if profiling then
        prof.push("draw")
    end
    player.camera:attach()

        if not player.showAverageGenes then
            gameMap:drawNoReset()

            if profiling then
                prof.push("draw animals")
            end
            for i, animal in ipairs(animals) do
                animal:draw()
            end
            if profiling then
                prof.pop("draw animals")
            end

            if debugMode then
                world:draw()
            end
        end

        player:draw()

    player.camera:detach()

    if not player.showAverageGenes then
        player:drawHud()
    end

    if profiling then
        prof.pop("draw")
    end
    if profiling then
        prof.pop("frame")
    end
end

function game:keypressed(key, scancode, isrepeat)
    player:keypressed(key, scancode, isrepeat)
end

function game:mousemoved(x, y, dx, dy, istouch)
    player:mousemoved(x, y, dx, dy, istouch)
end

function game:mousepressed(x, y, button, istouch, presses)
    player:mousepressed(x, y, button, istouch, presses)
end

function game:wheelmoved(x, y)
    player:wheelmoved(x, y)
end

function game:quit()
    -- print(lume.round(FPStotal / frameCount, 0.01))
end

return game