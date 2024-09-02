walls = {}

function loadMap(mapName)
    gameMap = sti(mapName)

    world:addCollisionClass("BlocksLOS")
    loadLayer("Cliffs", "BlocksLOS")

    world:addCollisionClass("Water")
    loadLayer("Water")

    world:addCollisionClass("Grass", {ignores=animalTypes}) -- ignores=animalTypes
    loadLayer("Grass")
end

function loadLayer(name, collisionClass)
    collisionClass = collisionClass or name
    if gameMap.layers[name] then
        for y, row in pairs(gameMap.layers[name].data) do
            for x, tile in pairs(row) do
                for i, collision in ipairs(tile.objectGroup.objects) do
                    spawnWall((x - 1) * gameMap.tilewidth + collision.x, (y - 1) * gameMap.tileheight + collision.y, collision.width, collision.height)
                    walls[#walls]:setCollisionClass(collisionClass)
                end
            end
        end
    end
end

function spawnWall(x, y, width, height)
    local wall = world:newRectangleCollider(x, y, width, height)
    wall:setType("static")
    table.insert(walls, wall)
end