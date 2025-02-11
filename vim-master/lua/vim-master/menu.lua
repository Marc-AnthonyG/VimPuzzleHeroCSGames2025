local log = require("vim-master.log")
local bind = require("vim-master.bind")
local types = require("vim-master.types")

local Menu = {}

local gameHeader = {
    "",
    "Select a Game (delete from the list to select)",
    "----------------------------------------------",
}

local instructions = {
    "Welcome to Vim Master Challenge. This challenges is a collection",
    "of small games intended to see if you are truly a vim master!",
    "When completing a mini-game you will receive a flag.",
    "To start a mini-game, delete the line of the game (Vd in normal mode)",
    "If at any point the game or the page glitch you can refresh the page to start a new session",
}

local credits = {
    "",
    "",
    "This challenges is conceive from the awsome plugin VimBeGood created by ThePrimeagen",
    "https://github.com/ThePrimeagen/vim-master",
    "",
    ""
}

function Menu:new(window, onResults)
    local menuObj = {
        window = window,
        buffer = window.buffer,
        onResults = onResults,
        game = types.games[1],
    }

    window.buffer:clear()
    window.buffer:setInstructions(instructions)

    self.__index = self
    local createdMenu = setmetatable(menuObj, self)

    createdMenu._onChange = bind(createdMenu, "onChange")
    window.buffer:onChange(createdMenu._onChange)

    return createdMenu
end

local function getMenuLength()
    return #types.games + #gameHeader + #credits
end

local function getTableChanges(lines, compareSet, startIdx)
    local maxCount = #lines
    local idx = startIdx
    local i = 1
    local found = false

    while found == false and idx <= maxCount and i <= #compareSet do
        if lines[idx] == nil or lines[idx]:find(compareSet[i], 1, true) == nil then
            found = true
        else
            i = i + 1
            idx = idx + 1
        end
    end

    return found, i, idx
end

function Menu:onChange()
    local lines = self.window.buffer:getGameLines()
    local maxCount = getMenuLength()

    if #lines == maxCount then
        return
    end

    local found, i, idx = getTableChanges(lines, gameHeader, 1)
    log.info("Menu:onChange initial instructions", found, i, idx)
    --- If menu change rerender
    if found then
        self:render()
        return
    end

    found, i, idx = getTableChanges(lines, types.games, idx)
    log.info("Menu:onChange game changes", found, i, idx)
    if found then
        self.game = types.games[i]

        log.info("Starting Game", self.game)
        local ok, msg = pcall(self.onResults, self.game)

        if not ok then
            log.info("Menu:onChange error", msg)
        end
        return
    end
end

local function createMenuItem(str, currentValue)
    if currentValue == str then
        return "[x] " .. str
    end
    return "[ ] " .. str
end

function Menu:render()
    self.window.buffer:clearGameLines()

    local lines = {}
    for idx = 1, #gameHeader do
        table.insert(lines, gameHeader[idx])
    end

    for idx = 1, #types.games do
        table.insert(lines, createMenuItem(types.games[idx], self.game))
    end

    for idx = 1, #credits do
        table.insert(lines, credits[idx])
    end

    self.window.buffer:render(lines)
end

function Menu:close()
    self.buffer:removeListener(self._onChange)
end

return Menu
