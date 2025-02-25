local GameUtils = require("vim-master.game-utils")
local log = require("vim-master.log")

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
	log.info("NewKobeGame", window)
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
	local bracketBasket = "[]"
	local curlyBasket = "{}"
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

	self.config = {
		basketArrangement = basketArrangement,
	}

	return self.config
end

function Kobe:render()
	local bracketBall = "BracketBall"
	local curlyBall = "CurlyBall"
	local doubleQuoteBall = "DoubleQuoteBall"
	local singleQuoteBall = "SingleQuoteBall"

	local lines = GameUtils.createEmpty(60)
	local cursorIdx = 1

	lines[1] = string.rep(" ", 180) .. self.config.basketArrangement.east

	lines[5] = bracketBall
	lines[6] = curlyBall
	lines[7] = doubleQuoteBall
	lines[8] = singleQuoteBall

	lines[20] = string.rep(" ", 90) .. self.config.basketArrangement.center

	lines[60] = self.config.basketArrangement.south .. string.rep(" ", 180) .. self.config.basketArrangement.southeast

	return lines, cursorIdx
end

function Kobe:checkForWin()
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

function Kobe:checkForLose()
	return false
end

Kobe.flag = "CSGAMES-d542d95c58b0048295422b46cf0a4a93"

Kobe.lostReason = ""

Kobe.timeToWin = 20

---@return GameExplanation
function Kobe:getExplanation()
	return {
		title = "Kobe Challenge",
		description = {
			"In this game, you'll be presented with a line of similar words.",
			"One word in the line is different from the others.",
			"Your task is to delete the different word using Vim motions.",
		},
		controls = {
			"v - Move to next word",
			"b - Move to previous word",
			"0 - Move to start of line",
			"$ - Move to end of line",
			"dw - Delete word",
		},
	}
end

Kobe.keyset = {
	-- Basic movement
	h = true,
	j = true,
	k = true,
	l = true,

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
	["["] = true, -- for bracket text objects
	["]"] = true,
	["{"] = true, -- for curly brace text objects
	["}"] = true,
	["'"] = true, -- for single quote text objects
	['"'] = true, -- for double quote text objects

	-- Find command
	f = true,
}

return Kobe
