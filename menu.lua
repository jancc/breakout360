Menu = {}
Menu.buttons = {}
Menu.selected = 1
Menu.activated = false
Menu.buttonHeight = 16
Menu.buttonOffset = 64
Menu.allowJoyMove = true

function Menu:button(text)
	table.insert(self.buttons, text)
	if self.activated and table.getn(self.buttons) == self.selected then
		self.activated = false
		return true
	end
	return false
end

function Menu:mousemoved(x, y, dx, dy)
	Menu.selected = math.floor((canvasMouseY - self.buttonOffset)/self.buttonHeight)
end

function Menu:keypressed(key)
	if key == "up" then
		self:moveUp()
	elseif key == "down" then
		self:moveDown()
	elseif key == "space" then
		self.activated = true
	end
end

function Menu:joypressed(button)
	if button == 1 then
		self.activated = true
	end
end

function Menu:joyMove(axis)
	if self.allowJoyMove then
		if axis > 0 then
			self:moveDown()
		elseif axis < 0 then
			self:moveUp()
		end
		self.allowJoyMove = false
	end
end

function Menu:mousepressed(x, y, button)
	if button == 1 then
		Menu.activated = true
	end
end

function Menu:moveUp()
	self.selected = self.selected - 1
	if self.selected < 1 then
		self.selected = table.getn(self.buttons)
	end
end

function Menu:moveDown()
	self.selected = self.selected + 1
	if self.selected > table.getn(self.buttons) then
		self.selected = 1
	end
end

function Menu:update()
	
end

function Menu:draw()
	local number = table.getn(self.buttons)
	for i=1,number,1 do
		if i == self.selected then
			love.graphics.setColor(255, 255, 0)
		else
			love.graphics.setColor(255, 255, 255)
		end
		love.graphics.printf(self.buttons[i], 0, self.buttonOffset + i*self.buttonHeight, canvasW, "center")
		love.graphics.setColor(255, 255, 255)
	end
end

function Menu:clear()
	self.buttons = {}
end