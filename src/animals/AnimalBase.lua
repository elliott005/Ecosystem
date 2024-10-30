AnimalBase = Class{}

spritesheets = {
    ["Fox"] = love.graphics.newImage("assets/Fox Sprite Sheet.png"),
    ["Cat"] = love.graphics.newImage("assets/Cat Sprite Sheet.png"),
    ["Chicken"] = love.graphics.newImage("assets/chicken.png")
}

function AnimalBase:init(x, y, baby)
    self.position = vector(x, y)
    self.baby = false
    if baby then
        self.baby = baby
    end

    -- variables to be modified inside of subclass
    self.size = 32
    self.spriteScale = 1
    self.hungerMax = 20.0
    self.thirstMax = 20.0
    self.reproductiveUrgeMax = 20.0
    self.thirstThreshold = 15.0
    self.hungerThreshold = 10.0
    self.searchRadius = 128
    self.targetReachedRadius = 16
    self.wanderRadius = 96
    self.speed = 32
    self.animalType = "none"
    self.prey = {}
    self.predators = {}
    self.sprintSpeed = 45
    self.maxBabies = 5
    self.gestationTime = 7
    self.growUpTime = 5

    self.mutationAmount = 0.5

    self.group = vector(math.ceil(self.position.x / tilesize / groupSize), math.ceil(self.position.y / tilesize / groupSize))
    self.id = #animals[self.group.x][self.group.y] + 1

    self.reproductiveUrgeThreshold = self.reproductiveUrgeMax / 4

    self.activity = "idle"
    self.activities = {
        ["idle"] = self.idle,
        ["moving"] = self.moving,
        ["wandering"] = self.wandering,
        ["drinking"] = self.drinking,
        ["eating"] = self.eating,
        ["reproduction"] = self.reproduction
    }
    
    self.dead = false
    self.fleeing = false
    self.fleeingFrom = false
    
    self.target = vector(0, 0)
    self.targetSteps = {}
    self.targetGoal = "none"

    self.timers = {
        death = Timer.new(),
        drink = Timer.new(),
        checkPath = Timer.new(),
        checkIfCloser = Timer.new(),
        gestation = Timer.new(),
        baby = Timer.new()
    }

    self.checkedPath = false
    self.checkPathAfter = 0.3
    self.checkedIfCloser = false
    self.checkIfCloserAfter = 0.2

    self.debugMessage = ""
end

function AnimalBase:update(dt)

    for k, timer in pairs(self.timers) do
        timer:update(dt)
    end

    if not self.dead then

        if profiling and self.id == 1 then
            prof.push("activity update")
        end
        self.activities[self.activity](self, dt)
        if profiling and self.id == 1 then
            prof.pop("activity update")
        end

        if profiling and self.id == 1 then
            prof.push("animation update")
        end
        self.animations[self.animation]:update(dt)
        if profiling and self.id == 1 then
            prof.pop("animation update")
        end
        
        self:updateStatus(dt)
    end
end

function AnimalBase:draw()
    if self.dead then
        love.graphics.setColor(0.9, 0.2, 0.2)
    end
    local pos = (self.position + vector(self.offsetX, self.offsetY))
    local scale = self.spriteScale
    if self.baby then
        scale = scale / 2
    end
    self.animations[self.animation]:draw(self.spritesheet, pos.x, pos.y, 0, scale, scale)
    if debugMode and not self.dead then
        --[[ if self.debugSpritesheet then
            love.graphics.draw(self.debugSpritesheet, (self.position + vector(self.offsetX, self.offsetY)):unpack())
        else
            love.graphics.draw(self.spritesheet, (self.position + vector(self.offsetX, self.offsetY)):unpack())
        end ]]
        love.graphics.setColor(1, 1, 1, 0.2)
        if self.activity == "moving" or self.activity == "wandering" then
            if #self.targetSteps > 0 then
                love.graphics.line(self.position.x, self.position.y, self.targetSteps[1]:unpack())
            else
                love.graphics.line(self.position.x, self.position.y, self.target:unpack())
            end
        end
        love.graphics.circle("fill", self.position.x, self.position.y, self.targetReachedRadius)
        love.graphics.setColor(0.5, 0.5, 1, 0.2)
        love.graphics.circle("fill", self.position.x, self.position.y, self.searchRadius)
    end
    love.graphics.setColor(1, 1, 1)
