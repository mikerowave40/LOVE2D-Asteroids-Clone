local stack = {}
local states = {}
stack.states = states

stack.push = function(newState)
    table.insert(states, newState)
end

stack.pop = function()
    table.remove(states, #states)
end

stack.update = function(dt)
    if #states > 0 and states[#states] then
        states[#states]:update(dt)
    end
end

stack.draw = function(dt)
    local drawStack = {}
    table.insert(drawStack, states[#states])

    if #states > 1 then
        local i = #states

        while states[i].drawPreviousState do
            table.insert(drawStack, 1, states[i - 1])
            i = i - 1
        end
    end

    for i, v in pairs(drawStack) do
        v:draw()
    end
end

for i, fname in pairs(loveMethodsToPass) do
    stack[fname] = function(...)
        if #states > 0 and states[#states][fname] then
            local thisState = states[#states]
            thisState[fname](thisState, ...)
        end
    end
end

return stack