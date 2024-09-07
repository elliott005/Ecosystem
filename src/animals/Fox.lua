Fox = Class{}

world:addCollisionClass("Fox")

function Fox:init(x, y)
    self:include(AnimalBase)
    AnimalBase.init(self, x, y)

    self.size = 32
    self.hungerMax = 35.0
    self.thirstMax = 25.0
    self.hungerThreshold = 25.0
    self.thirstThreshold = 20.0
    self.searchRadius = 128
    self.targetReachedRadius = 25
    self.wanderRadius = 96
    self.speed = 32
    self.animalType = "Fox"
    self.prey = {"Chicken"}

    self:setCollision("Fox", 1/4)
    self:setVariables()

    self.spritesheet = spritesheets[self.animalType]
    local grid = anim8.newGrid(32, 32, self.spritesheet:getWidth(), self.spritesheet:getHeight())
    self.animation = "idle"
    self.animations = {
        ["idle"] = anim8.newAnimation(grid("1-14", 2), 0.1),
        ["walk"] = anim8.newAnimation(grid("1-8", 3), 0.15),
        ["sit"] = anim8.newAnimation(grid("1-7", 7), 0.2),
        ["getUp"] = anim8.newAnimation(grid("7-1", 7), 0.2),
    }
end