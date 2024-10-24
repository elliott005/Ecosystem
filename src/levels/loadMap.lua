walls = {}
water = {}
grass = {}
groupSize = 5

function loadMap(mapName)
    gameMap = sti(mapName)

    for x=1,math.ceil(gameMap.width / groupSize) do
        walls[x] = {}
        water[x] = {}
        grass[x] = {}
        for y=1,math.ceil(gameMap.height / groupSize) do
            walls[x][y] = {}
            water[x][y] = {}
            grass[x][y] = {}
        end
    end

    --world:addCollisionClass("BlocksLOS", {ignores={"Fox", "Chicken", "BlocksLOS", "Water", "Grass"}})
    loadLayer("Cliffs", walls)

    --world:addCollisionClass("Water", {ignores={"Fox", "Chicken", "BlocksLOS", "Water", "Grass"}})
    loadLayer("Water", water)

    --world:addCollisionClass("Grass", {ignores=animalTypes}) -- ignores=animalTypes
    loadLayer("Grass", grass)
end

function loadLayer(name, group)
    if gameMap.layers[name] then
        for y, row in pairs(gameMap.layers[name].data) do
            for x, tile in pairs(row) do
                for i, collision in ipairs(tile.objectGroup.objects) do
                    local circle = {position=vector((x - 1) * gameMap.tilewidth + collision.x, (y - 1) * gameMap.tileheight + collision.y), radius=collision.width}
                    table.insert(group[math.ceil(x / groupSize)][math.ceil(y / groupSize)], circle)
                end
            end
        end
    end
end

function createMap(width, height, tilesize)
    for x=1,math.ceil(width / groupSize) do
        walls[x] = {}
        water[x] = {}
        grass[x] = {}
        for y=1,math.ceil(height / groupSize) do
            walls[x][y] = {}
            water[x][y] = {}
            grass[x][y] = {}
        end
    end

    local assetHills = love.graphics.newImage("assets/Hills1Tile.png")
    --quadHills = love.graphics.newQuad(16, 32, 16, 16, assetHills)
    local assetGrass = love.graphics.newImage("assets/Grass1Tile.png")
    --quadGrass = love.graphics.newQuad(0, 5 * 16, 16, 16, assetGrass)
    local assetWater = love.graphics.newImage("assets/Water+1Tile.png")
    --local quadWater = love.graphics.newQuad(16, 16, 16, 16, assetWater)

    mapCanvas = love.graphics.newCanvas(width * tilesize, height * tilesize)

    love.graphics.setCanvas(mapCanvas)
    
    love.graphics.draw(assetWater, 0, 0)

    --[[ noiseOffset = vector(1, 1) * (lume.random(1, 1000) / 10)
    for x=1, width do
        for y=1, height do
            local noiseValue = love.math.noise(x + noiseOffset.x, y + noiseOffset.y)
            local circle = {position=vector((x - 1) * tilesize, (y - 1) * tilesize), radius=tilesize}
            local groupX = math.ceil(x / groupSize)
            local groupY = math.ceil(y / groupSize)
            if noiseValue < 0.65 then
                table.insert(grass[groupX][groupY], circle)
                love.graphics.draw(assetGrass, x * tilesize, y * tilesize)
            elseif noiseValue < 0.9 then
                table.insert(water[groupX][groupY], circle)
                love.graphics.draw(assetWater, x * tilesize, y * tilesize)
            else
                table.insert(walls[groupX][groupY], circle)
                love.graphics.draw(assetHills, x * tilesize, y * tilesize)
            end
        end
    end ]]

    love.graphics.setCanvas()
end