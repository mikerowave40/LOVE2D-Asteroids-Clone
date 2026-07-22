local stateStack = require('stateStack')
local button = require('classes/button')

local gameOverState = {}

local holyYapSesh = [[Nice job blastin' them 'roids, son!
Score: %i
Time Alive: %d seconds

Thanks for playing this small prototype!]]

gameOverState.init = function(self)
    self.button = button("Menu", 25, 600 - 40 - 25, 200, 40)
    self.button.skew = 0.2
    self.button.click = function()
        stateStack.pop()
        stateStack.pop()
    end

    self.font = love.graphics.newFont('assets/fonts/audiowide.ttf', 36)
    self.btnFont = love.graphics.newFont('assets/fonts/audiowide.ttf', 24)
    self.blurbFont = love.graphics.newFont('assets/fonts/audiowide.ttf', 16)

    self.bgOpacity = 0
end

gameOverState.draw = function(self)
    local w = love.graphics.getWidth()

    love.graphics.push('all')

    local r, g, b, a = love.graphics.getBackgroundColor()

    love.graphics.setColor(r, g, b, a * self.bgOpacity * 0.5)
    love.graphics.rectangle('fill', 0, 0, w, love.graphics.getHeight())

    love.graphics.pop()

    love.graphics.push('all')

    love.graphics.setFont(self.font)
    love.graphics.printf("Game Over!", 0, 50, w, 'center')

    love.graphics.setFont(self.btnFont)
    self.button:draw()

    love.graphics.setFont(self.blurbFont)
    love.graphics.printf(holyYapSesh:format(self.scoreToDisplay or 0, self.lifetimeToDisplay or 0), w*0.1, 250, w*0.8, 'center')

    love.graphics.pop()
end

gameOverState.update = function(self, dt)
    self.bgOpacity = math.min(self.bgOpacity + dt, 1)

    local mx, my = love.mouse.getPosition()
    local lmb_down = love.mouse.isDown(1)
    
    for i, v in pairs({self.button, self.infobutton}) do
        v:update(dt)
    end
end

return function()
    local new = {}
    new.drawPreviousState = true

    setmetatable(new, {__index = gameOverState})

    new:init()

    return new
end