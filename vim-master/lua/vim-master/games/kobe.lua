local GameUtils = require('vim-master.game-utils')
local log = require('vim-master.log')

local putBallInBasket
local getBallAssociatedWithBasket

---@class KobeConfig
---@field roundTime number
---@field words string[]
---@field baskets string[]
---@field expected string

---@class Kobe: Game
local Kobe = {}

---Creates a new Kobe game instance
---@param window Window
---@return Game
---
function Kobe:new(window)
	log.info('NewKobeGame', window)
	local round = {
		window = window,
	}

	self.__index = self
	return setmetatable(round, self)
end

function Kobe:getInstructionsSummary()
	return {
		"use b, w, p, d and f to cut the different 'balls' and paste them in the appropriate baskets.",
	}
end

function Kobe:setupGame()
	local bracketBasket = '[]'
	local curlyBasket = '{}'
	local doubleQuoteBasket = '""'
	local singleQuoteBasket = "''"

	--  idx 1 = south; 2 = east; 3 = center; 4 = southeast
	local positions = { bracketBasket, curlyBasket, doubleQuoteBasket, singleQuoteBasket }
	GameUtils.shuffle(positions)

	local basketArrangement = {
		first = positions[1],
		second = positions[2],
		third = positions[3],
		fourth = positions[4],
	}
	local expected = string.rep('& ', 20)
		.. putBallInBasket(positions[1])
		.. string.rep(' | ', 20)
		.. putBallInBasket(positions[2])
		.. string.rep(' _ ', 20)
		.. putBallInBasket(positions[3])
		.. string.rep(' | ', 20)
		.. putBallInBasket(positions[4])

	self.config = {
		basketArrangement = basketArrangement,
		expected = expected,
	}

	return self.config
end

function Kobe:render()
	local lines = GameUtils.createEmpty(30)
	local cursorIdx = 1

	lines[2] = getBallAssociatedWithBasket(self.config.basketArrangement.first)
	lines[3] = getBallAssociatedWithBasket(self.config.basketArrangement.third)
	lines[4] = getBallAssociatedWithBasket(self.config.basketArrangement.fourth)
	lines[5] = getBallAssociatedWithBasket(self.config.basketArrangement.second)

	lines[7] = string.rep('& ', 20)
		.. self.config.basketArrangement.first
		.. string.rep(' | ', 20)
		.. self.config.basketArrangement.second
		.. string.rep(' _ ', 20)
		.. self.config.basketArrangement.third
		.. string.rep(' | ', 20)
		.. self.config.basketArrangement.fourth
	return lines, cursorIdx
end

function Kobe:checkForWin()
	local lines = self.window.buffer:getGameLines()
	local trimmed = GameUtils.trimLines(lines)
	local concatenated = table.concat(GameUtils.filterEmptyLines(trimmed), '')

	local winner = concatenated == self.config.expected

	if winner then
		vim.cmd('stopinsert')
	end

	return winner
end

function Kobe:checkForLose()
	return false
end

Kobe.flag = 'CSGAMES-d542d95c58b0048295422b46cf0a4a93'

Kobe.lostReason = ''

Kobe.timeToWin = 20

---@return GameExplanation
function Kobe:getExplanation()
	return {
		title = 'Kobe Challenge',
		description = {
			"In this game, you'll be presented with different 'balls' that need to be placed in matching baskets.",
			'Each ball type (Bracket, Curly, DoubleQuote, SingleQuote) must be moved to its corresponding basket.',
			'Use your Vim skills to yank and paste the balls into their proper positions.',
		},
		controls = {
			'w - Move to end of word',
			'b - Move to previous word',
			'd - Cut',
			'p - Paste',
			'f - Find and move to character',
		},
	}
end

Kobe.keyset = {
	-- Basic movement
	j = true,
	k = true,

	-- Word movement
	w = true,
	b = true,

	-- Cut and paste
	d = true,
	p = true,

	-- Text object operators
	i = true,
	a = true,

	-- Text objects
	['['] = true,
	[']'] = true,
	['{'] = true,
	['}'] = true,
	["'"] = true,
	['"'] = true,

	-- Find command
	f = true,
}

function putBallInBasket(basket)
	if basket == '[]' then
		return '[BracketBall]'
	end
	if basket == '{}' then
		return '{CurlyBall}'
	end
	if basket == '""' then
		return '"DoubleQuoteBall"'
	end
	if basket == "''" then
		return "'SingleQuoteBall'"
	end
end

function getBallAssociatedWithBasket(basket)
	if basket == '[]' then
		return 'BracketBall'
	end
	if basket == '{}' then
		return 'CurlyBall'
	end
	if basket == '""' then
		return 'DoubleQuoteBall'
	end
	if basket == "''" then
		return 'SingleQuoteBall'
	end
end
return Kobe
