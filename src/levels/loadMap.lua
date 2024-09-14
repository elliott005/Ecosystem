walls = {}
water = {}
grass = {}

function loadMap(mapName)
    gameMap = sti(mapName)

    groupSize = 5
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