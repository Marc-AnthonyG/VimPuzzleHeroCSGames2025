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
        return { "Delete the entire code block that contains '// DELETE THIS'" }
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
                        
                        -- Don't add this block to expected
                        table.insert(expected, "")
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

Blocks.lostReason = "You deleted too much or too little! Delete exactly the block containing '// DELETE THIS'"

Blocks.timeToWin = 20

---@return GameExplanation
function Blocks:getExplanation()
        return {
                title = "Code Block Deletion Challenge",
                description = {
                        "In this game, you'll see a function with multiple code blocks.",
                        "One line inside a code block is marked with '// DELETE THIS'.",
                        "Your task is to delete the entire code block containing that line.",
                        "A code block is a contiguous group of lines separated by empty lines.",
                },
                examples = {
                        "Example: If you see:",
                        "    // Code line 1",
                        "    // Code line 2 // DELETE THIS",
                        "    // Code line 3",
                        "",
                        "You need to delete all three lines of that block.",
                },
                controls = {
                        "Use any Vim commands you want! All keys are allowed.",
                        "Hint: Visual mode (v) and deletion (d) work well together.",
                        "Hint: { and } move between paragraphs (blocks of text).",
                }
        }
end

-- No keyset means all keys are allowed
Blocks.keyset = nil

return Blocks