Chicken = Class{}

--world:addCollisionClass("Chicken", {ignores={"Fox", "Chicken", "BlocksLOS", "Water", "Grass"}})

function Chicken:init(x, y, genes, baby)
    self:include(AnimalBase)
    AnimalBase.init(self, x, y, baby)

    self.size = 32
    self.spriteScale = 0.5
    self.hungerMax = 25.0
    self.thirstMax = 20.0
    self.repruductiveUrgeMax = 10.0
    self.hungerThreshold = 20.0
    self.thirstThreshold = 17.0
    self.searchRadius = 128
    self.targetReachedRadius = 20
    self.wanderRadius = 96
    self.speed = 20
    self.animalType = "Chicken"
    self.prey = {"Grass"}
    self.predators = {"Fox", "Cat"}

    --self:setCollision("Chicken", 1/5)
    self:setVariables(genes)

    self.offsetX = -8
    self.offsetY = -8

    self.spritesheet = spritesheets[self.animalType]

    local grid = anim8.newGrid(32, 32, self.spritesheet:getWidth(), self.spritesheet:getHeight())
    self.animation = "idle"
    self.animations = {
        ["idle"] = anim8.newAnimation(grid(1, 4), 0.1),
        ["walk"] = anim8.newAnimation(grid("1-4", 8), 0.2),
        ["sit"] = anim8.newAnimation(grid("1-3", 4), 0.3),
        ["getUp"] = anim8.newAnimation(grid("3-1", 4), 0.3),
    }
end