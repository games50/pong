--[[
push.lua v1.0

The MIT License (MIT)

Copyright (c) 2018 Ulysse Ramage

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

local settings

local pushWidth, pushHeight
local windowWidth, windowHeight

local scale = {x = 0, y = 0}
local offset = {x = 0, y = 0}

local drawWidth, drawHeight

local canvases

local canvasOptions

local function initValues()
	if settings.upscale then
		scale.x = windowWidth / pushWidth
		scale.y = windowHeight / pushHeight

		if settings.upscale == "normal" or settings.upscale == "pixel-perfect" then
			local scaleVal

			scaleVal = math.min(scale.x, scale.y)
			if scaleVal >= 1 and settings.upscale == "pixel-perfect" then scaleVal = math.floor(scaleVal) end

			offset.x = math.floor((scale.x - scaleVal) * (pushWidth / 2))
			offset.y = math.floor((scale.y - scaleVal) * (pushHeight / 2))

			scale.x, scale.y = scaleVal, scaleVal -- Apply same scale to width and height
		elseif settings.upscale == "stretched" then -- If stretched, no need to apply offset
			offset.x, offset.y = 0, 0
		else
			error("Invalid upscale setting")
		end
	else
		scale.x, scale.y = 1, 1

		offset.x = math.floor((windowWidth / pushWidth - 1) * (pushWidth / 2))
		offset.y = math.floor((windowHeight / pushHeight - 1) * (pushHeight / 2))
	end

	drawWidth = windowWidth - offset.x * 2
	drawHeight = windowHeight - offset.y * 2
end

local function setupCanvas(canvasTable)
	table.insert(canvasTable, {name = "_render", private = true}) -- Final render

	canvases = {}

	for i = 1, #canvasTable do
		local params = canvasTable[i]

		table.insert(
			canvases,
			{
				name = params.name,
				private = params.private,
				shader = params.shader,
				canvas = love.graphics.newCanvas(pushWidth, pushHeight),
				stencil = params.stencil
			}
		)
	end

	canvasOptions = {canvases[1].canvas, stencil = canvases[1].stencil}
end

local function getCanvasTable(name)
	for i = 1, #canvases do
		if canvases[i].name == name then
			return canvases[i]
		end
	end
end

local function start()
	if settings.canvas then
		love.graphics.push()
		love.graphics.setCanvas(canvasOptions)
	else
		love.graphics.translate(offset.x, offset.y)
		love.graphics.setScissor(offset.x, offset.y, pushWidth * scale.x, pushHeight * scale.y)
		love.graphics.push()
		love.graphics.scale(scale.x, scale.y)
	end
end

local function applyShaders(canvas, shaders)
	local shader = love.graphics.getShader()

	if #shaders <= 1 then
		love.graphics.setShader(shaders[1])
		love.graphics.draw(canvas)
	else
		local canvas = love.graphics.getCanvas()
		local tmp = getCanvasTable("_tmp")
		local outputCanvas
		local inputCanvas

		-- Only create "_tmp" canvas if needed
		if not tmp then
			table.insert(
				canvases,
				{
			 		name = "_tmp",
			  		private = true,
			  		canvas = love.graphics.newCanvas(pushWidth, pushHeight)
		   		}
	   		)

			tmp = getCanvasTable("_tmp")
		end

		love.graphics.push()
		love.graphics.origin()
		for i = 1, #shaders do
			inputCanvas = i % 2 == 1 and canvas or tmp.canvas
			outputCanvas = i % 2 == 0 and canvas or tmp.canvas
			love.graphics.setCanvas(outputCanvas)
			love.graphics.clear()
			love.graphics.setShader(shaders[i])
			love.graphics.draw(inputCanvas)
			love.graphics.setCanvas(inputCanvas)
		end
		love.graphics.pop()

		love.graphics.setCanvas(canvas)
		love.graphics.draw(outputCanvas)
	end

	love.graphics.setShader(shader)
end

local function finish(shader)
	if settings.canvas then
		local render = getCanvasTable("_render")

		love.graphics.pop()

		-- Draw canvas
		love.graphics.setCanvas(render.canvas)
		-- Do not draw render yet
		for i = 1, #canvases do
			local canvasTable = canvases[i]

			if not canvasTable.private then
				local shader = canvasTable.shader

				applyShaders(canvasTable.canvas, type(shader) == "table" and shader or {shader})
			end
		end
		love.graphics.setCanvas()

		-- Now draw render
		love.graphics.translate(offset.x, offset.y)
		love.graphics.push()
		love.graphics.scale(scale.x, scale.y)
		do
			local shader = shader or render.shader

			applyShaders(render.canvas, type(shader) == "table" and shader or {shader})
		end
		love.graphics.pop()

		-- Clear canvas
		for i = 1, #canvases do
			love.graphics.setCanvas(canvases[i].canvas)
			love.graphics.clear()
		end

		love.graphics.setCanvas()
		love.graphics.setShader()
	else
		love.graphics.pop()
		love.graphics.setScissor()
	end
end

return {
	setupScreen = function(width, height, settingsTable)
		pushWidth, pushHeight = width, height
		windowWidth, windowHeight = love.graphics.getDimensions()

		settings = settingsTable

		initValues()

		if settings.canvas then
			setupCanvas({"default"})
		end
	end,

	setupCanvas = setupCanvas,
	setCanvas = function(name)
		local canvasTable

		if not settings.canvas then return true end

		canvasTable = getCanvasTable(name)
		return love.graphics.setCanvas({canvasTable.canvas, stencil = canvasTable.stencil})
	end,
	setShader = function(name, shader)
		if not shader then
			getCanvasTable("_render").shader = name
		else
			getCanvasTable(name).shader = shader
		end
	end,

	updateSettings = function(settingsTable)
		settings.upscale = settingsTable.upscale or settings.upscale
		settings.canvas = settingsTable.canvas or settings.canvas
	end,

	toGame = function(x, y)
		local normalX, normalY

		x, y = x - offset.x, y - offset.y
		normalX, normalY = x / drawWidth, y / drawHeight

		x = (x >= 0 and x <= pushWidth * scale.x) and math.floor(normalX * pushWidth) or false
		y = (y >= 0 and y <= pushHeight * scale.y) and math.floor(normalY * pushHeight) or false

		return x, y
	end,
	toReal = function(x, y)
		local realX = offset.x + (drawWidth * x) / pushWidth
		local realY = offset.y + (drawHeight * y)/ pushHeight

		return realX, realY
	end,

	start = start,
	finish = finish,

	resize = function(width, height)
		windowWidth, windowHeight = width, height

		initValues()
	end,

	getWidth = function() return pushWidth end,
	getHeight = function() return pushHeight end,
	getDimensions = function() return pushWidth, pushHeight end
}
