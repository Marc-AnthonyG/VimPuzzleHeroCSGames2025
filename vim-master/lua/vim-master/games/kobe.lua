local GameUtils = require('vim-master.game-utils')
local log = require('vim-master.log')

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
		"use v, w, p, y and f to yank the different 'balls' and paste them in the appropriate baskets.",
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
		south = positions[1],
		east = positions[2],
		center = positions[3],
		southeast = positions[4],
	}
	local expected = positions[1] .. positions[2] .. positions[3] .. positions[4]

	self.config = {
		basketArrangement = basketArrangement,
		expected = expected,
	}

	return self.config
end

function Kobe:render()
	local bracketBall = 'BracketBall'
	local curlyBall = 'CurlyBall'
	local doubleQuoteBall = 'DoubleQuoteBall'
	local singleQuoteBall = 'SingleQuoteBall'

	local lines = GameUtils.createEmpty(60)
	local cursorIdx = 1

	lines[2] = bracketBall
	lines[3] = curlyBall
	lines[4] = doubleQuoteBall
	lines[5] = singleQuoteBall

	lines[5] = string.rep(' ', 180) .. self.config.basketArrangement.east

	lines[20] = string.rep(' ', 90) .. self.config.basketArrangement.center

	lines[60] = self.config.basketArrangement.south .. string.rep(' ', 180) .. self.config.basketArrangement.southeast

	return lines, cursorIdx
end

function Kobe:checkForWin()
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
			'v - Enter visual mode',
			'w - Move to next word',
			'y - Yank (copy) selection',
			'p - Paste',
			'f - Find and move to character',
		},
	}
end

Kobe.keyset = {
	-- Basic movement
	h = true,
	j = true,
	k = true,
	l = true,
	g = true,

	-- Visual mode
	v = true,

	-- Word movement
	w = true,

	-- Yank and paste
	y = true,
	p = true,

	-- Text object operators
	i = true, -- inner text object
	a = true, -- around text object

	-- Text objects
	['['] = true, -- for bracket text objects
	[']'] = true,
	['{'] = true, -- for curly brace text objects
	['}'] = true,
	["'"] = true, -- for single quote text objects
	['"'] = true, -- for double quote text objects

	-- Find command
	f = true,
}

return Kobe
