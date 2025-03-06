local GameUtils = require('vim-master.game-utils')
local log = require('vim-master.log')

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
	log.info('NewWords', window)
	local round = {
		window = window,
	}

	self.__index = self
	return setmetatable(round, self)
end

function Words:getInstructionsSummary()
	return {
		'use w, b, 0, $ and d to delete the different word in the line. Be careful to only delete the different word!',
		'utilisez w, b, 0, $ et d pour supprimer le mot différent dans la ligne. Attention à ne supprimer que le mot différent !',
	}
end

function Words:setupGame()
	local one = GameUtils.getRandomWord()
	local temps = GameUtils.getRandomWord()
	while temps == one do
		temps = GameUtils.getRandomWord()
	end
	local two = temps:upper()
	local round = {}
	local expected = {}
	local idx = math.ceil(math.random() * 12)
	for i = 1, 12 do
		if i == idx then
			table.insert(round, two)
		else
			table.insert(round, one)
			table.insert(expected, one)
		end
	end

	self.config = {
		words = round,
		expected = table.concat(expected, ' '),
		default = table.concat(round, ' '),
	}

	return self.config
end

function Words:checkForWin()
	local lines = self.window.buffer:getGameLines()
	local trimmed = GameUtils.trimLines(lines)
	local concatenated = table.concat(GameUtils.filterEmptyLines(trimmed), '')
	local lowercased = concatenated:lower()

	local winner = lowercased == self.config.expected

	if winner then
		vim.cmd('stopinsert')
	end

	return winner
end

function Words:checkForLose()
	local lines = self.window.buffer:getGameLines()
	local trimmed = GameUtils.trimLines(lines)
	local concatenated = table.concat(GameUtils.filterEmptyLines(trimmed), '')

	local lost = concatenated ~= self.config.default and not self:checkForWin()

	if lost then
		vim.cmd('stopinsert')
	end

	return lost
end

function Words:render()
	local lines = GameUtils.createEmpty(5)
	local cursorIdx = 5

	local gameLine = table.concat(self.config.words, ' ')
	lines[5] = gameLine

	return lines, cursorIdx, math.floor(gameLine:len() / 2)
end

Words.flag = 'CSGAMES-WOW-YOU-ARE-SO-FAST'

Words.lostReason = 'You deleted the wrong word!'

Words.timeToWin = 12

---@return GameExplanation
function Words:getExplanation()
	return {
		title = 'Word Master Challenge',
		description = {
			"In this game, you'll be presented with a line of similar words.",
			'One word in the line is different from the others.',
			'Your task is to delete the different word using Vim motions.',

			'Dans ce jeu, une ligne de mots similaires vous sera présentée.',
			'Un mot dans la ligne est différent des autres.',
			'Votre tâche est de supprimer le mot différent en utilisant les mouvements Vim.',
		},
		examples = {
			"Example: If you see: 'bar bar foo bar bar bar'",
			"You need to delete 'foo' using commands like 'w' to move and 'dw' to delete",

			"Exemple: Si vous voyez: 'bar bar foo bar bar bar'",
			"Vous devez supprimer 'foo' en utilisant des commandes comme 'w' pour se déplacer et 'dw' pour supprimer",
		},
		controls = {
			'w - Move to next word',
			'b - Move to previous word',
			'0 - Move to start of line',
			'$ - Move to end of line',
			'dw - Delete word',

			'w - Aller au mot suivant',
			'b - Aller au mot précédent',
			'0 - Aller au début de la ligne',
			'$ - Aller à la fin de la ligne',
			'dw - Supprimer le mot',
		},
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
