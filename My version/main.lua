WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

servingPlayer = 1
winningPlayer = 0
toWin = 5

push = require 'push'
Class = require 'class'

require 'Paddle'
require 'Ball'
function love.load()
	math.randomseed(os.time())

	love.graphics.setDefaultFilter('nearest', 'nearest')
	love.window.setTitle('Pong')
	smallFont = love.graphics.newFont('font.ttf', 8)
	scoreFont = love.graphics.newFont('font.ttf', 32)
	love.graphics.setFont(smallFont)

	player1Score = 0
	player2Score = 0

	player1 = Paddle(10, 30, 5, 20)
	player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)
	
	ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

	gameState = 'serve'
	
	sounds = {
		['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
		['score'] = love.audio.newSource('sounds/score.wav', 'static'),
		['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')		
	}		
	--[[ For High Res games
	
		love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
		fullscreen = false,
		resizable = false,
		vsync = true
	})
	]]

	push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
		fullscreen = false,
		resizable = true,
		vsync = true,
		canvas = true
	})
end

-- For resizing the window
function love.resize(w, h)
	push:resize(w, h)
end

function love.update(dt)
	
	if gameState == 'serve' then
		ball.dy = math.random(-50, 50)
		if servingPlayer == 1 then		
			ball.dx = math.random(140, 200)
		else
			ball.dx = -math.random(140, 200)
		end
	elseif gameState == 'play' then
		if ball:collides(player1) then
			ball.dx = -ball.dx * 1.03
			ball.x = player1.x + 5
			sounds['paddle_hit']:play()
			if ball.dy < 0 then
				ball.dy = -math.random(10, 150)
			else
				ball.dy = math.random(10, 150)
			end
		end
	
		if ball:collides(player2) then
			ball.dx = -ball.dx * 1.03
			ball.x = player2.x - 4
			sounds['paddle_hit']:play()
			if ball.dy < 0 then
				ball.dy = -math.random(10, 150)
			else
				ball.dy = math.random(10, 150)
			end
		end

		if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
        	sounds['wall_hit']:play()
        end

        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
        	sounds['wall_hit']:play()
        end

        if ball.x < 0 then    		
	        servingPlayer = 1
        	player2Score = player2Score + 1
        	if player2Score >= toWin  then
        		winningPlayer = 2
        		sounds['score']:play()
        		gameState = 'done'
        	else
        		gameState = 'serve'
        		ball:reset()
        	end
        elseif ball.x > VIRTUAL_WIDTH then
        	player1Score = player1Score + 1
        	servingPlayer = 2	
        	if player1Score >= toWin then
        		winningPlayer = 1    		
	        	sounds['score']:play()
        		gameState = 'done'
        	else
        		gameState = 'serve'
        		ball:reset()
        	end
        end
	end

	
	if gameState == 'play' then
		ball:update(dt)
	end

	-- Y axis Movement of Player1
	if love.keyboard.isDown('w') then
		player1.dy = -PADDLE_SPEED
	elseif love.keyboard.isDown('s') then
		player1.dy = PADDLE_SPEED
	else
		player1.dy = 0
	end

	-- Y axis Movement of Player2
	if love.keyboard.isDown('up') then
		player2.dy = -PADDLE_SPEED
	elseif love.keyboard.isDown('down') then
		player2.dy = PADDLE_SPEED
	else
		player2.dy = 0
	end

	-- X axis Movement of player1

	if love.keyboard.isDown('d') then
		player1.dx = PADDLE_SPEED
	elseif love.keyboard.isDown('a') then
		player1.dx = -PADDLE_SPEED
	else 
		player1.dx = 0
	end

	-- X Movement for player2
	if love.keyboard.isDown('right') then
		player2.dx = PADDLE_SPEED
	elseif love.keyboard.isDown('left') then
		player2.dx = -PADDLE_SPEED
	else 
		player2.dx = 0
	end

	-- Limit PLayer1's movement till left side
	if player1.dx < 0 then
    	player1.x = math.max(0, player1.x + player1.dx * dt)
    	-- To keep paddle 1 on the left half
    else
    	player1.x = math.min(VIRTUAL_WIDTH / 4 - player1.width, player1.x + player1.dx * dt)
    end

	-- Limit PLayer2's movement till right side
    if player2.dx < 0 then
    	player2.x = math.max(3 * VIRTUAL_WIDTH / 4 - player2.width, player2.x + player2.dx * dt)
	else
		player2.x = math.min(VIRTUAL_WIDTH - player2.width, player2.x + player2.dx * dt)
	end

	player1:update(dt)
	player2:update(dt)
end

function love.keypressed(key)
	if key == 'escape' then
		love.event.quit()
	
	elseif key == 'enter' or key == 'return' then
		if gameState == 'start' then
			gameState = 'serve'
		elseif gameState == 'serve' then
			gameState = 'play'			
		elseif gameState == 'done' then
			gameState = 'serve'
			ball:reset()
			if winningPlayer == 1 then
				servingPlayer = 2
			else
				servingPlayer = 1
			end
			winningPlayer = 0
			player1Score = 0
			player2Score = 0
		end
	end
end

function love.draw()
	push:apply('start')
	
    love.graphics.clear(40/255, 45/255, 52/255, 255/255)

    love.graphics.setFont(smallFont)
	if gameState == 'start' then
		love.graphics.printf('Press Enter to play', 0, 20, VIRTUAL_WIDTH, 'center') 
	elseif gameState == 'serve' then
		love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve", 0, 20, VIRTUAL_WIDTH, 'center')
	elseif gameState == 'play' then
		love.graphics.printf('Pong!', 0, 20, VIRTUAL_WIDTH, 'center')
		love.graphics.printf(tostring(player1Score), 20, 20, VIRTUAL_WIDTH, 'left')
		love.graphics.printf(tostring(player2Score), VIRTUAL_WIDTH - 20, 20, VIRTUAL_WIDTH, 'left')
	elseif gameState == 'done' then
		love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' won!', 0, 20, VIRTUAL_WIDTH, 'center')
		love.graphics.printf('Press Enter to play again.', 0, 30, VIRTUAL_WIDTH, 'center')
	end
	player1:render()
	player2:render()

	ball:render()	

	displayFPS()
	push:apply('end')
end

function displayFPS()
	love.graphics.setFont(smallFont)
	love.graphics.setColor(0, 255, 0, 255)
	love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end
 