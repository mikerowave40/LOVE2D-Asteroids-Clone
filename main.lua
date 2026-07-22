_G.loveMethodsToPass = {
    "mousepressed",
    "mousereleased",
    "keypressed",
    "keyreleased"
}

local keysPressed = {}

local function deepcopy(orig, copies)
    copies = copies or {}
    if type(orig) ~= 'table' then 
        return orig 
    end

    if copies[orig] then 
        return copies[orig] 
    end
    
    local copy = {}
    copies[orig] = copy
    
    for orig_key, orig_value in next, orig, nil do
        copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
    end

    return copy -- setmetatable(copy, deepcopy(getmetatable(orig), copies))
end
table.deepclone = deepcopy

local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end
table.contains = has_value

local stateStack = require("stateStack")
local menuState = require("states/menuState")
local gameState = require("states/gameState")

function love.load()
    local menuState = menuState()
    
    stateStack.push(menuState)

    love.graphics.setDefaultFilter('nearest')
    love.graphics.setBackgroundColor(0.01, 0, 0.05)
end

function love.update(dt)
    stateStack.update(dt)

    keysPressed = {}
end

function love.draw()
    stateStack.draw()
end

for i, fname in pairs(loveMethodsToPass) do
    love[fname] = function(...)
        stateStack[fname](...)
    end
end

function love.keypressed(key)
    stateStack.keypressed(key)
    keysPressed[key] = true
end

function love.keyboard.wasPressed(key)
    return keysPressed[key] == true
end