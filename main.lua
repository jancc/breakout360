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
gameInitialized = false
circleCenterX = canvasW / 2
circleCenterY = canvasH / 2
circleRadius = canvasH * 0.45
playerCount = 1
playerPos = 0
playerX = 0
playerY = 0
inputX = 0
inputY = 0
joystick = nil
joyX = 0
joyY = 0
playerEdgeDistance = 0.28
mouseSensitivity = 0.005
shots = {}
powerups = {}
blocks = {}
blocksXCount = 12
blocksYCount = 20
blocksWidth = 8
blocksHeight = 4
blocksXStart = circleCenterX - (blocksXCount/2 + 1)*blocksWidth
blocksYStart = circleCenterY - (blocksYCount/2 + 1)*blocksHeight
points = 0
lifes = 3

--Has to be called when you switch to the joystick
--otherwise the paddle would always jump back to its mouse position
function resetMouse()
	inputX = 0
	inputY = 0
end

function getPlayerPosition(id)
	mod = (math.pi * 2 / playerCount)*id
	return ((playerPos + mod + math.pi) % (math.pi*2)) - math.pi
end

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
	for i=1,playerCount,1 do
		local delta = math.abs(getPlayerPosition(i) - angle)
		if delta < playerEdgeDistance or delta > math.pi * 2 - playerEdgeDistance then
			return true, i
		end
	end
	return false, 0
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

function setBlockArea(x, y, size, b)
	for posY=-size,size,1 do
		for posX=-size,size,1 do
			setBlock(x + posX, y + posY, b)
		end
	end
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

function setBlockAreaAtPos(x, y, size, b)
	local tx = math.floor((x - blocksXStart) / blocksWidth)
	local ty = math.floor((y - blocksYStart) / blocksHeight)
	return setBlockArea(tx, ty, size, b)
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

--todo: load level from a file
function genBlocks()
	for y=1,blocksYCount,1 do
		for x=1,blocksXCount,1 do
			setBlock(x, y, math.random(0, 1))
		end
	end
end

function makeShot()
	--once we are out of lifes or a shot already exists, the function returns
	if table.getn(shots) > 0 or lifes == 0 then
		return
	end
	local shot = {}
	shot.x = playerX
	shot.y = playerY
	shot.angle = playerPos - math.pi
	shot.speed = 96
	shot.vx, shot.vy = vec2rotate(shot.speed, 0, shot.angle)
	shot.insideCircle = false
	--powerups
	--how large the area of destroyed blocks is (0 = only the hit block is destroyed)
	shot.area = 0
	--rocket-mode = shot does not bounce but move straight through blocks
	shot.rocket = false
	table.insert(shots, shot)
end

function makePowerup(x, y, effect)
	local powerup = {}
	powerup.x = x
	powerup.y = y
	powerup.vx, powerup.vy = vec2normalize(x - circleCenterX, y - circleCenterY)
	powerup.vx, powerup.vy = vec2scale(powerup.vx, powerup.vy, 32)
	powerup.effect = effect
	table.insert(powerups, powerup)
end

function bounceShotFromCircle(shot, playerId)
	local mod = circlePointToAngle(shot.x, shot.y) - getPlayerPosition(playerId)
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
		--generate movement delta of this frame
		local dx = shots[i].vx * love.timer.getDelta( )
		local dy = shots[i].vy * love.timer.getDelta( )
		--the shot is at the edge of the circle (outside)
		if not isPointInCircle(shots[i].x + dx, shots[i].y + dy) then
			local collided, playerId = circleIsPlayerOnAngle(circlePointToAngle(shots[i].x + dx, shots[i].y + dy))
			--has the shot collided with the player?
			if not collided then
				--the shot has not collided with the player, remove it
				--add shot to a removeTable, so that it can be removed without breaking this for-loop
				table.insert(removeShots, i)
				points = points - 10
			else
				Audio:playSound("paddle.wav")
				bounceShotFromCircle(shots[i], playerId)
			end
		end
		--tests for collisions with blocks via a raycast
		local hit = blockRaycast(shots[i].x, shots[i].y, shots[i].x + dx, shots[i].y + dy)
		--hit position is not (0,0) so there was a hit!
		if hit.x + hit.y > 0 then
			--remove the block at the hit position
			setBlockAreaAtPos(hit.x, hit.y, 0, 0)
			--move the shot to the hit position
			shots[i].x = hit.x
			shots[i].y = hit.y
			--bounce the shot, according to the side of the block that was hit
			if hit.isVertical then
				shots[i].vy = -shots[i].vy
			else
				shots[i].vx = -shots[i].vx
			end
			points = points + 1
			makePowerup(hit.x, hit.y, "rocket")
			Audio:playSound("brick.wav")
		else
			--nothing was hit, simply move the shot
			shots[i].x = shots[i].x + dx
			shots[i].y = shots[i].y + dy
		end
	end
	--loop through the table that contains all shots that can be removed in this frame
	for i=1,table.getn(removeShots),1 do
		table.remove(shots, removeShots[i])
		--this was the last shot on the field, the player has lost a life
		if table.getn(shots) == 0 then
			lifes = lifes - 1
		end
	end
end

