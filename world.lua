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
			setBlock(x, y, math.random(0, 3))
		end
	end
end

function drawBlocks()
	love.graphics.setColor(0, 255, 0)
	local block = 0
	for y=1,blocksYCount,1 do
		for x=1,blocksXCount,1 do
			block = getBlock(x, y)
			if block > 0 then
				if block == 1 then
					love.graphics.setColor(255, 0, 0)
				elseif block == 2 then
					love.graphics.setColor(0, 255, 0)
				elseif block == 3 then
					love.graphics.setColor(0, 0, 255)
				end
				local xPos = x * blocksWidth + blocksXStart
				local yPos = y * blocksHeight + blocksYStart
				love.graphics.draw(images["brick"], xPos, yPos)
			end
		end
	end
end