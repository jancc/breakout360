function makePowerup(x, y)
	local powerup = {}
	powerup.x = x
	powerup.y = y
	powerup.vx, powerup.vy = vec2normalize(x - circleCenterX, y - circleCenterY)
	powerup.vx, powerup.vy = vec2scale(powerup.vx, powerup.vy, 32)
	local func = math.random(0, 2)
	if func == 0 then
		powerup.func = powerupFuncAnotherLife
	elseif func == 1 then
		powerup.func = powerupFuncAnotherPlayer
	elseif func == 2 then
		powerup.func = powerupFuncRocket
	end
	table.insert(powerups, powerup)
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
				powerups[i].func()
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

function drawPowerups()
	local powerupsCount = table.getn(powerups)
	for i=1,powerupsCount,1 do
		love.graphics.rectangle("fill", powerups[i].x - 1, powerups[i].y - 1, 2, 2)
	end
end

function powerupFuncRocket()
	if table.getn(shots) > 0 then
		shots[1].rocket = true
	end
end

function powerupFuncAnotherLife()
	lifes = lifes + 1
end

function powerupFuncAnotherPlayer()
	playerCount = playerCount + 1
end