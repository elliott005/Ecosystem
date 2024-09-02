Player = Class{}

function Player:init(x, y)
    self.camera = Camera(x, y)
    self.selectedAnimal = false

    self.gameSpeedFactor = 1
end

function Player:update(dt)
    if self.selectedAnimal then
        if not lume.find(animals, self.selectedAnimal) then
            self.selectedAnimal = false
        else
            self.camera:lookAt(self.selectedAnimal.position.x, self.selectedAnimal.position.y)
        end
    end
end

function Player:draw()
    if self.selectedAnimal then
        if self.selectedAnimal.activity == "moving" or self.selectedAnimal.activity == "wandering" then
            love.graphics.setColor(1, 0, 0)
            love.graphics.line(self.selectedAnimal.position.x, self.selectedAnimal.position.y, self.selectedAnimal.target.x, self.selectedAnimal.target.y)
            love.graphics.setColor(1, 1, 1)
        end
    end
end

function Player:drawHud()
    love.graphics.setColor(1, 0, 0)
    if self.selectedAnimal then
        love.graphics.print("activity: " .. self.selectedAnimal.activity, 0, 0, 0, 2, 2)
        love.graphics.print("targetGoal: " .. self.selectedAnimal.targetGoal, 0, 32, 0, 2, 2)
        love.graphics.print("id: " .. self.selectedAnimal.id, 0, 64, 0, 2, 2)
        love.graphics.print("thirst: " .. lume.round(self.selectedAnimal.thirst, 0.1), 0, 96, 0, 2, 2)
        love.graphics.print("hunger: " .. lume.round(self.selectedAnimal.hunger, 0.1), 0, 128, 0, 2, 2)
        love.graphics.print("reproductive urge: " .. lume.round(self.selectedAnimal.reproductiveUrge, 0.1), 0, 160, 0, 2, 2)
        love.graphics.print("fleeing: " .. tostring(self.selectedAnimal.fleeing), 0, 192, 0, 2, 2)
        love.graphics.print("species: " .. self.selectedAnimal.animalType, 0, 224, 0, 2, 2)
        love.graphics.print("sex: " .. self.selectedAnimal.sex, 0, 256, 0, 2, 2)
        if debugMode then
            love.graphics.print("debug message: " .. self.selectedAnimal.debugMessage, 0, 288, 0, 2, 2)
        end
    end

    width, height, flags = love.window.getMode()
    love.graphics.print("FPS: " .. love.timer.getFPS(), width - 300, 0, 0, 2, 2)
    love.graphics.print("game speed: " .. (self.gameSpeedFactor * 100) .. "%", width - 300, 32, 0, 2, 2)
    love.graphics.print("animal count: " .. #animals, width - 300, 64, 0, 2, 2)
    love.graphics.setColor(1, 1, 1)
end

function Player:keypressed(key, scancode, isrepeat)
    if key == "left" then
        self.gameSpeedFactor = math.max(self.gameSpeedFactor - 0.1, 0)
    elseif key == "right" then
        self.gameSpeedFactor = self.gameSpeedFactor + 0.1
    end
end

function Player:mousemoved(x, y, dx, dy, istouch)
    if love.mouse.isDown(1) and not self.selectedAnimal then
        self.camera:move(-dx / self.camera.scale, -dy / self.camera.scale)
    end
end

function Player:wheelmoved(p_x, p_y)
    local y = lume.clamp(p_y, -5, 5)
    self.camera:zoom(lume.remap(y, -5, 5, 0.2, 1.8))
    self.camera.scale = lume.clamp(self.camera.scale, 0.1, 10)
end

function Player:mousepressed(x, y, button, istouch, presses)
    if button == 2 then
        worldX, worldY = self.camera:worldCoords(x, y)
        -- Modify windfield to detect circles with queries
        local colliders = world:queryCircleArea(worldX, worldY, 10, animalTypes)
        local closest = false
        local closestDistance = false
        for i, collider in ipairs(colliders) do
            local dist = lume.distance(collider:getX(), collider:getY(), worldX, worldY)
            if (not closest) or dist < closestDistance then
                closestDistance = dist
                closest = collider:getObject()
            end
        end
        self.selectedAnimal = closest
    elseif button == 3 then
        debugMode = not debugMode
    end
end