end

--[[ function AnimalBase:setCollision(collisionClass, sizeMultiplier)
    self.collider = world:newCircleCollider(self.position.x + self.size / 2, self.position.y + self.size / 2, self.size * sizeMultiplier)
    self.collider:setFixedRotation(true)
    self.collider:setCollisionClass(collisionClass)
    self.collider:setObject(self)
    self.collider:setLinearVelocity(0, 0)
end ]]

function AnimalBase:setVariables(genes)
    if genes then
        self.genes = genes
    else
        self.genes = {
            speedMultiplier = math.max(0, 1 + lume.random(-self.mutationAmount, self.mutationAmount)),
            attractiveness = math.max(0, 0.5 + lume.random(-self.mutationAmount, self.mutationAmount)),
            gestationMultiplier = math.max(0, 1 + lume.random(-self.mutationAmount, self.mutationAmount))
        }
    end

    if self.baby then
        self.timers.baby:after(self.growUpTime / self.genes.gestationMultiplier, function(self)
            self.baby = false
        end, self)
    end

    self.offsetX = -self.size / 2
    self.offsetY = -self.size / 1.4

    self.sex = lume.randomchoice({"male", "female"})

    self.hunger = self.hungerMax + lume.random(-2, 2)
    self.thirst = self.thirstMax + lume.random(-2, 2)
    self.reproductiveUrge = self.reproductiveUrgeMax + lume.random(-5, 5)

    self.speed = self.speed * self.genes.speedMultiplier
    self.gestationTime = self.gestationTime * self.genes.gestationMultiplier
end

function AnimalBase:updateStatus(dt)
    self:updateGroup()

    self.hunger = self.hunger - dt / self.genes.speedMultiplier
    self.thirst = self.thirst - dt / self.genes.speedMultiplier
    if not self.baby then
        self.reproductiveUrge = self.reproductiveUrge - dt
    end
    -- print(self.thirst)

    if self.thirst < 0.0 or self.hunger < 0.0 then
        self.dead = true
        self.timers.death:after(1, self.die, self)
    end

    if self.reproductiveUrge < 0.0 then
        local closest = self:searchForMate()
        if closest and not (self.targetGoal == "reproduction" and self.target == closest.position) then
            self.target = closest.position
            self.activity = "moving"
            self.targetGoal = "reproduction"
        end
    end
end

function AnimalBase:updateGroup()
    local newGroup = vector(math.max(1, math.ceil(self.position.x / tilesize / groupSize)), math.max(1, math.ceil(self.position.y / tilesize / groupSize)))
    if newGroup ~= self.group then
        lume.remove(animals[self.group.x][self.group.y], self)
        self.group = newGroup
        table.insert(animals[self.group.x][self.group.y], self)
    end
    self.id = #animals[self.group.x][self.group.y]
end

function AnimalBase:die()
    self.dead = true
    self:updateGroup()
    if player.selectedAnimal == self then
        player.selectedAnimal = false
    end
    lume.remove(animals[self.group.x][self.group.y], self)
end

function AnimalBase:heal()
    self.thirst = self.thirstMax
    self.hunger = self.hungerMax
    self.reproductiveUrge = self.reproductiveUrgeMax
end

