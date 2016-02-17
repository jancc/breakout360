function makeShot()
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
	return shot
end

function makeShotAtPos(x, y)
	local shot = makeShot()
	shot.x = x
	shot.y = y
	shot.speed = 96
end

function shoot()
	--once we are out of lifes or a shot already exists, the function returns
	if table.getn(shots) == 0 and lifes > 0 then
		makeShot()
	end
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
			if math.random(0, 1) == 1 then
				makePowerup(hit.x, hit.y)
			end
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

function drawShots()
	local shotCount = table.getn(shots)
	for i=1,shotCount,1 do
		--love.graphics.rectangle("fill", shots[i].x - 1, shots[i].y - 4, 8, 8)
		love.graphics.points(shots[i].x, shots[i].y)
	end
end