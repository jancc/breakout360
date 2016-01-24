require("mathex")
require("audio")
require("menu")

canvasW = 320
canvasH = 180
canvasScaleX = 1
canvasScaleY = 1
canvasMouseX = 0
canvasMouseY = 0
canvas = nil
gamestate = "none"
circleCenterX = canvasW / 2
circleCenterY = canvasH / 2
circleRadius = canvasH * 0.45
playerPos = 0
playerX = 0
playerY = 0
inputX = 0
inputY = 0
playerEdgeDistance = 0.28
mouseSensitivity = 0.005
shots = {}
blocks = {}
blocksXCount = 12
blocksYCount = 20
blocksWidth = 8
blocksHeight = 4
blocksXStart = circleCenterX - (blocksXCount/2 + 1)*blocksWidth
blocksYStart = circleCenterY - (blocksYCount/2 + 1)*blocksHeight
points = 0

function circleAngleToPoint(circleAngle)
	local x = circleCenterX + circleRadius * math.cos(circleAngle)
	local y = circleCenterY + circleRadius * math.sin(circleAngle)
	return x, y
end

function circlePointToAngle(x, y)
	return math.atan2(y - circleCenterY, x - circleCenterX)
end

function circleGetOppositePoint(x, y)
	local opX = x + (circleCenterX - x) * 2
	local opY = y + (circleCenterY - y) * 2
	return opX, opY
end

function circleIsPlayerOnAngle(angle)
	local delta = math.abs(playerPos - angle)
	return delta < playerEdgeDistance or delta > math.pi * 2 - playerEdgeDistance
end

function isPointInCircle(x, y)
	local dx = x - circleCenterX
	local dy = y - circleCenterY
	local dist = math.sqrt(dx*dx + dy*dy)
	return dist < circleRadius
end

function setBlock(x, y, b)
	if x < 1 or y < 1 or x > blocksXCount or y > blocksYCount then
		return
	end
	blocks[blocksXCount * y + x] = b
end

function getBlock(x, y)
	if x < 1 or y < 1 or x > blocksXCount or y > blocksYCount then
		return 0
	end
	return blocks[blocksXCount * y + x]
end

function setBlockAtPos(x, y, b)
	local tx = math.floor((x - blocksXStart) / blocksWidth)
	local ty = math.floor((y - blocksYStart) / blocksHeight)
	return setBlock(tx, ty, b)
end

function getBlockAtPos(x, y)
	local tx = math.floor((x - blocksXStart) / blocksWidth)
	local ty = math.floor((y - blocksYStart) / blocksHeight)
	return getBlock(tx, ty)
end

function makeRaycastHit(x, y, isVertical)
	local hit = {}
	hit.x = x
	hit.y = y
	hit.isVertical = isVertical
	return hit
end

function blockRaycast(x1, y1, x2, y2)
	local dx = x2 - x1
	local dy = y2 - y1
	local steps = 0
	if math.abs(dx) > math.abs(dy) then
		steps = math.ceil(math.abs(dx))
	else
		steps = math.ceil(math.abs(dy))
	end
	local xInc = dx / steps
	local yInc = dy / steps
	local xStep = 0
	local yStep = 0
	for i=0,steps,1 do
		if getBlockAtPos(x1, y1 + yStep) > 0 then
			return makeRaycastHit(x1, y1 + yStep, true)
		elseif getBlockAtPos(x1 + xStep, y1) > 0 then
			return makeRaycastHit(x1 + xStep, y1, false)
		end
		xStep = xStep + xInc
		yStep = yStep + yInc
	end
	return makeRaycastHit(0, 0, false)
end

function genBlocks()
	for y=1,blocksYCount,1 do
		for x=1,blocksXCount,1 do
			setBlock(x, y, math.random(0, 1))
		end
	end
end

function shoot()
	local shot = {}
	shot.x = playerX
	shot.y = playerY
	shot.angle = playerPos - math.pi
	shot.speed = 96
	shot.vx, shot.vy = vec2rotate(shot.speed, 0, shot.angle)
	shot.insideCircle = false
	table.insert(shots, shot)
end

function bounceShotFromCircle(shot)
	local mod = circlePointToAngle(shot.x, shot.y) - playerPos
	shot.angle = circlePointToAngle(shot.x, shot.y) - mod * 3.5 + math.pi
	shot.vx, shot.vy = vec2rotate(shot.speed, 0, shot.angle)
	shot.x, shot.y = vec2normalize(shot.x - circleCenterX, shot.y - circleCenterY)
	shot.x = shot.x * (circleRadius - 2) + circleCenterX
	shot.y = shot.y * (circleRadius - 2) + circleCenterY
end

function updateShots()
	local shotCount = table.getn(shots)
	local removeShots = {}
	for i=1,shotCount,1 do
		local dx = shots[i].vx * love.timer.getDelta( )
		local dy = shots[i].vy * love.timer.getDelta( )
		if not isPointInCircle(shots[i].x + dx, shots[i].y + dy) then
			bounceShotFromCircle(shots[i])
			if not circleIsPlayerOnAngle(circlePointToAngle(shots[i].x + dx, shots[i].y + dy)) then
				table.insert(removeShots, i)
				points = points - 10
			else
				Audio:playSound("paddle.wav")
			end
		end
		local hit = blockRaycast(shots[i].x, shots[i].y, shots[i].x + dx, shots[i].y + dy)
		if hit.x + hit.y > 0 then
			setBlockAtPos(hit.x, hit.y, 0)
			shots[i].x = hit.x
			shots[i].y = hit.y
			if hit.isVertical then
				shots[i].vy = -shots[i].vy
			else
				shots[i].vx = -shots[i].vx
			end
			points = points + 1
			Audio:playSound("brick.wav")
		else
			shots[i].x = shots[i].x + dx
			shots[i].y = shots[i].y + dy
		end
	end
	for i=1,table.getn(removeShots),1 do
		table.remove(shots, removeShots[i])
	end
