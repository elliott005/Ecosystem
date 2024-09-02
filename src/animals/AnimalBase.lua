AnimalBase = Class{}

spritesheets = {
    ["Fox"] = love.graphics.newImage("assets/Fox Sprite Sheet.png"),
    ["Cat"] = love.graphics.newImage("assets/Cat Sprite Sheet.png"),
    ["Chicken"] = love.graphics.newImage("assets/chicken.png")
}

function AnimalBase:init(x, y)
    self.position = vector(x, y)

    -- variables to be modified inside of subclass
    self.size = 32
    self.spriteScale = 1
    self.hungerMax = 20.0
    self.thirstMax = 20.0
    self.reproductiveUrgeMax = 30
    self.thirstThreshold = 15.0
    self.hungerThreshold = 10.0
    self.searchRadius = 128
    self.targetReachedRadius = 20
    self.wanderRadius = 96
    self.speed = 32
    self.animalType = "none"
    self.prey = {}
    self.predators = {}
    self.sprintSpeed = 45
    self.maxBabies = 3
    

    self.id = #animals + 1

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
        checkIfCloser = Timer.new()
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
        self.activities[self.activity](self)
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
        
        if profiling and self.id == 1 then
            prof.push("status update")
        end
        self:updateStatus(dt)
        if profiling and self.id == 1 then
            prof.pop("status update")
        end
    end
end

function AnimalBase:draw()
    if self.dead then
        love.graphics.setColor(0.9, 0.2, 0.2)
    end
    local pos = (self.position + vector(self.offsetX, self.offsetY))
    self.animations[self.animation]:draw(self.spritesheet, pos.x, pos.y, 0, self.spriteScale, self.spriteScale)
    if debugMode and not self.dead then
        --[[ if self.debugSpritesheet then
            love.graphics.draw(self.debugSpritesheet, (self.position + vector(self.offsetX, self.offsetY)):unpack())
        else
            love.graphics.draw(self.spritesheet, (self.position + vector(self.offsetX, self.offsetY)):unpack())
        end ]]
        love.graphics.setColor(1, 1, 1, 0.5)
        if self.activity == "moving" or self.activity == "wandering" then
            if #self.targetSteps > 0 then
                love.graphics.line(self.collider:getX(), self.collider:getY(), self.targetSteps[1]:unpack())
            else
                love.graphics.line(self.collider:getX(), self.collider:getY(), self.target:unpack())
            end
        end
        love.graphics.circle("fill", self.collider:getX(), self.collider:getY(), self.targetReachedRadius)
        love.graphics.setColor(0.5, 0.5, 1, 0.5)
        love.graphics.circle("fill", self.position.x, self.position.y, self.searchRadius)
    end
    love.graphics.setColor(1, 1, 1)
end

function AnimalBase:setCollision(collisionClass, sizeMultiplier)
    self.collider = world:newCircleCollider(self.position.x + self.size / 2, self.position.y + self.size / 2, self.size * sizeMultiplier)
    self.collider:setFixedRotation(true)
    self.collider:setCollisionClass(collisionClass)
    self.collider:setObject(self)
    self.collider:setLinearVelocity(0, 0)
end

function AnimalBase:setVariables()
    self.offsetX = -self.size / 2
    self.offsetY = -self.size / 1.4

    self.sex = lume.randomchoice({"male", "female"})

    self.hunger = self.hungerMax + lume.random(-2, 2)
    self.thirst = self.thirstMax + lume.random(-2, 2)
    self.reproductiveUrge = self.reproductiveUrgeMax + lume.random(-5, 5)
end

function AnimalBase:updateStatus(dt)
    self.position.x = self.collider:getX()
    self.position.y = self.collider:getY()

    self.hunger = self.hunger - dt
    self.thirst = self.thirst - dt
    self.reproductiveUrge = self.reproductiveUrge - dt
    -- print(self.thirst)

    if self.thirst < 0.0 or self.hunger < 0.0 then
        self.dead = true
        self.collider:setLinearVelocity(0, 0)
        self.timers.death:after(1, self.die, self)
    end

    if self.reproductiveUrge < 0.0 then
        local closest = self:searchForMate()
        if closest and not (self.targetGoal == "reproduction" and self.target == vector(closest:getX(), closest:getY())) then
            self.target = vector(closest:getX(), closest:getY())
            self.activity = "moving"
            self.targetGoal = "reproduction"
        end
    end
end

function AnimalBase:die()
    self.dead = true
    self.collider:destroy()
    table.remove(animals, self.id)
    for i, animal in ipairs(animals) do
        animal.id = i
    end
end

