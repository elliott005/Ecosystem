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

    local assetHills = love.graphics.newImage("assets/Hills.png")
    quadHills = love.graphics.newQuad(16, 32, 16, 16, assetHills)
    local assetGrass = love.graphics.newImage("assets/Grass.png")
    quadGrass = love.graphics.newQuad(0, 5 * 16, 16, 16, assetGrass)
    quadGrassFood = love.graphics.newQuad(6 * 16, 5 * 16, 16, 16, assetGrass)
    local assetWater = love.graphics.newImage("assets/Water+.png")
    local quadWater = love.graphics.newQuad(16, 16, 16, 16, assetWater)

    mapCanvas = love.graphics.newCanvas(width * tilesize, height * tilesize)

    love.graphics.setCanvas(mapCanvas)
    
    --love.graphics.draw(assetWater, 0, 0)

    local noiseOffsets = {
        vector(1, 1) * love.math.random() * 1000,
       --[[  vector(1, 1) * love.math.random() * 1000,
        vector(1, 1) * love.math.random() * 1000,
        vector(1, 1) * love.math.random() * 1000, ]]
    }
    local zoom = 0.05
    for x=1, width do
        for y=1, height do
            local noiseValue = 0
            for i, noise in ipairs(noiseOffsets) do
                noiseValue = noiseValue + love.math.noise((x + noise.x) * zoom, (y + noise.y) * zoom)
            end
            noiseValue = noiseValue / #noiseOffsets
            --[[ love.graphics.setColor(noiseValue, noiseValue, noiseValue)
            love.graphics.rectangle("fill", x * tilesize, y * tilesize, 16, 16) ]]
            local circle = {position=vector((x - 1) * tilesize, (y - 1) * tilesize), radius=tilesize}
            local groupX = math.ceil(x / groupSize)
            local groupY = math.ceil(y / groupSize)
            if noiseValue < 0.1 then
                table.insert(walls[groupX][groupY], circle)
                love.graphics.draw(assetHills, quadHills, (x - 1) * tilesize, (y - 1) * tilesize)
            elseif noiseValue < 0.8 then
                love.graphics.draw(assetGrass, quadGrass, (x - 1) * tilesize, (y - 1) * tilesize)
                if love.math.random() < 0.05 then
                    table.insert(grass[groupX][groupY], circle)
                    love.graphics.draw(assetGrass, quadGrassFood, (x - 1) * tilesize, (y - 1) * tilesize)
                end
            else
                table.insert(water[groupX][groupY], circle)
                love.graphics.draw(assetWater, quadWater, (x - 1) * tilesize, (y - 1) * tilesize)
            end
        end
    end

    love.graphics.setCanvas()
end