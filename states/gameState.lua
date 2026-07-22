local stateStack = require('stateStack')
local gameOverState = require('states/gameOverState')

local gameState = {}

-- per second
local PLAYER_ACCEL = 300
local PLAYER_MAX_SPEED = 200
local PLAYER_ROTATION_SPEED = math.pi

local BULLET_SHOOT_ANGLES = {0, -math.pi/12, math.pi/12}
local BULLET_SPEED = 300

local DEBUG_VIEW = false

local function rv(x, y, r)
    local c = math.cos(r)
    local s = math.sin(r)

    return c * x - s * y, s * x + c * y
end

local function nGon(nRadius, nCount)
    local thisShape = {}

    for i = 1, nCount do
        local t = 2 * math.pi * (i - 1) / nCount
        local x, y = math.cos(t) * nRadius, math.sin(t) * nRadius

        table.insert(thisShape, x)
        table.insert(thisShape, y)
    end

    return thisShape
end

local shape_prefabs = {
    fallback = {-8,-8, 8,-8, 8,8, -8,8};
    ship = {8,0, -8,-6, -8,6};
    bullet = {6,0, 0,-2, -6,0, 0,2};
    diamond = {-6,0, 0,6, 6,0, 0,-6};
    ngon = nGon(8, 8);
}

local color_prefabs = {
    fallback = {1, 1, 1, 1},
    ship = {0.5, 0.5, 1, 1},
    bullet = {1, 0.5, 0.5, 1}
}

local components = {
    motion = {
        velocity = {
            x = 0,
            y = 0
        },
        wrapBoxSize = {
            w = 16,
            h = 16
        }
    },
    render = {
        points = shape_prefabs.fallback,
        color =  color_prefabs.fallback
    },
    lifespan = {
        duration = 3,
        maxDuration = 3
    },
    hurtbox = {
        damage = 10,
        w = 16,
        h = 16,
        excludeTags = {}
    },
    hitbox = {
        w = 16,
        h = 16,
        hitTag = "default"
    }
}

local templates = {}
local function newTemplate(name)
    local new = table.deepclone(templates[name])
    new.templateName = name

    return new
end

local function ac(e, ...)
    local count = select('#', ...)
    for i = 1, count do
        local val = select(i, ...) 
        if components[val] then
            e[val] = table.deepclone(components[val])
        end
    end
end

templates.player = {
    x = 400,
    y = 300,
    r = 0,
    scale = 1,

    shootCooldown = 0,
    shootCount = 1
}

ac(templates.player, "motion", "render", "hitbox")
templates.player.render.points = shape_prefabs.ship
templates.player.render.color = color_prefabs.ship
templates.player.hitbox.hitTag = "ship"

templates.bullet = {
    x = 0,
    y = 0,
    r = 0,
    scale = 1
}
ac(templates.bullet, "motion", "render", "lifespan", "hurtbox")
templates.bullet.render.points = shape_prefabs.bullet
templates.bullet.render.color = color_prefabs.bullet
templates.bullet.hurtbox.excludeTags = {"ship"}

templates.stone = {
    x = 0,
    y = 0,
    r = 0,
    scale = 1,
    depth = 1
}
ac(templates.stone, "motion", "render", "hitbox", "hurtbox")
templates.stone.hurtbox.excludeTags = {"stone"}
templates.stone.hurtbox.useCircle = true

templates.stone.hitbox.hitTag = "stone"
templates.stone.hitbox.useCircle = true

templates.stone.render.points = shape_prefabs.ngon

local function makeRoid(size, x, y)
    local roid = newTemplate('stone')

    roid.x = x or math.random(0, 800)
    roid.y = y or math.random(0, 600)
    roid.depth = size or math.random(1, 3)
    roid.scale = roid.depth * 1.5
    roid.r = math.random() * 2 * math.pi

    local mx, my = rv(1, 0, math.random(1, 100) / 100 * 2 * math.pi)
    local ms = math.random(85, 115)

    roid.motion.velocity.x = mx * ms
    roid.motion.velocity.y = my * ms
    
    return roid
end

local function solveCircleRectCollision(x1, y1, r, x2, y2, w, h)
    local closeX = math.max(x2, math.min(x1, x2 + w))
    local closeY = math.max(y2, math.min(y1, y2 + h))

    local dx, dy = x1 - closeX, y1 - closeY

    return math.sqrt(dx*dx + dy*dy) <= r
end

gameState.init = function(self)
    math.randomseed(os.time())

    local player = newTemplate('player')

    self.entities = {}
    table.insert(self.entities, newTemplate('player'))

    for i = 1, 4 do
        local roid = makeRoid()
        table.insert(self.entities, roid)
    end

    self.score = 0
    self.scoreFont = love.graphics.newFont('assets/fonts/audiowide.ttf', 24)

    self.particleTs = 0.1
    self.roidSpawnTs = 2

    self.clock = 0
end

