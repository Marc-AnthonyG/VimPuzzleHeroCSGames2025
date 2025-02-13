local GameUtils = require("vim-master.game-utils")
local log = require("vim-master.log")

---@class WordConfig
---@field roundTime number
---@field words string[]
---@field expected string

---@class Words: Game
local Words = {}

---Creates a new Words game instance
---@param window Window
---@return Game
function Words:new(window)
	log.info("NewWords", window)
	local round = {
		window = window,
	}

	self.__index = self
	return setmetatable(round, self)
end

function Words:getInstructionsSummary()
	return { "use w, b, 0, $ and d to delete the different word in the line. Be careful to only delete the different word!" }
end

function Words:setupGame()
	local one = GameUtils.getRandomWord()
	local two = GameUtils.getRandomWord()
	while (two == one)
	do
		two = GameUtils.getRandomWord()
	end
	local round = {}
	local expected = {}
	local idx = math.ceil(math.random() * 20);
	for i = 1, 20 do
		if i == idx then
			table.insert(round, two);
		else
			table.insert(round, one);
			table.insert(expected, one);
		end
	end

	self.config = {
		words = round,
		expected = table.concat(expected, " "),
		default = table.concat(round, " ")
	}

	return self.config
end

function Words:checkForWin()
	local lines = self.window.buffer:getGameLines()
	local trimmed = GameUtils.trimLines(lines)
	local concatenated = table.concat(GameUtils.filterEmptyLines(trimmed), "")
	local lowercased = concatenated:lower()

	local winner = lowercased == self.config.expected

	if winner then
		vim.cmd("stopinsert")
	end

	return winner
end

function Words:checkForLose()
	local lines = self.window.buffer:getGameLines()
	local trimmed = GameUtils.trimLines(lines)
	local concatenated = table.concat(GameUtils.filterEmptyLines(trimmed), "")
	local lowercased = concatenated:lower()

	local lost = lowercased ~= self.config.default and not self:checkForWin()

	if lost then
		vim.cmd("stopinsert")
	end

	return lost
end

function Words:render()
	local lines = GameUtils.createEmpty(5)
	local cursorIdx = 5

	lines[5] = table.concat(self.config.words, " ")

	return lines, cursorIdx
end

Words.flag = "CSGAMES-d542d95c58b0048295422b46cf0a4a93"

Words.lostReason = "You deleted the wrong word!"

Words.timeToWin = 20

---@return GameExplanation
function Words:getExplanation()
	return {
		title = "Word Master Challenge",
		description = {
			"In this game, you'll be presented with a line of similar words.",
			"One word in the line is different from the others.",
			"Your task is to delete the different word using Vim motions.",
		},
		examples = {
			"Example: If you see: 'bar bar foo bar bar bar'",
			"You need to delete 'foo' using commands like 'w' to move and 'dw' to delete",
		},
		controls = {
			"w - Move to next word",
			"b - Move to previous word",
			"0 - Move to start of line",
			"$ - Move to end of line",
			"dw - Delete word",
		}
	}
end

Words.keyset = {
	-- Basic movement
	h = true,
	j = true,
	k = true,
	l = true,
	-- Word movement
	w = true,
	b = true,
	-- Shifted word movement
	W = true, -- Move forward by WORD
	B = true, -- Move backward by WORD
	-- Line movement
	['0'] = true,
	['$'] = true,
	I = true,
	A = true,
	-- Deletion
	d = true,
	D = true, -- Delete to end of line
	-- Numbers for repeat operations
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

return Words