function AnimalBase:idle()
    self.animation = "idle"
    if self.thirst < self.thirstThreshold and not (self.hunger < self.hungerThreshold and self.hunger < self.thirst) then
        local closest = self:searchForWater()
        if closest then
            self.target = closest.position
            self.activity = "moving"
            self.targetGoal = "drinking"
        else
            self.activity = "wandering"
            for _=1, 10 do
                self.target = vector(self.position.x + lume.random(-self.wanderRadius, self.wanderRadius), self.position.y + lume.random(-self.wanderRadius, self.wanderRadius))
                self.target.x = lume.clamp(self.target.x, tilesize, (mapWidth - 1) * tilesize)
                self.target.y = lume.clamp(self.target.y, tilesize, (mapHeight - 1) * tilesize)
                if not queryLine(self.position, self.target, walls) then
                    break
                else
                    self.target = self.position
                end
            end
        end
    elseif self.hunger < self.hungerThreshold then
        local closest = self:searchForFood()
        if closest then
            self.target = closest.position
            self.activity = "moving"
            self.targetGoal = "eating"
        else
            self.activity = "wandering"
            for _=1, 10 do
                self.target = vector(self.position.x + lume.random(-self.wanderRadius, self.wanderRadius), self.position.y + lume.random(-self.wanderRadius, self.wanderRadius))
                self.target.x = lume.clamp(self.target.x, tilesize, (mapWidth - 1) * tilesize)
                self.target.y = lume.clamp(self.target.y, tilesize, (mapHeight - 1) * tilesize)
                if not queryLine(self.position, self.target, walls) then
                    break
                else
                    self.target = self.position
                end
            end
        end
    end
    self:searchForPredators()
end

function AnimalBase:move(dt, switchTo)
    self.animation = "walk"
    
    if not self.checkedPath then
        self.checkedPath = true
        self.timers.checkPath:after(self.checkPathAfter, function(self)
            --[[ if profiling and self.id == 1 then
                prof.push("check path")
            end ]]
            if self.dead then return end
            self.checkedPath = false
            self:checkPath()
            --[[ if profiling and self.id == 1 then
                prof.pop("check path")
            end ]]
        end, self)
    end
    local dir
    
    if #self.targetSteps > 0 then
        dir = (self.targetSteps[1] - self.position):normalized()
    else
        dir = (self.target - self.position):normalized()
    end

    local speed = self.speed
    if self.fleeing then
        speed = self.sprintSpeed
    end
    if self.baby then
        speed = speed / 2
    end
    self.position = self.position + dir * speed * dt
    self.position.x = lume.clamp(self.position.x, tilesize, (mapWidth - 1) * tilesize)
    self.position.y = lume.clamp(self.position.y, tilesize, (mapHeight - 1) * tilesize)
    self.animations[self.animation].flippedH = dir.x < 0.0
    if self.position == self.target or self.position:dist(self.target) <= self.targetReachedRadius then
        self.activity = switchTo
    elseif self.targetGoal == "drinking" then
        if not self.checkedIfCloser then
            self.checkedIfCloser = true
            self.timers.checkIfCloser:after(self.checkIfCloserAfter, function(self)
                self.checkedIfCloser = false
                if self.targetGoal ~= "drinking" then return end
                if self.dead then return end
                local closestWater = self:searchForWater()
                if closestWater then
                    if closestWater.position ~= self.target then
                        self.target = closestWater.position
                    end
                else
                    self.activity = "idle"
                    self.targetGoal = "none"
                end
            end, self)
        end
    elseif self.targetGoal == "eating" then
        if not self.checkedIfCloser then
            self.checkedIfCloser = true
            self.timers.checkIfCloser:after(self.checkIfCloserAfter, function(self)
                self.checkedIfCloser = false
                if self.targetGoal ~= "eating" then return end
                if self.dead then return end
                local closestFood = self:searchForFood()
                if closestFood then
                    if closestFood.position ~= self.target then
                        self.target = closestFood.position
                    end
                else
                    self.activity = "idle"
                    self.targetGoal = "none"
                end
            end, self)
        end
    end

    self:searchForPredators()
end

function AnimalBase:checkPath()
    local collisionWith = {water, walls}
    local colliding = false
    if self.targetGoal == "drinking" then
        lume.remove(collisionWith, water)
    end
    if #self.targetSteps > 0 and (self.targetSteps[1] == self.position or self.position:dist(self.targetSteps[1]) < self.targetReachedRadius) then
        self.targetSteps[1] = nil
    else
        if #self.targetSteps > 0 then
            collidingTarget = queryLine(self.position, self.target, unpack(collisionWith))
            if collidingTarget then
                colliding = queryLine(self.position, self.targetSteps[1], unpack(collisionWith))
            else
                self.targetSteps = {}
            end
        elseif self.position ~= self.target then
            colliding = queryLine(self.position, self.target, unpack(collisionWith))
        end
    end
    if colliding then
        local angle = 15
        local targetStep
        while math.abs(angle) <= 180 do
            if #self.targetSteps > 0 then
                targetStep = (self.targetSteps[1] - self.position):rotated(angle)
            else
                targetStep = (self.target - self.position):rotated(angle)
            end
            colliding = queryLine(self.position, self.position + targetStep, unpack(collisionWith))
            if not colliding then
                break
            end
            targetStep = vector(0, 0)
            if angle > 0 then
                angle = -angle
            else
                angle = -angle * 2
            end
        end
        self.targetSteps[1] = self.position + targetStep
    end