function AnimalBase:idle()
    self.animation = "idle"
    if self.thirst < self.thirstThreshold then
        local closest = self:searchForWater()
        if closest then
            self.target = vector(closest:getX(), closest:getY())
            self.activity = "moving"
            self.targetGoal = "drinking"
        else
            self.activity = "wandering"
            for _=1, 10 do
                self.target = vector(self.position.x + lume.random(-self.wanderRadius, self.wanderRadius), self.position.y + lume.random(-self.wanderRadius, self.wanderRadius))
                if #world:queryLine(self.position.x, self.position.y, self.target.x, self.target.y, {"All", except={self.animalType}}) < 1 then
                    break
                else
                    self.target = self.position
                end
            end
        end
    elseif self.hunger < self.hungerThreshold then
        local closest = self:searchForFood()
        if closest then
            self.target = vector(closest:getX(), closest:getY())
            self.activity = "moving"
            self.targetGoal = "eating"
        else
            self.activity = "wandering"
            for _=1, 10 do
                self.target = vector(self.position.x + lume.random(-self.wanderRadius, self.wanderRadius), self.position.y + lume.random(-self.wanderRadius, self.wanderRadius))
                if #world:queryLine(self.position.x, self.position.y, self.target.x, self.target.y, {"All", except={self.animalType}}) < 1 then
                    break
                else
                    self.target = self.position
                end
            end
        end
    end
    self:searchForPredators()
end