gameState.update = function(self, dt)
    self.clock = self.clock + dt
    if self.gameOutcome and self.clock - self.gameOutcome.timeAlive > 1 then
        local screenResults = gameOverState()
        screenResults.scoreToDisplay = self.gameOutcome.score
        screenResults.lifetimeToDisplay = self.gameOutcome.timeAlive

        stateStack.push(screenResults)
    elseif love.keyboard.wasPressed('escape') then
        stateStack.pop()
    end

    if love.keyboard.wasPressed("c") then
        DEBUG_VIEW = not DEBUG_VIEW
    end

    if self.gameOutcome then
        local a = self.clock - self.gameOutcome.timeAlive
        a = math.sin(a * math.pi / 2)

        dt = dt * (1 - a)
    end

    self.roidSpawnTs = math.max(self.roidSpawnTs - dt)
    if self.roidSpawnTs <= 0 then
        self.roidSpawnTs = 1.5 * (2.5 - 1.5) * math.random()

        local roid = makeRoid(
            nil, 
            400 + 500 * (math.random() > 0.5 and 1 or -1), 
            300 + 400 * (math.random() > 0.5 and 1 or -1)
        )
        table.insert(self.entities, roid)
    end

    local moveInput = (love.keyboard.isDown("w") and 1 or 0) - (love.keyboard.isDown("s") and 1 or 0)
    local rotationInput = (love.keyboard.isDown("d") and 1 or 0) - (love.keyboard.isDown("a") and 1 or 0)

    local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
    local player = self.entities[1]

    if player and player.templateName == "player" then
        player.shootCooldown = math.max(player.shootCooldown - dt, 0)
        player.r = player.r + rotationInput * PLAYER_ROTATION_SPEED * dt
        
        local vel = player.motion.velocity
        local accel_x, accel_y = rv(PLAYER_ACCEL * dt * moveInput, 0, player.r)
        vel.x = vel.x + accel_x
        vel.y = vel.y + accel_y

        local thisSpeed = math.sqrt(vel.x*vel.x + vel.y*vel.y)
        if thisSpeed > PLAYER_MAX_SPEED then
            vel.x = vel.x / thisSpeed * PLAYER_MAX_SPEED
            vel.y = vel.y / thisSpeed * PLAYER_MAX_SPEED
        end

        if moveInput ~= 0 then
            self.particleTs = math.max(self.particleTs - dt, 0)

            if self.particleTs <= 0 then
                self.particleTs = 0.25

                local new = {x = math.random(0, love.graphics.getWidth()), y = 612, scale = 1}
                local faceX, faceY = rv(-1, 0, player.r)

                ac(new, "motion", "render", "lifespan")

                local randDur = 3
                new.lifespan.duration, new.lifespan.maxDuration = randDur, randDur
                new.lifespan.fadeOverDuration = true
                new.render.color = {1, 0.75, 0.75, 0.25}
                new.render.points = shape_prefabs.diamond
                new.x = player.x + faceX * 8
                new.y = player.y + faceY * 8
                new.motion.velocity = {x = faceX * 10, y = faceY * 10 - 25}

                table.insert(self.entities, new)
            end
        end

        if love.keyboard.isDown("space") and player.shootCooldown <= 0 then
            player.shootCooldown = 0.1
            
            for i = 1, math.min(player.shootCount, #BULLET_SHOOT_ANGLES) do
                local br = BULLET_SHOOT_ANGLES[i]
                local faceX, faceY = rv(1, 0, player.r + br)

                local bullet = newTemplate('bullet')
                bullet.motion.velocity.x, bullet.motion.velocity.y = faceX * BULLET_SPEED, faceY * BULLET_SPEED
                bullet.x = player.x + faceX * 16
                bullet.y = player.y + faceY * 16
                bullet.r = player.r + br
                bullet.owner = player

                table.insert(self.entities, bullet)
            end
        end
    end

    local queued_for_removal = {}

    for i, e in pairs(self.entities) do
        if e.motion then
            local vel = e.motion.velocity
            e.x = e.x + vel.x * dt
            e.y = e.y + vel.y * dt

            local boxToUse = e.motion.wrapBoxSize
            local boundX = boxToUse.w * e.scale
            local boundY = boxToUse.h * e.scale

            if e.x < -boundX then
                e.x = screenWidth + boundX
            elseif e.x > screenWidth + boundX then
                e.x = -boundX
            end
            if e.y < -boundY then
                e.y = screenHeight + boundY
            elseif e.y > screenHeight + boundY then
                e.y = -boundY
            end
        end

        if e.lifespan then
            e.lifespan.duration = math.max(e.lifespan.duration - dt, 0)
            if e.lifespan.duration <= 0 then
                table.insert(queued_for_removal, i)
            end
        end

        if e.hurtbox then
            for id, e2 in pairs(self.entities) do
                if e2.hitbox and not table.contains(e.hurtbox.excludeTags, e2.hitbox.hitTag) then

                    local isColliding = false

                    -- Handle separate collision check cases based on hitbox shape

                    -- a) Hurtbox is circle, hitbox is square
                    if e.hurtbox.useCircle and not e2.hitbox.useCircle then
                        local w2, h2 = e2.hitbox.w * e2.scale, e2.hitbox.h * e2.scale
                        local x2, y2 = e2.x - w2/2, e2.y - h2/2

                        isColliding = solveCircleRectCollision(e.x, e.y, e.hurtbox.w * e.scale / 2, x2, y2, w2, h2)
                    -- b) Hurtbox is square, hitbox is circle
                    elseif not e.hurtbox.useCircle and e2.hitbox.useCircle then
                        local w2, h2 = e.hurtbox.w * e.scale, e.hurtbox.h * e.scale
                        local x2, y2 = e.x - w2/2, e.y - h2/2
                        
                        isColliding = solveCircleRectCollision(e2.x, e2.y, e2.hitbox.w * e2.scale / 2, x2, y2, w2, h2)
                    -- c) Both are squares
                    else
                        local w1, h1 = e.hurtbox.w * e.scale, e.hurtbox.h * e.scale
                        local x1, y1 = e.x - w1/2, e.y - h1/2

                        local w2, h2 = e2.hitbox.w * e2.scale, e2.hitbox.h * e2.scale
                        local x2, y2 = e2.x - w2/2, e2.y - h2/2

                        isColliding = x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
                    end
                    
                    if isColliding then
                        if e2.templateName == "player" then
                            table.insert(queued_for_removal, id)
                            break
                        end

                        table.insert(queued_for_removal, id)
                        table.insert(queued_for_removal, i)
                        break
                    end
                end
            end
        end
    end
    
    for i = #queued_for_removal, 1, -1 do
        local id = queued_for_removal[i]
        local e = self.entities[id]

        if e then
            if e.templateName == "stone" then
                self.score = self.score + 1
                
                if e.depth > 1 then
                    for i = 1, 2 do
                        local randomAngle = math.random() * math.pi * 2
                        local rx, ry = rv(1, 0, randomAngle)

                        local newRoid = makeRoid(e.depth - 1, e.x + rx * 16, e.y + ry * 16)
                        table.insert(self.entities, newRoid)
                    end
                end
            elseif e.templateName == "player" then
                self.gameOutcome = {
                    lost = true,
                    score = self.score,
                    timeAlive = self.clock
                }
            end
        end

        table.remove(self.entities, id)
    end