end

function AnimalBase:moving(dt)
    self:move(dt, self.targetGoal)
end

function AnimalBase:wandering(dt)
    self:move(dt, "idle")
    if self.thirst < self.thirstThreshold and not (self.hunger < self.hungerThreshold and self.hunger < self.thirst) then
        local closest = self:searchForWater()
        if closest then
            self.target = closest.position
            self.activity = "moving"
            self.targetGoal = "drinking"
        end
    elseif self.hunger < self.hungerThreshold then
        local closest = self:searchForFood()
        if closest then
            self.target = closest.position
            self.activity = "moving"
            self.targetGoal = "eating"
        end
    end
    self:searchForPredators()
end

function AnimalBase:drinking()
    if self.animation ~= "sit" and self.animation ~= "getUp" then
        self.animation = "sit"
        self.timers.drink:after(self.animations[self.animation].totalDuration, self.getUpAfterDrink, self)
    end
end

function AnimalBase:getUpAfterDrink()
    if self.dead then return end
    self.thirst = self.thirstMax
    self.animation = "getUp"
    self.timers.drink:after(self.animations[self.animation].totalDuration, self.stopDrinking, self)
end

function AnimalBase:stopDrinking()
    if self.dead then return end
    self.activity = "idle"
    self.targetGoal = "none"
end

function AnimalBase:eating()
    local closest = self:searchForFood()
    if closest then
        if closest.animalType then
            closest:die()
        else
            grassGroup = grass[math.max(1, math.ceil((closest.position.x / tilesize + 1) / groupSize))][math.max(1, math.ceil(closest.position.y / tilesize / groupSize))]
            for i, grassTile in ipairs(grassGroup) do
                if grassTile.position:dist(closest.position) < tilesize / 2 then
                    lume.remove(grassGroup, grassTile)
                    spawnGrass()
                    break
                end
            end
        end
        self.hunger = self.hungerMax
    end
    self.activity = "idle"
    self.targetGoal = "none"
end

function AnimalBase:reproduction()
    local closest = self:searchForMate()
    if closest and self.genes.attractiveness > math.random() then

        local genes = {}
        for k, v in pairs(self.genes) do
            if math.random() >= 0.5 then
                genes[k] = math.max(0, v + lume.random(-self.mutationAmount, self.mutationAmount))
            end
        end
        genes["attractiveness"] = self.genes.attractiveness
        for k, v in pairs(closest.genes) do
            if not genes[k] then
                genes[k] = math.max(0, v + lume.random(-self.mutationAmount, self.mutationAmount))
            end
        end

        closest.reproductiveUrge = closest.reproductiveUrgeMax
        closest.activity = "idle"
        closest.targetGoal = "none"

        if self.sex == "female" then
            self.timers.gestation:after(self.gestationTime, self.giveBirth, self)
            self.childGenes = genes
        else
            closest.timers.gestation:after(closest.gestationTime, closest.giveBirth, closest)
            closest.childGenes = genes
        end
    end
    self.reproductiveUrge = self.reproductiveUrgeMax
    self.activity = "idle"
    self.targetGoal = "none"
end

function AnimalBase:giveBirth()
    if self.dead then return end
    for _=1, lume.random(1, self.maxBabies) do
        for _=1, 5 do
            local pos = self.position + vector(32, 0):rotated(lume.random(0, 360))
            pos.x = lume.clamp(pos.x, tilesize, (mapWidth - 1) * tilesize)
            pos.y = lume.clamp(pos.y, tilesize, (mapHeight - 1) * tilesize)
            if #queryCircle(pos, 16, walls, water) < 1 then
                local group = vector(math.ceil(pos.x / tilesize / groupSize), math.ceil(pos.y / tilesize / groupSize))
                table.insert(animals[group.x][group.y], animalClasses[self.animalType](pos.x, pos.y, self.childGenes, true))
                break
            end
        end
    end
