Player = Class{}

function Player:init(x, y)
    self.camera = Camera(x, y)
    self.selectedAnimal = false
    self.selectedAnimalGroup = vector(0, 0)

    self.gameSpeedFactor = 1

    x, y, flags = love.window.getMode()
    self.buttons = {
        {x=0, y=y-50, width=75, height=50, text="KILL", color={1, 1, 0}, animal=true, func=self.killSelectedAnimal},
        {x=75, y=y-50, width=100, height=50, text="HEAL", color={1, 1, 0}, animal=true, func=self.healSelectedAnimal},
        {x=x-100, y=y-50, width=100, height=50, text="QUIT", color={1, 1, 1}, animal=false, func=self.quitGame},
    }

    self.showAverageGenes = false

    self.graphSize = 100
end

function Player:update(dt)
    if self.selectedAnimal then
        self.camera:lookAt(self.selectedAnimal.position.x, self.selectedAnimal.position.y)
    end
end

function Player:draw()
    if self.selectedAnimal then
        if self.selectedAnimal.activity == "moving" or self.selectedAnimal.activity == "wandering" then
            love.graphics.setColor(1, 0, 0)
            love.graphics.line(self.selectedAnimal.position.x, self.selectedAnimal.position.y, self.selectedAnimal.target.x, self.selectedAnimal.target.y)
            if self.selectedAnimal.targetSteps then
                love.graphics.setColor(0, 1, 0)
                for i, step in ipairs(self.selectedAnimal.targetSteps) do
                    love.graphics.line(self.selectedAnimal.position.x, self.selectedAnimal.position.y, step.x, step.y)
                end
            end
            love.graphics.setColor(1, 1, 1)
        end
    end
    if self.showAverageGenes then
        love.graphics.setColor(1, 0, 0)
        for i, v in ipairs(self.graphAnimalTypes) do
            love.graphics.print(v, (i - 1) * self.graphSize, -self.graphSize)
        end
        for i, v in ipairs(self.graphGeneNames) do
            love.graphics.print(v .. ":", -self.graphSize, i * self.graphSize - self.graphSize / 2)
        end
        love.graphics.print("Population:", -self.graphSize, -self.graphSize / 2)
        fpsGraph.drawGraphs(self.graphs)
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
        love.graphics.print("group: " .. tostring(self.selectedAnimal.group), 0, 288, 0, 2, 2)
        if debugMode then
            love.graphics.print("debug message: " .. self.selectedAnimal.debugMessage, 0, 320, 0, 2, 2)
        end
    end

    width, height, flags = love.window.getMode()
    love.graphics.print("FPS: " .. love.timer.getFPS(), width - 300, 0, 0, 2, 2)
    love.graphics.print("game speed: " .. (self.gameSpeedFactor * 100) .. "%", width - 300, 32, 0, 2, 2)
    local animalCount = 0
    for x, column in ipairs(animals) do
        for y, group in ipairs(column) do
            animalCount = animalCount + #group
        end
    end
    love.graphics.print("animal count: " .. animalCount, width - 300, 64, 0, 2, 2)

    for i, button in ipairs(self.buttons) do
        if not (not self.selectedAnimal and button.animal) then
            love.graphics.setColor(button.color)
            love.graphics.rectangle("line", button.x, button.y, button.width, button.height)
            love.graphics.print(button.text, button.x, button.y, 0, 2, 2)
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function Player:keypressed(key, scancode, isrepeat)
    if key == "left" then
        self.gameSpeedFactor = math.max(self.gameSpeedFactor - 0.1, 0)
    elseif key == "right" then
        self.gameSpeedFactor = self.gameSpeedFactor + 0.1
    elseif key == "up" then
        self.gameSpeedFactor = self.gameSpeedFactor + 1
    elseif key == "down" then
        self.gameSpeedFactor = math.max(self.gameSpeedFactor - 1, 0)
    elseif key == "space" then
        self.showAverageGenes = not self.showAverageGenes
        if self.showAverageGenes then
            self:calculateGenesGraphs()
            self.selectedAnimal = false
        end
    elseif key == "escape" then
        love.event.quit()
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
    if button == 1 then
        for i, button in ipairs(self.buttons) do
            if not (not self.selectedAnimal and button.animal) then
                if pointIsInsideRect(x, y, button.x, button.y, button.width, button.height) then
                    button.func(self)
                    break
                end
            end
        end
    elseif button == 2 then
        worldX, worldY = self.camera:worldCoords(x, y)
        -- Modify windfield to detect circles with queries
        local colliders = queryCircle(vector(worldX, worldY), 10, animals)
        local closest = false
        local closestDistance = false
        for i, collider in ipairs(colliders) do
            local dist = lume.distance(collider.position.x, collider.position.y, worldX, worldY)
            if (not closest) or dist < closestDistance then
                closestDistance = dist
                closest = collider
            end
        end
        self.selectedAnimal = closest
    elseif button == 3 then
        debugMode = not debugMode
    end
end

function Player:killSelectedAnimal()
    self.selectedAnimal:die()
end
function Player:healSelectedAnimal()
    self.selectedAnimal:heal()
end
function Player:quitGame()
    love.event.quit()
end

function Player:calculateGenesGraphs()
    self.graphs = {}
    self.graphAnimalTypes = {}
    self.graphGeneNames = {}
    local createdGeneNames = false
    local y = 0
    local i = 1
    local len = 0
    for animalType, animalGroup in pairs(averageGenesOverTime) do
        table.insert(self.graphs, fpsGraph.createGraph(y * self.graphSize, -self.graphSize, self.graphSize, self.graphSize, 1))
        len = len + 1
        for i, v in ipairs(animalPopulationOverTime[animalType]) do
            fpsGraph.updateGraph(self.graphs[#self.graphs], v, "", 1)
        end
        self.graphAnimalTypes[y + 1] = animalType
        local createdGraph = false
        for time, genes in ipairs(animalGroup) do
            local x = 1
            for k, gene in pairs(genes) do
                if not createdGraph then
                    table.insert(self.graphs, fpsGraph.createGraph(y * self.graphSize, (x - 1) * self.graphSize, self.graphSize, self.graphSize, 1))
                end
                if not createdGeneNames then
                    table.insert(self.graphGeneNames, k)
                end
                fpsGraph.updateGraph(self.graphs[len + x + y * lume.count(genes)], gene * 10, "", 1)
                x = x + 1
            end
            createdGeneNames = true
            createdGraph = true
        end
        y = y + 1
    end
end

function pointIsInsideRect(pointX, pointY, x, y, w, h)
    return x < pointX and pointX < x + w and y < pointY and pointY < y + h
end