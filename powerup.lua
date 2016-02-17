function makePowerup(x, y, effect)
	local powerup = {}
	powerup.x = x
	powerup.y = y
	powerup.vx, powerup.vy = vec2normalize(x - circleCenterX, y - circleCenterY)
	powerup.vx, powerup.vy = vec2scale(powerup.vx, powerup.vy, 32)
	powerup.effect = effect
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

function drawPowerups()
	local powerupsCount = table.getn(powerups)
	for i=1,powerupsCount,1 do
		love.graphics.rectangle("fill", powerups[i].x - 1, powerups[i].y - 1, 2, 2)
	end
end