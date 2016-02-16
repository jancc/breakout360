function vec2angle(x, y)
	return math.atan2(y, x)
end

function vec2length(x, y)
	return math.sqrt(x*x + y*y)
end

function vec2normalize(x, y)
	local length = vec2length(x, y)
	return x/length, y/length
end

function vec2scale(x, y, factor)
	return x*factor, y*factor
end

function vec2rotate(x, y, angle)
	local sin = math.sin(angle)
	local cos = math.cos(angle)
	local tx = x
	local ty = y
	x = (cos * tx) - (sin * ty)
	y = (sin * tx) + (cos * ty)
	return x, y
end

function clamp(value, lower, upper)
	if value > upper then
		value = upper
	elseif value < lower then
		value = lower
	end
	return value
end

function pointBoxIntersection(x, y, bx, by, bw, bh)
	return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end