end

function updatePlayer()
	if vec2length(inputX, inputY) > 0.25 then
		playerPos = vec2angle(inputX, inputY)
	elseif love.keyboard.isDown("right") then
		playerPos = playerPos + love.timer.getDelta() * 3
	elseif love.keyboard.isDown("left") then
		playerPos = playerPos - love.timer.getDelta() * 3
	end
	playerX, playerY = circleAngleToPoint(playerPos)
	if playerPos > math.pi then
		playerPos = -math.pi
	elseif playerPos < -math.pi then
		playerPos = math.pi
	end
end

function drawBlocks()
	for y=1,blocksYCount,1 do
		for x=1,blocksXCount,1 do
			if getBlock(x, y) == 1 then
				local xPos = x * blocksWidth + blocksXStart
				local yPos = y * blocksHeight + blocksYStart
				love.graphics.rectangle("line", xPos, yPos, 8, 4)
			end
		end
	end
end

function drawShots()
	local shotCount = table.getn(shots)
	for i=1,shotCount,1 do
		--love.graphics.rectangle("fill", shots[i].x - 1, shots[i].y - 4, 8, 8)
		love.graphics.points(shots[i].x, shots[i].y)
	end
end

function drawShapes()
	local shapesCount = table.getn(shapes)
	for i=1,shapesCount,1 do
		love.graphics.circle("fill", shapes[i].x, shapes[i].y, shapes[i].scale, shapes[i].segments)
	end
end

function drawPlayer()
	love.graphics.push()
	love.graphics.translate(circleAngleToPoint(playerPos))
	love.graphics.rotate(playerPos)
	love.graphics.rectangle("fill", -4, -20, 8, 40)
	love.graphics.pop()
end

function initGame()
	genBlocks()
	playerPos = 0
	points = 0
end

function updateGame()
	updateShots()
	updatePlayer()
end

function updateMenu()
	Menu:clear()
	if Menu:button("Play") then
		initGame()
		setState("game")
	end
	if Menu:button("Scores") then
		
	end
	if Menu:button("Settings") then
	
	end
	if Menu:button("Visit JanCC.de") then
		love.system.openURL("http://jancc.de")
	end
	if Menu:button("Quit") then
		love.event.quit()
	end
	Menu:update()
end

function drawGame()
	love.graphics.setColor(255, 0, 255)
	--draw circle
	love.graphics.circle("line", circleCenterX, circleCenterY, circleRadius)
	drawBlocks()
	drawShots()
	drawPlayer()
	love.graphics.print("Points: " .. tostring(points), 0, 0)
end

function drawMenu()
	Menu:draw()
	local canvas_mouse_x = love.mouse.getX() / (love.graphics.getWidth() / canvasW)
	local canvas_mouse_y = love.mouse.getY() / (love.graphics.getHeight() / canvasH)
	love.graphics.points(canvas_mouse_x, canvas_mouse_y)
end

function setState(state)
	gamestate = state
	if gamestate == "game" then
		love.mouse.setRelativeMode(true)
	else
		love.mouse.setRelativeMode(false)
	end
end

function love.mousemoved(x, y, dx, dy)
	canvasMouseX = x / (love.graphics.getWidth() / canvasW)
	canvasMouseY = y / (love.graphics.getHeight() / canvasH)
	if gamestate == "game" then
		inputX = clamp(inputX + dx * mouseSensitivity, -1.0, 1.0)
		inputY = clamp(inputY + dy * mouseSensitivity, -1.0, 1.0)
	elseif gamestate == "menu" then
		Menu:mousemoved(x, y, dx, dy)
	end
end

function love.mousepressed(x, y, button)
	if gamestate == "game" then
		if button == 1 then
			shoot()
		end
	elseif gamestate == "menu" then
		Menu:mousepressed(x, y, button)
	end
end

function love.keypressed(key, scancode, isRepeat)
	if key == "escape" and not isRepeat then
		if gamestate == "game" then
			setState("menu")
		else
			setState("game")
		end
	end
	if gamestate == "menu" then
		Menu:keypressed(key)
	end
	if key == "return" and love.keyboard.isDown("lalt") then
		local fullscreen = love.window.getFullscreen()
		fullscreen = not fullscreen
		love.window.setFullscreen(fullscreen)
	end
end

function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	canvas = love.graphics.newCanvas(canvasW, canvasH)
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
	love.mouse.setVisible(false)
	local joysticks = love.joystick.getJoysticks()
	joystick = joysticks[1]
	setState("menu")
	initGame()
	Audio.mute = true
	Audio:loadAll()
	--Audio:playMusic("arena1.s3m")
end

function love.update(dt)
	if gamestate == "game" then
		updateGame()
	elseif gamestate == "menu" then
		updateMenu()
	end
end

function love.draw()
	love.graphics.setCanvas(canvas)
	love.graphics.clear()
	love.graphics.setColor(255, 255, 255)
	love.graphics.push()
	if gamestate == "game" then
		drawGame()
	elseif gamestate == "menu" then
		drawMenu()
	end
	love.graphics.pop()
	love.graphics.setCanvas()
	canvasScaleX = love.graphics.getWidth() / canvasW
	canvasScaleY = love.graphics.getHeight() / canvasH
	love.graphics.draw(canvas, 0, 0, 0, canvasScaleX, canvasScaleY)
	love.graphics.setColor(255, 0, 0)
	love.graphics.print("Development Version", 0, love.graphics.getHeight() - 16)
end