end

function AnimalBase:searchForWater()
    local waterColliders = queryCircle(self.position, self.searchRadius, water)
    local closest = false
    local closestDistance = 0
    for i, waterCollider in ipairs(waterColliders) do
        if (not closest) or lume.distance(self.position.x, self.position.y, waterCollider.position.x, waterCollider.position.y) < closestDistance then
            if not queryLine(self.position, waterCollider.position, walls) then
                closest = waterCollider
                closestDistance = self.position:dist(waterCollider.position)
            end
        end
    end
    return closest
end

function AnimalBase:searchForFood()
    local foodColliders = {}
    local closest = false
    local closestDistance = 0
    if lume.find(self.prey, "Grass") then
        foodColliders = queryCircle(self.position, self.searchRadius, grass)
        for i, foodCollider in ipairs(foodColliders) do
            if (not closest) or self.position:dist(foodCollider.position) < closestDistance then
                if not queryLine(self.position, foodCollider.position, walls) then
                    closest = foodCollider
                    closestDistance = self.position:dist(foodCollider.position)
                end
            end
        end
    end
    if self.prey == {"Grass"} then
        return closest
    end
    foodColliders = queryCircle(self.position, self.searchRadius, animals)
    for i, foodCollider in ipairs(foodColliders) do
        if lume.find(self.prey, foodCollider.animalType) and ((not closest) or self.position:dist(foodCollider.position) < closestDistance) then
            if not queryLine(self.position, foodCollider.position, walls) then
                closest = foodCollider
                closestDistance = self.position:dist(foodCollider.position)
            end
        end
    end
    return closest
end

function AnimalBase:searchForMate()
    local mates = queryCircle(self.position, self.searchRadius, animals)
    local closest = false
    local closestDistance = 0
    for i, mate in ipairs(mates) do
        if self.animalType == mate.animalType and mate.reproductiveUrge < mate.reproductiveUrgeThreshold and mate.sex ~= self.sex and ((not closest) or self.position:dist(mate.position) < closestDistance) then
            if not queryLine(self.position, mate.position, walls) then
                closest = mate
                closestDistance = self.position:dist(mate.position)
            end
        end
    end
    return closest
end

function AnimalBase:searchForPredators()
    if #self.predators < 1 then return end

    local closeAnimals = queryCircle(self.position, self.searchRadius, animals)
    local predators = {}
    for i, animal in ipairs(closeAnimals) do
        if lume.find(self.predators, animal.animalType) then
            table.insert(predators, animal)
        end
    end

    if #predators > 0 then
        local predator = predators[lume.round(lume.random(1, #predators))]
        if self.fleeingFrom then
            local colliderIndex = lume.find(predators, self.fleeingFrom)
            if colliderIndex then
                predator = predators[colliderIndex]
            else
                self.fleeingFrom = false
            end
        end
        self.fleeingFrom = predator
        if not queryLine(self.position, predator.position, walls) then
            local target = (self.position - predator.position):normalized() * (self.searchRadius - self.position:dist(predator.position) + 32) + self.position
            local collidersInPath = queryLine(self.position, target, walls)
            if not collidersInPath then
                self.target = target
                self.fleeing = true
                self.activity = "moving"
                self.targetGoal = "idle"
            else
                local angle = 15
                while math.abs(angle) <= 90 do
                    target = (self.position - predator.position):rotated(angle):normalized() * (self.searchRadius - self.position:dist(predator.position) + 32) + self.position
                    collidersInPath = queryLine(self.position, target, walls)
                    if not collidersInPath then
                        self.target = target
                        self.fleeing = true
                        self.activity = "moving"
                        self.targetGoal = "idle"
                        break
                    end
                    if angle < 0 then
                        angle = -angle * 2
                    else
                        angle = -angle
                    end
                end
            end
        end
    else
        if self.fleeing then
            self.activity = "idle"
            self.targetGoal = "none"
        end
        self.fleeing = false
        self.fleeingFrom = false
    end
end