function AnimalBase:move(switchTo)
    self.animation = "walk"
    
    if not self.checkedPath then
        self.checkedPath = true
        self.timers.checkPath:after(self.checkPathAfter, function(self)
            --[[ if profiling and self.id == 1 then
                prof.push("check path")
            end ]]
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
    self.collider:setLinearVelocity((dir * speed):unpack())
    self.animations[self.animation].flippedH = dir.x < 0.0
    if self.position == self.target or self.position:dist(self.target) <= self.targetReachedRadius then
        self.activity = switchTo
        self.collider:setLinearVelocity(0, 0)
    elseif self.targetGoal == "drinking" then
        if not self.checkedIfCloser then
            self.checkedIfCloser = true
            self.timers.checkIfCloser:after(self.checkIfCloserAfter, function(self)
                self.checkedIfCloser = false
                if self.targetGoal ~= "drinking" then return end
                local closestWater = self:searchForWater()
                if closestWater then
                    if not (closestWater:getX() == self.target.x and closestWater:getY() == self.target.y) then
                        self.target = vector(closestWater:getX(), closestWater:getY())
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
                local closestFood = self:searchForFood()
                if closestFood then
                    if not (closestFood:getX() == self.target.x and closestFood:getY() == self.target.y) then
                        self.target = vector(closestFood:getX(), closestFood:getY())
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
    local except = {}
    local colliders = {}
    if self.targetGoal == "drinking" then
        table.insert(except, "Water")
    elseif self.targetGoal == "eating" then
        except = lume.concat(except, self.prey)
    elseif self.targetGoal == "reproduction" then
        table.insert(except, self.animalType)
    end
    if #self.targetSteps > 0 and (self.targetSteps[1] == self.position or self.position:dist(self.targetSteps[1]) < self.targetReachedRadius) then
        self.targetSteps[1] = nil
    else
        if #self.targetSteps > 0 then
            colliders = world:queryLine(self.position.x, self.position.y, self.targetSteps[1].x, self.targetSteps[1].y, {"All", except=except})
        elseif self.position ~= self.target then
            colliders = world:queryLine(self.position.x, self.position.y, self.target.x, self.target.y, {"All", except=except})
        end
    end
    if #colliders > 0 and colliders[1] ~= self.collider then
        local angle = 15
        local targetStep
        while math.abs(angle) <= 180 do
            if #self.targetSteps > 0 then
                targetStep = (self.targetSteps[1] - self.position):rotated(angle)
            else
                targetStep = (self.target - self.position):rotated(angle)
            end
            colliders = world:queryLine(self.position.x, self.position.y, targetStep.x, targetStep.y, {"All", except=except})
            if #colliders < 1 then
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

function AnimalBase:moving()
    self:move(self.targetGoal)
end

function AnimalBase:wandering()
    self:move("idle")
    if self.thirst < self.thirstThreshold then
        local closest = self:searchForWater()
        if closest then
            self.target = vector(closest:getX(), closest:getY())
            self.activity = "moving"
            self.targetGoal = "drinking"
        end
    elseif self.hunger < self.hungerThreshold then
        local closest = self:searchForFood()
        if closest then
            self.target = vector(closest:getX(), closest:getY())
            self.activity = "moving"
            self.targetGoal = "eating"
        end
    end
    self:searchForPredators()
end

function AnimalBase:drinking()
    if self.animation ~= "sit" and self.animation ~= "getUp" then
        self.collider:setLinearVelocity(0, 0)
        self.animation = "sit"
        self.timers.drink:after(self.animations[self.animation].totalDuration, self.getUpAfterDrink, self)
    end
end

function AnimalBase:getUpAfterDrink()
    if self.dead then return end
    self.thirst = self.thirstMax
    self.collider:setLinearVelocity(0, 0)
    self.animation = "getUp"
    self.timers.drink:after(self.animations[self.animation].totalDuration, self.stopDrinking, self)
end

function AnimalBase:stopDrinking()
    self.collider:setLinearVelocity(0, 0)
    self.activity = "idle"
    self.targetGoal = "none"
end

function AnimalBase:eating()
    local closest = self:searchForFood()
    if closest then
        local obj = closest:getObject()
        if obj then
            obj:die()
        --[[ else
            closest:destroy() ]]
        end
        self.hunger = self.hungerMax
    end
    self.activity = "idle"
    self.targetGoal = "none"
end

function AnimalBase:reproduction()
    local closest = self:searchForMate()
    if closest then
        local obj = closest:getObject()
        obj.reproductiveUrge = obj.reproductiveUrge
    end
    for _=1, lume.random(1, self.maxBabies) do
        for _=1, 5 do
            local pos = self.position + vector(32, 0):rotated(lume.random(0, 360))
            if #world:queryCircleArea(pos.x, pos.y, 16, {"All"}) < 1 then
                table.insert(animals, animalClasses[self.animalType](pos.x, pos.y))
                break
            end
        end
    end
    self.reproductiveUrge = self.reproductiveUrgeMax
    self.activity = "idle"
    self.targetGoal = "none"
end

function AnimalBase:searchForWater()
    local waterColliders = world:queryCircleArea(self.position.x, self.position.y, self.searchRadius, {"Water"})
    local closest = false
    local closestDistance = 0
    for i, waterCollider in ipairs(waterColliders) do
        local waterX = waterCollider:getX()
        local waterY = waterCollider:getY()
        if (not closest) or lume.distance(self.position.x, self.position.y, waterX, waterY) < closestDistance then
            if #world:queryLine(self.position.x, self.position.y, waterX, waterY, {"BlocksLOS"}) < 1 then
                closest = waterCollider
                closestDistance = lume.distance(self.position.x, self.position.y, waterX, waterY)
            end
        end
    end
    return closest
end

function AnimalBase:searchForFood()
    local foodColliders = world:queryCircleArea(self.position.x, self.position.y, self.searchRadius, self.prey)
    local closest = false
    local closestDistance = 0
    for i, foodCollider in ipairs(foodColliders) do
        local foodX = foodCollider:getX()
        local foodY = foodCollider:getY()
        if (not closest) or lume.distance(self.position.x, self.position.y, foodX, foodY) < closestDistance then
            if #world:queryLine(self.position.x, self.position.y, foodX, foodY, {"BlocksLOS"}) < 1 then
                closest = foodCollider
                closestDistance = lume.distance(self.position.x, self.position.y, foodX, foodY)
            end
        end
    end
    return closest
end

function AnimalBase:searchForMate()
    local mateColliders = world:queryCircleArea(self.position.x, self.position.y, self.searchRadius, {self.animalType})
    local closest = false
    local closestDistance = 0
    for i, mateCollider in ipairs(mateColliders) do
        local mateX = mateCollider:getX()
        local mateY = mateCollider:getY()
        local mateObj = mateCollider:getObject()
        if mateObj.reproductiveUrge < mateObj.reproductiveUrgeThreshold and mateObj.sex ~= self.sex and ((not closest) or lume.distance(self.position.x, self.position.y, mateX, mateY) < closestDistance) then
            if #world:queryLine(self.position.x, self.position.y, mateX, mateY, {"BlocksLOS"}) < 1 then
                closest = mateCollider
                closestDistance = lume.distance(self.position.x, self.position.y, mateX, mateY)
            end
        end
    end
    return closest
end

function AnimalBase:searchForPredators()
    if #self.predators < 1 then return end

    local colliders = world:queryCircleArea(self.position.x, self.position.y, self.searchRadius, self.predators)

    if #colliders > 0 then
        local predator = colliders[lume.round(lume.random(1, #colliders))]
        if self.fleeingFrom then
            local colliderIndex = lume.find(colliders, self.fleeingFrom)
            if colliderIndex then
                predator = colliders[colliderIndex]
            else
                self.fleeingFrom = false
            end
        end
        self.fleeingFrom = predator
        local predatorObj = predator:getObject()
        if #world:queryLine(self.position.x, self.position.y, predatorObj.position.x, predatorObj.position.y, {"BlocksLOS"}) < 1 then
            local target = (self.position - predatorObj.position):normalized() * (self.searchRadius - self.position:dist(predatorObj.position) + 32) + self.position
            local collidersInPath = world:queryLine(self.position.x, self.position.y, target.x, target.y, {"All", except={"Grass"}})
            if #collidersInPath < 1 or (#collidersInPath < 2 and collidersInPath[1] == self.collider) then
                self.target = target
                self.fleeing = true
                self.activity = "moving"
                self.targetGoal = "idle"
            else
                local angle = 15
                while math.abs(angle) <= 90 do
                    target = (self.position - predatorObj.position):rotated(angle):normalized() * (self.searchRadius - self.position:dist(predatorObj.position) + 32) + self.position
                    collidersInPath = world:queryLine(self.position.x, self.position.y, target.x, target.y, {"All", except={"Grass"}})
                    if #collidersInPath < 1 or (#collidersInPath < 2 and collidersInPath[1] == self.collider) then
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
            self.collider:setLinearVelocity(0, 0)
            self.activity = "idle"
            self.targetGoal = "none"
        end
        self.fleeing = false
        self.fleeingFrom = false
    end
end