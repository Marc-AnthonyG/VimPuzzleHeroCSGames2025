local GameRunner = require('vim-master.game-runner')
local Menu = require('vim-master.menu')
local WindowHandler = require('vim-master.window')
local log = require('vim-master.log')

math.randomseed(os.time())

local windowHandler

local function onVimResize()
	if windowHandler then
		if not windowHandler:onResize() then
			windowHandler = nil
		end
	end
end

local function menu()
	log.info('------------------ STARTING THE GAME -----------------------------')
	local endItAll = nil
	local hasEverythingEnded = false

	local menuItem
	local gameRunner
	windowHandler = WindowHandler:new()
	windowHandler:show()

	endItAll = function()
		if hasEverythingEnded then
			return
		end

		log.info('endItAll', debug.traceback())
		hasEverythingEnded = true

		if windowHandler then
			windowHandler:close()
			windowHandler = nil
		end
		if menuItem ~= nil then
			menuItem:close()
			menuItem = nil
		end

		if gameRunner ~= nil then
			gameRunner:close()
			gameRunner = nil
		end
	end

	local onGameFinish
	local onMenuSelect

	local function createMenu()
		menuItem = Menu:new(windowHandler, onMenuSelect)
		menuItem:render()
	end

	onGameFinish = function(gameString, game, nextState)
		log.info('Ending it from the game baby!', nextState)

		vim.schedule(function()
			if nextState == 'menu' then
				game:close()
				windowHandler.buffer:clear()
				vim.schedule(function()
					createMenu()
				end)
			elseif nextState == 'replay' then
				game:close()
				onMenuSelect(gameString)
			else
				endItAll()
			end
		end)
	end

	onMenuSelect = function(gameString)
		menuItem:close()

		log.info('onResults', gameString)
		local gameRunnerItem = GameRunner:new({ gameString }, windowHandler, function(game, nextState)
			onGameFinish(gameString, game, nextState)
		end)

		local ok, msg = pcall(function()
			gameRunnerItem:init()
		end, debug.traceback)
		if not ok then
			log.info('Error: Menu:new callback', msg)
		end
	end

	createMenu()
end

return {
	menu = menu,
	onVimResize = onVimResize,
}
