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
    log.trace("Menu:new")
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

local function areTablesEqual(t1, t2)
    if #t1 ~= #t2 then return false end
    for i = 1, #t1 do
        if t1[i] ~= t2[i] then return false end
    end
    return true
end

local function findGameInLine(line)
    for i, game in ipairs(types.games) do
        if line and line:find("- " .. game, 1, true) then
            return i, game
        end
    end
    return nil
end

local function getExpectedLines()
    local lines = {}
    for _, line in ipairs(gameHeader) do
        table.insert(lines, line)
    end
    for _, game in ipairs(types.games) do
        table.insert(lines, "- " .. game)
    end
    for _, line in ipairs(credits) do
        table.insert(lines, line)
    end
    return lines
end

function Menu:onChange()
    log.trace("Menu:onChange")
    local currentLines = self.window.buffer:getGameLines()
    local expectedLines = getExpectedLines()

    if areTablesEqual(currentLines, expectedLines) then
        log.trace("Menu:onChange - no changes needed")
        return
    end

    local missingGameIndex = nil
    local currentGameLines = {}

    for _, line in ipairs(currentLines) do
        local gameIndex = findGameInLine(line)
        if gameIndex then
            table.insert(currentGameLines, gameIndex)
        end
    end

    for i = 1, #types.games do
        local found = false
        for _, index in ipairs(currentGameLines) do
            if index == i then
                found = true
                break
            end
        end
        if not found then
            missingGameIndex = i
            break
        end
    end

    if missingGameIndex then
        self.game = types.games[missingGameIndex]
        log.info("Starting Game", self.game)
        local ok, msg = pcall(self.onResults, self.game)
        if not ok then
            log.info("Menu:onChange error", msg)
        end
        return
    end

    self:render()
end

function Menu:render()
    log.trace("Menu:render")
    self.window.buffer:clearGameLines()
    local lines = getExpectedLines()
    self.window.buffer:render(lines)
end

function Menu:close()
    log.trace("Menu:close")
    self.buffer:removeListener(self._onChange)
end

return Menu
