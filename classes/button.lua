
return function(text, x, y, width, height)
    return {
        transform = {x or 0, y or 0, width or 200, height or 50},
        text = text or "No Text",

        hovering = false,
        pressing = false,
        skew = 0,

        update = function(self, dt)
            local mx, my = love.mouse.getPosition()
            local lmbDown = love.mouse.isDown(1)

            local bt = self.transform
            local mouseOverButton = bt[1] <= mx and mx <= bt[1] + bt[3] and bt[2] <= my and my <= bt[2] + bt[4]
            self.hovering = mouseOverButton

            if mouseOverButton and lmbDown then
                self.pressing = true
            else
                if self.pressing and mouseOverButton then
                    if self.click then
                        self.click()
                    end
                end

                self.pressing = false
            end
        end,

        draw = function(self)
            local bt = self.transform
            local color = {0.5, 0.5, 0.5, 0.5}
            color = self.hovering and {0.75, 0.75, 0.75, 0.5} or color
            color = self.pressing and {1, 1, 1, 0.5} or color

            love.graphics.setColor(unpack(color))
            love.graphics.setLineWidth(2)

            love.graphics.push()

            love.graphics.translate(bt[1] + bt[3]/2, bt[2] + bt[4]/2)

            love.graphics.shear(self.skew, 0)
            love.graphics.rectangle('line', -bt[3]/2, -bt[4]/2, bt[3], bt[4])

            love.graphics.pop()

            love.graphics.setColor(1, 1, 1, 1)

            love.graphics.printf(self.text, bt[1], bt[2] + math.floor(bt[4]/2 - love.graphics.getFont():getHeight()/2 + 0.5), bt[3], 'center')
        end
    }
end