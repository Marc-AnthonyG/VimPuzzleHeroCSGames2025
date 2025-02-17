local GameUtils = require("vim-master.game-utils")
local log = require("vim-master.log")

---@class BlocksConfig
---@field lines string[]
---@field expected string[]

---@class Blocks: Game
local Blocks = {}

---Creates a new Blocks game instance
---@param window Window
---@return Game
function Blocks:new(window)
        log.info("NewBlocks", window)
        local round = {
                window = window,
        }

        self.__index = self
        return setmetatable(round, self)
end

function Blocks:getInstructionsSummary()
        return { "Use Vim motions to delete exactly the line marked with '// DELETE THIS' inside a code block" }
end

local function generateCodeBlock(size)
        local block = {}
        for i = 1, size do
                table.insert(block, "    // Code line " .. i)
        end
        return block
end

function Blocks:setupGame()
        local lines = {
                "local function example() {",
        }
        
        -- Generate 3-4 code blocks
        local numBlocks = math.random(3, 4)
        local targetBlock = math.random(1, numBlocks)
        local targetLine
        local expected = {}
        
        for i = 1, numBlocks do
                -- Add empty line before block
                table.insert(lines, "")
                
                -- Generate block with 3-5 lines
                local blockSize = math.random(3, 5)
                local block = generateCodeBlock(blockSize)
                
                -- If this is the target block, mark a random line
                if i == targetBlock then
                        local lineToMark = math.random(1, #block)
                        block[lineToMark] = block[lineToMark] .. " // DELETE THIS"
                        targetLine = block[lineToMark]
                        
                        -- Add all lines except the target to expected
                        for j = 1, #block do
                                if j ~= lineToMark then
                                    table.insert(expected, block[j])
                                end
                        end
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
        table.insert(lines, "")
        table.insert(lines, "}")
        table.insert(expected, "")
        table.insert(expected, "}")

        self.config = {
                lines = lines,
                expected = expected
        }

        return self.config
end

function Blocks:checkForWin()
        local lines = self.window.buffer:getGameLines()
        local trimmed = GameUtils.trimLines(lines)
        local expected = GameUtils.trimLines(self.config.expected)
        
        local winner = #trimmed == #expected
        if winner then
                for i = 1, #trimmed do
                        if trimmed[i] ~= expected[i] then
                                winner = false
                                break
                        end
                end
        end

        if winner then
                vim.cmd("stopinsert")
        end

        return winner
end

function Blocks:checkForLose()
        local lines = self.window.buffer:getGameLines()
        local trimmed = GameUtils.trimLines(lines)
        
        -- Lost if content changed but not correct
        local lost = #trimmed ~= #self.config.lines and not self:checkForWin()

        if lost then
                vim.cmd("stopinsert")
        end

        return lost
end

function Blocks:render()
        return self.config.lines, 2
end

Blocks.flag = "CSGAMES-BLOCK-DELETION-MASTER"

Blocks.lostReason = "You deleted too much or too little! Delete exactly the marked line."

Blocks.timeToWin = 20

---@return GameExplanation
function Blocks:getExplanation()
        return {
                title = "Code Block Deletion Challenge",
                description = {
                        "In this game, you'll see a function with multiple code blocks.",
                        "One line inside a code block is marked with '// DELETE THIS'.",
                        "Your task is to delete exactly that line using Vim motions.",
                },
                examples = {
                        "Example: If you see a line '    // Code line 2 // DELETE THIS'",
                        "You need to delete exactly that line, no more, no less.",
                },
                controls = {
                        "j/k - Move up/down",
                        "0 - Move to start of line",
                        "$ - Move to end of line",
                        "dd - Delete current line",
                }
        }
end

Blocks.keyset = {
        -- Basic movement
        h = true,
        j = true,
        k = true,
        l = true,
        -- Line movement
        ['0'] = true,
        ['$'] = true,
        -- Deletion
        d = true,
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

return Blocks