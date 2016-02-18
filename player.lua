function getPlayerPosition(id)
	mod = (math.pi * 2 / playerCount)*id
	return ((playerPos + mod + math.pi) % (math.pi*2)) - math.pi
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

function drawPlayer(id)
	love.graphics.push()
	love.graphics.translate(circleAngleToPoint(getPlayerPosition(id)))
	love.graphics.rotate(getPlayerPosition(id))
	love.graphics.draw(images["paddle"], -16, -80)
	love.graphics.pop()
end

function drawPlayers()
	love.graphics.setColor(0, 0, 255)
	for i=1,playerCount,1 do
		drawPlayer(i)
	end
end