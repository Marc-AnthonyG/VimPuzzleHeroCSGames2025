local GameUtils = require("vim-master.game-utils")
local log = require("vim-master.log")

---@class HjklConfig
---@field roundTime number
---@field words string[]
---@field expected string

---@class Hjkl: Game
local Hjkl = {}

---Creates a new Words game instance
---@param window Window
---@return Game
function Hjkl:new(window)
	log.info("New", window)
	local round = {
		window = window,
	}

	self.__index = self
	return setmetatable(round, self)
end

function Hjkl:getInstructionsSummary()
	return { "Use h,j,k,l and d to delete the X! Tips: number are authorized too!" }
end

function Hjkl:setupGame()
end

function Hjkl:checkForWin()
	local lines = self.window.buffer:getGameLines()
	local found = false
	local idx = 1

	while idx <= #lines and not found do
		local line = lines[idx]
		found = string.match(line, "x")

		idx = idx + 1
	end
	log.info("HjklRound:checkForWin(", idx, "): ", found)

	return not found
end

function Hjkl:checkForLose()
	return false
end

function Hjkl:render()
	local boardSize = 8
	local lines = GameUtils.createEmpty(boardSize)

	local xCol = 1
	local xLine = 1
	local cursorCol = 1
	local cursorLine = 1

	while (xLine == cursorLine or xCol == cursorCol) do
		xCol = math.random(1, boardSize)
		xLine = math.random(1, boardSize)
		cursorCol = math.random(1, boardSize)
		cursorLine = math.random(1, boardSize)
	end

	log.info("HjklRound:render      xLine: ", xLine, "      xCol: ", xCol)
	log.info("HjklRound:render cursorLine: ", cursorLine, " cursorCol: ", cursorCol)

	local idx = 1
	while idx <= #lines do
		local line = lines[idx]
		for i = 1, boardSize, 1
		do
			if xLine == idx and xCol == i then
				line = line .. "x"
			else
				line = line .. " "
			end
		end
		lines[idx] = line
		idx = idx + 1
	end

	return lines, cursorLine, cursorCol
end

Hjkl.flag = "CSGAMES-YAY-YOU-KNOW-HOW-TO-NOT-USE-ARROW"

Hjkl.lostReason = ""

Hjkl.timeToWin = 20

---@return GameExplanation
function Hjkl:getExplanation()
	return {
		title = "HJKL Master Challenge",
		description = {
			"In this game, you'll be presented with a grid with an X somewhere",
			"Your task is to move the cursor to the X using the HJKL keys",
			"Then you can use the 'd' key with hjkl to delete the x",
		},
		controls = {
			"Use h, j, k, l to move the cursor",
			"Use d to delete the X",
		}
	}
end

Hjkl.keyset = {
	-- Basic movement
	h = true,
	j = true,
	k = true,
	l = true,
	d = true,
	D = true,
	['1'] = true,
	['2'] = true,
	['3'] = true,
	['4'] = true,
	['5'] = true,
	['6'] = true,
	['7'] = true,
	['8'] = true,
	['9'] = true,
}

return Hjkl
