local GameUtils = require("vim-be-good.game-utils")
local log = require("vim-be-good.log")

local instructions = {
    "Test your ability to hop by relative line numbers",
    "To win the game, delete the line that says \"DELETE_ME\"",
}

local RelativeRound = {}
function RelativeRound:new(window)
    log.info("New", window)
    local round = {
        window = window,
        fixedOffset = vim.g["vim_be_good_delete_me_fixed_offset"],
        randomOffset = 15,
    }

    self.__index = self
    return setmetatable(round, self)
end

function RelativeRound:getInstructions()
    return instructions
end

function RelativeRound:getConfig()
    return {
        roundTime = 10000
    }
end

function RelativeRound:checkForWin()
    local lines = self.window.buffer:getGameLines()
    local found = false
    local idx = 1

    while idx <= #lines and not found do
        local line = lines[idx]
        found = string.match(line, "DELETE_ME")

        idx = idx + 1
    end
    log.info("RelativeRound:checkForWin(", idx, "): ", found)

    return not found
end

function RelativeRound:render()
    local lines = GameUtils.createEmpty(20)
    local deleteMeIdx = math.random(1, 20)
    local goHigh = deleteMeIdx < 17 and math.random() > 0.5

    local cursorIdx
    if goHigh then
        cursorIdx = math.random(deleteMeIdx + 1, 20)
    else
        cursorIdx = math.random(1, deleteMeIdx - 1)
    end

    lines[deleteMeIdx] = " DELETE_ME"

    return lines, cursorIdx
end

function RelativeRound:name()
    return "relative"
end

return RelativeRound