function updatePowerups()
	local powerupsCount = table.getn(powerups)
	local removePowerups = {}
	for i=1,powerupsCount,1 do
		powerups[i].x = powerups[i].x + powerups[i].vx * love.timer.getDelta( )
		powerups[i].y = powerups[i].y + powerups[i].vy * love.timer.getDelta( )
		if not isPointInCircle(powerups[i].x, powerups[i].y) then
			local collided = circleIsPlayerOnAngle(circlePointToAngle(powerups[i].x, powerups[i].y))
			if collided then
				lifes = lifes + 1
			else
				
			end
			table.insert(removePowerups, i)
		end
	end
	--loop through the table that contains all powerups that can be removed in this frame
	for i=1,table.getn(removePowerups),1 do
		table.remove(powerups, removePowerups[i])
	end
end

function updatePlayer()
	--keyboard input (left arrow, right arrow)
	if love.keyboard.isDown("right") then
		playerPos = playerPos + love.timer.getDelta() * 3
		resetMouse()
	elseif love.keyboard.isDown("left") then
		playerPos = playerPos - love.timer.getDelta() * 3
		resetMouse()
	--joystick input (left stick)
	elseif vec2length(joyX, joyY) > 0.25 then
		playerPos = vec2angle(joyX, joyY)
		resetMouse()
	--mouse input
	elseif vec2length(inputX, inputY) > 0.25 then
		playerPos = vec2angle(inputX, inputY)
	end
	playerX, playerY = circleAngleToPoint(playerPos)
	--clamps the player position to (-math.pi, +math.pi)
	playerPos = ((playerPos + math.pi) % (math.pi*2)) - math.pi
	--if playerPos > math.pi then
	--	playerPos = -math.pi
	--elseif playerPos < -math.pi then
	--	playerPos = math.pi
	--end
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

function drawPowerups()
	local powerupsCount = table.getn(powerups)
	for i=1,powerupsCount,1 do
		love.graphics.rectangle("fill", powerups[i].x - 1, powerups[i].y - 1, 2, 2)
	end
end

function drawPlayer(id)
	love.graphics.push()
	love.graphics.translate(circleAngleToPoint(getPlayerPosition(id)))
	love.graphics.rotate(getPlayerPosition(id))
	love.graphics.rectangle("fill", -4, -20, 8, 40)
	love.graphics.pop()
end

function drawPlayers()
	for i=1,playerCount,1 do
		drawPlayer(i)
	end
end

--gets called whenever a new game is started
function initGame()
	genBlocks()
	playerPos = 0
	playerCount = 1
	points = 0
	lifes = 3
	shots = {}
	gameInitialized = true
end

function updateGame()
	updateShots()
	updatePowerups()
	updatePlayer()
end

--updates immediate mode menu
function updateMenu()
	--clear the menu because buttons get re-added every frame
	--not the fastest solution but very simple to use
	Menu:clear()
	if gameInitialized then
		if Menu:button("Continue") then
			setState("game")
		end
		if Menu:button("Back to menu") then
			setState("menu")
			gameInitialized = false
		end
	else
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
	end
	if Menu:button("Quit") then
		love.event.quit()
	end
	if math.abs(joyY) > 0.5 then
		Menu:joyMove(joyY)
	else
		Menu.allowJoyMove = true
	end
	Menu:update()
end

function drawGame()
	love.graphics.setColor(255, 0, 255)
	--draw circle
	love.graphics.circle("line", circleCenterX, circleCenterY, circleRadius)
	drawBlocks()
	drawShots()
	drawPowerups()
	drawPlayers()
	love.graphics.print("Points: " .. tostring(points) .. "\nLifes: " .. tostring(lifes), 0, 0)
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

function toggleState()
	if gamestate == "game" then
		setState("menu")
	elseif gamestate == "menu" then
		setState("game")
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
			makeShot()
		end
	elseif gamestate == "menu" then
		Menu:mousepressed(x, y, button)
	end
end

function love.keypressed(key, scancode, isRepeat)
	if key == "escape" and not isRepeat then
		toggleState()
	end
	if gamestate == "menu" then
		Menu:keypressed(key)
	elseif gamestate == "game" and key == "space" then
		makeShot()
	end
	if key == "return" and love.keyboard.isDown("lalt") then
		local fullscreen = love.window.getFullscreen()
		fullscreen = not fullscreen
		love.window.setFullscreen(fullscreen)
	end
end

function love.joystickadded(newJoystick)
	if joystick == nil then
		joystick = newJoystick
	end
end

function love.joystickremoved(removedJoystick)
	if joystick == removedJoystick then
		joystick = nil
	end
end

function love.joystickpressed(pressedJoystick, button)
	if joystick == pressedJoystick then
		if button == 2 then
			toggleState()
		end
		if gamestate == "menu" then
			Menu:joypressed(button)
		elseif gamestate == "game" and button == 1 then
			makeShot()
		end
	end
end

function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	canvas = love.graphics.newCanvas(canvasW, canvasH)
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
	love.mouse.setVisible(false)
	setState("menu")
	Audio.mute = true
	Audio:loadAll()
	--Audio:playMusic("arena1.s3m")
end

function love.update(dt)
	if joystick ~= nil then
		joyX = joystick:getAxis(1)
		joyY = joystick:getAxis(2)
	else
		joyX = 0
		joyY = 0
	end
	if gamestate == "game" then
		updateGame()
	elseif gamestate == "menu" then
		updateMenu()
	end
end

function love.draw()
	--draws graphics to a canvas, so that they can be rescaled easily
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
