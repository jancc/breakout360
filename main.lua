require("mathex")
require("audio")
require("menu")
require("world")
require("player")
require("shot")
require("powerup")

canvasW = 1280
canvasH = 720
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
blocksWidth = 32
blocksHeight = 16
blocksXStart = circleCenterX - (blocksXCount/2 + 1)*blocksWidth
blocksYStart = circleCenterY - (blocksYCount/2 + 1)*blocksHeight
points = 0
lifes = 3
images = {}

--Has to be called when you switch to the joystick
--otherwise the paddle would always jump back to its mouse position
function resetMouse()
	inputX = 0
	inputY = 0
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
	love.graphics.setColor(255, 100, 0)
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

function loadImage(id, filename)
	images[id] = love.graphics.newImage("gfx/" .. filename)
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
		toggleState()
	end
	if gamestate == "menu" then
		Menu:keypressed(key)
	elseif gamestate == "game" and key == "space" then
		shoot()
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
			shoot()
		end
	end
end

function love.load()
	--love.graphics.setDefaultFilter("nearest", "nearest", 0)
	canvas = love.graphics.newCanvas(canvasW, canvasH)
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
	love.mouse.setVisible(false)
	setState("menu")
	Audio.mute = true
	Audio:loadAll()
	loadImage("brick", "brick.png")
	loadImage("paddle", "paddle.png")
	loadImage("ball", "ball.png")
	--Audio:playMusic("arena1.s3m")
	Menu:load()
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
	love.graphics.push()
	if gameInitialized then
		drawGame()
	end
	if gamestate == "menu" then
		drawMenu()
	end
	love.graphics.pop()
	love.graphics.setCanvas()
	canvasScaleX = love.graphics.getWidth() / canvasW
	canvasScaleY = love.graphics.getHeight() / canvasH
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(canvas, 0, 0, 0, canvasScaleX, canvasScaleY)
	love.graphics.setColor(255, 0, 0)
	love.graphics.print("Development Version", 0, love.graphics.getHeight() - 16)
end