end

gameState.draw = function(self)
    for i, e in pairs(self.entities) do
        if e.render then
            love.graphics.push('all')

            love.graphics.translate(e.x, e.y)
            love.graphics.rotate(e.r or 0)

            local color = {unpack(e.render.color)}
            if e.lifespan and e.lifespan.fadeOverDuration then
                color[4] = color[4] * e.lifespan.duration/e.lifespan.maxDuration
            end

            love.graphics.setColor(unpack(color))

            if e.scale == 1 then
                love.graphics.polygon('line', unpack(e.render.points))
            else
                local points = table.deepclone(e.render.points)
                for i, v in pairs(points) do
                    points[i] = v * e.scale
                end
                
                love.graphics.polygon('line', unpack(points))
            end

            love.graphics.pop()
        end

        if DEBUG_VIEW then
            love.graphics.rectangle('fill', e.x - 4, e.y - 1, 8, 2)
            love.graphics.rectangle('fill', e.x - 1, e.y - 4, 2, 8)

            if e.hitbox then
                local boundX, boundY = e.hitbox.w, e.hitbox.h
                boundX = boundX * e.scale
                boundY = boundY * e.scale

                local color = {0, 1, 0, 0.5}

                love.graphics.setColor(color)

                if e.hitbox.useCircle then
                    love.graphics.circle('line', e.x, e.y, boundX/2)
                else
                    love.graphics.rectangle('line', e.x - boundX/2, e.y - boundY/2, boundX, boundY)
                end

                love.graphics.setColor(1, 1, 1, 1)
            end

            if e.hurtbox then
                local boundX, boundY = e.hurtbox.w, e.hurtbox.h
                boundX = boundX * e.scale
                boundY = boundY * e.scale

                local color = {1, 0, 0, 0.5}

                love.graphics.setColor(color)

                if e.hurtbox.useCircle then
                    love.graphics.circle('line', e.x, e.y, boundX/2)
                else
                    love.graphics.rectangle('line', e.x - boundX/2, e.y - boundY/2, boundX, boundY)
                end

                love.graphics.setColor(1, 1, 1, 1)
            end
        end
    end

    if not self.gameOutcome then
        love.graphics.setFont(self.scoreFont)
        love.graphics.printf("Score: "..math.floor(self.score), 0, 0, love.graphics.getWidth(), 'center')
    end

    if DEBUG_VIEW then
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.print("Entities: "..#self.entities.."\nFPS: ".. love.timer.getFPS())
    end
end

return function()
    local new = {}
    setmetatable(new, {__index = gameState})

    new:init()

    return new
end