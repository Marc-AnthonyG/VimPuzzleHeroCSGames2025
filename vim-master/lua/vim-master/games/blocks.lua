local GameUtils = require('vim-master.game-utils')
local log = require('vim-master.log')

---@class BlocksConfig
---@field lines string[]
---@field expected string[]

---@class Blocks: Game
local Blocks = {}

---Creates a new Blocks game instance
---@param window Window
---@return Game
function Blocks:new(window)
	log.info('NewBlocks', window)
	local round = {
		window = window,
	}

	self.__index = self
	return setmetatable(round, self)
end

function Blocks:getInstructionsSummary()
	return {
		"Delete the entire code block that contains '// DELETE THIS' -- Supprimez le bloc de code qui contient '// DELETE THIS'",
	}
end

local function generateCodeBlock(size)
	local block = {}
	for i = 1, size do
		table.insert(block, '    // Code line ' .. i)
	end
	return block
end

function Blocks:setupGame()
	local lines = {
		'local function example() {',
	}

	-- Generate 3-4 code blocks
	local numBlocks = math.random(3, 4)
	local targetBlock = math.random(1, numBlocks)
	local expected = { 'local function example() {' }
	local targetStart, targetEnd

	for i = 1, numBlocks do
		-- Add empty line before block
		table.insert(lines, '')
		table.insert(expected, '')

		-- Generate block with 3-5 lines
		local blockSize = math.random(3, 5)
		local block = generateCodeBlock(blockSize)

		-- If this is the target block, mark a random line
		if i == targetBlock then
			local lineToMark = math.random(1, #block)
			block[lineToMark] = block[lineToMark] .. ' // DELETE THIS'
			targetStart = #lines + 1
			targetEnd = #lines + #block
		else
			-- Add all lines to expected
			for _, line in ipairs(block) do
				table.insert(expected, line)
			end
		end

		-- Add block lines
		for _, line in ipairs(block) do
			table.insert(lines, line)
		end
	end

	-- Add closing brace
	table.insert(lines, '')
	table.insert(lines, '}')
	table.insert(expected, '')
	table.insert(expected, '}')

	self.config = {
		lines = lines,
		expected = expected,
		targetStart = targetStart,
		targetEnd = targetEnd,
	}

	return self.config
end

function Blocks:checkForWin()
	local lines = self.window.buffer:getGameLines()
	local trimmed = GameUtils.trimLines(lines)
	local expected = GameUtils.trimLines(self.config.expected)

	local winner = GameUtils.linesAreEqual(trimmed, expected)

	if winner then
		vim.cmd('stopinsert')
	end

	return winner
end

function Blocks:checkForLose()
	local lines = self.window.buffer:getGameLines()
	local trimmed = GameUtils.trimLines(lines)
	local originalLines = GameUtils.trimLines(self.config.lines)

	-- If nothing has changed or we've won, not a loss
	if GameUtils.linesAreEqual(trimmed, originalLines) or self:checkForWin() then
		return false
	end

	-- Check if we've modified anything outside the target block
	local targetStart = self.config.targetStart
	local targetEnd = self.config.targetEnd

	for i = 1, #originalLines do
		if i < targetStart or i > targetEnd then
			if trimmed[i] ~= originalLines[i] then
				vim.cmd('stopinsert')
				return true
			end
		end
	end

	-- If we get here, we've only modified the target block but haven't won yet
	return false
end

function Blocks:render()
	return self.config.lines, 2
end

Blocks.flag = 'CSGAMES-BLOCK-DELETION-MASTER'

Blocks.lostReason = "You deleted too much or too little! Delete exactly the block containing '// DELETE THIS'"

Blocks.timeToWin = 20

---@return GameExplanation
function Blocks:getExplanation()
	return {
		title = 'Code Block Deletion Challenge -- Défi de suppression de bloc de code',
		description = {
			"In this game, you'll see a function with multiple code blocks.",
			"One line inside a code block is marked with '// DELETE THIS'.",
			'Your task is to delete the entire code block containing that line.',
			'A code block is a contiguous group of lines separated by empty lines.',
			'',
			'Dans ce jeu, vous verrez une fonction avec plusieurs blocs de code.',
			"Une ligne dans un bloc de code est marquée avec '// DELETE THIS'.",
			'Votre tâche est de supprimer le bloc de code entier contenant cette ligne.',
			'Un bloc de code est un groupe de lignes contiguës séparées par des lignes vides.',
		},
		examples = {
			'Example: If you see: -- Exemple: Si vous voyez:',
			'    // Code line 1',
			'    // Code line 2 // DELETE THIS',
			'    // Code line 3',
			'',
			'You need to delete all three lines of that block.',
			'Vous devez supprimer les trois lignes de ce bloc.',
		},
		controls = {
			'Use any Vim commands you want! All keys are allowed.',
			'Hint: Visual mode (v) and deletion (d) work well together.',
			'Hint: { and } move between paragraphs (blocks of text).',
			'',
			'Utilisez les commandes Vim que vous voulez! Toutes les touches sont permises.',
			'Astuce: Le mode visuel (v) et la suppression (d) fonctionnent bien ensemble.',
			'Astuce: { et } permettent de se déplacer entre les paragraphes (blocs de texte).',
		},
	}
end

-- No keyset means all keys are allowed
Blocks.keyset = nil

return Blocks
