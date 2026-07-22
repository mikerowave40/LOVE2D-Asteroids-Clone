local stateStack = require('stateStack')
local gameState = require('states/gameState')
local infoState = require('states/infoState')

local button = require('classes/button')

local menuState = {}

menuState.init = function(self)

    self.button = button("Play Game", 250, 400, 300, 50)
    self.button.skew = 0.2
    self.button.click = function()
        stateStack.push(gameState())
    end

    self.infobutton = button("Exploration log!", 250, 460, 300, 50)
    self.infobutton.skew = -0.2
    self.infobutton.click = function()
        stateStack.push(infoState())
    end

    self.buttons = {self.button, self.infobutton}

    self.font = love.graphics.newFont('assets/fonts/audiowide.ttf', 36)
    self.btnFont = love.graphics.newFont('assets/fonts/audiowide.ttf', 24)
end

menuState.draw = function(self)
    love.graphics.push('all')

    local thisName = "Asteroids Game"

    love.graphics.setFont(self.font)
    love.graphics.printf(thisName, 0, 50, love.graphics.getWidth(), 'center')

    love.graphics.setFont(self.btnFont)
    for i, v in pairs(self.buttons) do
        v:draw()
    end

    love.graphics.pop()
end

menuState.update = function(self, dt)
    for i, v in pairs(self.buttons) do
        v:update(dt)
    end
end

return function()
    local new = {}
    setmetatable(new, {__index = menuState})

    new:init()

    return new
end