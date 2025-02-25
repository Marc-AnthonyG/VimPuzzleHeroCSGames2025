local GameUtils = require('vim-master.game-utils')
local log = require('vim-master.log')

local wrapWithBrackets

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
	local expected = string.rep('&', 20)
		.. wrapWithBrackets(positions[1])
		.. string.rep('|', 20)
		.. wrapWithBrackets(positions[2])
		.. string.rep('_', 20)
		.. wrapWithBrackets(positions[3])
		.. string.rep('|', 20)
		.. wrapWithBrackets(positions[4])

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

	lines[6] = string.rep(' & ', 20)
		.. self.config.basketArrangement.first:lower()
		.. string.rep(' | ', 20)
		.. self.config.basketArrangement.second:lower()
		.. string.rep(' _ ', 20)
		.. self.config.basketArrangement.third:lower()
		.. string.rep(' | ', 20)
		.. self.config.basketArrangement.fourth:lower()
	return lines, cursorIdx
end

function Kobe:checkForWin()
	log.info('Checking for win')
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

	-- Yank and paste
	d = true,
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
	g = true,
}

function wrapWithBrackets(ball)
	if ball == 'BracketBall' then
		return '[' .. ball .. ']'
	end
	if ball == 'CurlyBall' then
		return '{' .. ball .. '}'
	end
	if ball == 'DoubleQuoteBall' then
		return '"' .. ball .. '"'
	end
	if ball == 'SingleQuoteBall' then
		return "'" .. ball .. "'"
	end
	return ball
end

return Kobe
