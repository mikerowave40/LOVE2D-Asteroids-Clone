local stateStack = require('stateStack')

local button = require('classes/button')

local menuState = {}

local holyYapSesh = [[Hi all! I've decided to start including what I have learned within my prototypes as a way to document my progress.

This Asteroids clone taught me:

- Game state management and switching between gameplay and menus by using a 'state stack' and pushing/popping states
- How to structure games in Love2D in general and using composition (in relation to in-game entity functionality) to reuse code

Fun fact: This game has no image files. Dear god, it's all polygons and fonts.]]

menuState.init = function(self)
    self.button = button("Back", 25, 600 - 40 - 25, 200, 40)
    self.button.skew = 0.2
    self.button.click = function()
        stateStack.pop()
    end

    self.font = love.graphics.newFont('assets/fonts/audiowide.ttf', 36)
    self.btnFont = love.graphics.newFont('assets/fonts/audiowide.ttf', 24)
    self.blurbFont = love.graphics.newFont('assets/fonts/audiowide.ttf', 16)
end

menuState.draw = function(self)
    love.graphics.push('all')

    love.graphics.setFont(self.font)
    love.graphics.printf("Exploration Log!", 0, 50, love.graphics.getWidth(), 'center')

    love.graphics.setFont(self.btnFont)
    self.button:draw()

    local w = love.graphics.getWidth()
    love.graphics.setFont(self.blurbFont)
    love.graphics.printf(holyYapSesh, w*0.1, 150, love.graphics.getWidth()*0.8, 'center')

    love.graphics.pop()
end

menuState.update = function(self, dt)
    self.button:update(dt)
end

return function()
    local new = {}
    setmetatable(new, {__index = menuState})

    new:init()

    return new
end