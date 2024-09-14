Cat = Class{}

function Cat:init(x, y)
    self:include(AnimalBase)
    AnimalBase.init(self, x, y)

    self.size = 32
    self.hungerMax = 45.0
    self.thirstMax = 35.0
    self.hungerThreshold = 35.0
    self.thirstThreshold = 30.0
    self.searchRadius = 128
    self.targetReachedRadius = 25
    self.wanderRadius = 96
    self.speed = 32
    self.animalType = "Cat"
    self.prey = {"Chicken"}

    self:setVariables()

    self.spritesheet = spritesheets[self.animalType]
    local grid = anim8.newGrid(32, 32, self.spritesheet:getWidth(), self.spritesheet:getHeight())
    self.animation = "idle"
    self.animations = {
        ["idle"] = anim8.newAnimation(grid("1-4", 1), 0.25),
        ["walk"] = anim8.newAnimation(grid("1-8", 5), 0.15),
        ["sit"] = anim8.newAnimation(grid("1-4", 7), 0.25),
        ["getUp"] = anim8.newAnimation(grid("4-1", 7), 0.25),
    }
end