local GameUtils = require("vim-master.game-utils")
local WordRound = require("vim-master.games.words")
local Hjkl = require("vim-master.games.hjkl")
local Blocks = require("vim-master.games.blocks")
local log = require("vim-master.log")

local endStates = {
        menu = "Menu",
        replay = "Replay",
}

local states = {
        instruction = 0,
        playing = 1,
        gameEnd = 2,
}

local games = {
        words = function(window)
                return WordRound:new(window)
        end,
        hjkl = function(window)
                return Hjkl:new(window)
        end,
        blocks = function(window)
                return Blocks:new(window)
        end,
}

local gameInstructionAknowledged = "Delete this line to start the game"

---@class GameResult
---@field timings number[]

local runningId = 0

---@class GameRunner
---@field currentRound number
---@field rounds Game[]
---@field config table
---@field window Window
---@field onFinished function
---@field results GameResult
---@field state number
---@field round Game|nil
---@field running boolean
---@field startTime number
---@field ended boolean
---@field hasLost boolean
---@field onChange function
---@field listenerId string
local GameRunner = {}

local function getGame(game, window)
        log.info("getGame", game, window)
        return games[game](window)
end

function GameRunner:new(selectedGames, window, onFinished)
        local config = {
                roundCount = 10,
        }

        local rounds = {}
        log.info("GameRunner:new", vim.inspect(selectedGames))

        for idx = 1, #selectedGames do
                table.insert(rounds, getGame(selectedGames[idx], window))
        end

        local gameRunnerBase = {
                currentRound = 1,
                rounds = rounds,
                config = config,
                window = window,
                onFinished = onFinished,
                results = {
                        timings = {},
                },
                state = states.playing,
                hasLost = false,
        }

        self.__index = self
        local gameRunner = setmetatable(gameRunnerBase, self)

        local function onChange()
                if gameRunner.state == states.explanation then
                        if gameRunner:checkExplanationAcknowledged() then
                                gameRunner.state = states.playing
                                gameRunner:countdown(3, function()
                                        self.startTime = GameUtils.getTime()
                                        gameRunner:run()
                                end)
                        end
                elseif gameRunner.state == states.playing then
                        gameRunner:checkForWinOrLost()
                else
                        gameRunner:checkEndGameMenuSelection()
                end
        end

        gameRunner.onChange = onChange
        window.buffer:onChange(onChange)
        return gameRunner
end

function GameRunner:countdown(count, cb)
        local ok, msg = pcall(function()
                if count > 0 then
                        local str = string.format("Game Starts in %d", count)

                        self.window.buffer:debugLine(str)
                        self.window.buffer:render({})

                        vim.defer_fn(function()
                                self:countdown(count - 1, cb)
                        end, 1000)
                else
                        cb()
                end
        end)

        if not ok then
                log.info("Error: GameRunner#countdown", msg)
        end
end

function GameRunner:init()
        vim.schedule(function()
                if not self.round then
                        local idx = math.random(1, #self.rounds)
                        self.round = self.rounds[idx]
                end

                self.state = states.explanation
                self.window.buffer:setInstructions({})
                self.window.buffer:clear()
                self.window.buffer:render(self:renderExplanation())
        end)
end

---@return string[] lines Lines to display
function GameRunner:renderExplanation()
        if not self.round then
                return {}
        end

        local explanation = self.round:getExplanation()
        local lines = {}

        -- Add title
        table.insert(lines, string.rep("=", 60))
        table.insert(lines, string.format("Welcome to %s", explanation.title))
        table.insert(lines, string.rep("=", 60))
        table.insert(lines, "")

        -- Add description
        for _, line in ipairs(explanation.description) do
                table.insert(lines, line)
        end
        table.insert(lines, "")

        -- Add examples if they exist
        if explanation.examples and #explanation.examples > 0 then
                table.insert(lines, "Examples:")
                for _, example in ipairs(explanation.examples) do
                        table.insert(lines, example)
                end
                table.insert(lines, "")
        end

        -- Add controls
        table.insert(lines, "Controls:")
        for _, control in ipairs(explanation.controls) do
                table.insert(lines, control)
        end
        table.insert(lines, "")
        table.insert(lines, string.rep("-", 60))
        table.insert(lines, "")
        table.insert(lines, gameInstructionAknowledged)

        return lines
end

local function linesAreEqual(current, expected)
        if #current ~= #expected then
                return false
        end

        return table.concat(current, "\n") == table.concat(expected, "\n")
end

---@return boolean
function GameRunner:checkExplanationAcknowledged()
        log.info("GameRunner:checkExplanationAcknowledged")
        local lines = self.window.buffer:getGameLines()
        local expectedLines = self:renderExplanation()
        if linesAreEqual(lines, expectedLines) then
                return false
        end

        local stillHasAknowledged = false

        for _, line in ipairs(lines) do
                if line == gameInstructionAknowledged then
                        stillHasAknowledged = true
                        break
                end
        end

        if stillHasAknowledged then
                self.window.buffer:render(expectedLines)
        end

        return not stillHasAknowledged
end

function GameRunner:checkEndGameMenuSelection()
        log.info("GameRunner:checkForNext")
        local lines = self.window.buffer:getGameLines()
        local expectedLines = self:renderEndGame()

        if linesAreEqual(lines, expectedLines) then
                return
        end

        local foundStates = {}
        for _, line in ipairs(lines) do
                for stateKey, stateValue in pairs(endStates) do
                        if line == stateValue then
                                foundStates[stateKey] = true
                        end
                end
        end

        local missingCount = 0
        local lastMissingKey = nil

        for stateKey, _ in pairs(endStates) do
                if not foundStates[stateKey] then
                        missingCount = missingCount + 1
                        lastMissingKey = stateKey
                end
        end

        if missingCount == 1 then
                log.info("GameRunner:checkForNext: foundKey", lastMissingKey)
                self.onFinished(self, lastMissingKey)
        else
                log.info("GameRunner:checkForNext Some line was changed that is insignificant, rerendering")
                self.window.buffer:render(expectedLines)
        end
end

function GameRunner:checkForWinOrLost()
        if not self.round then
                return
        end

        if not self.running then
                return
        end

        if self.round:checkForLose() then
                self.hasLost = true
                self:endGame()
        end

        if self.round:checkForWin() then
                self:endRound()
        end
end

function GameRunner:endRound()
        self.running = false

        log.info("endRound", self.currentRound, self.config.roundCount)
        if self.currentRound >= self.config.roundCount then
                self:endGame()
                return
        end
        self.currentRound = self.currentRound + 1

        if not self.window:isValid() then
                return
        end

        vim.schedule_wrap(function()
                self:run()
        end)()
end

function GameRunner:close()
        log.info("GameRunner:close()", debug.traceback())
        vim.on_key(nil, self.listenerId)
        self.window.buffer:removeListener(self.onChange)
        self.window.buffer:clearGameLines()
        self.window.buffer:debugLine(nil)
        self.ended = true
end

function GameRunner:renderEndGame()
        self.window.buffer:debugLine(string.format("Round %d / %d", self.currentRound, self.config.roundCount))

        local lines = {}

        local endTime = GameUtils.getTime()
        local totalTime = endTime - self.startTime

        self.ended = true

        table.insert(lines, string.format("Time to complete %.2f", totalTime))

        if self.hasLost then
                table.insert(lines, string.format("You lost! %s", self.round.lostReason))
        elseif totalTime < self.round.timeToWin then
                table.insert(lines, string.format("Wow so fast here is the flag %s", self.round.flag))
        else
                table.insert(lines, string.format("You have to beat %s second to get my flag!", self.round.timeToWin))
        end

        for _ = 1, 3 do
                table.insert(lines, "")
        end

        table.insert(lines, "Where do you want to go next? (Delete Line)")
        local optionLine = #lines + 1

        table.insert(lines, endStates.menu)
        table.insert(lines, endStates.replay)
        table.insert(lines, endStates.quit)

        return lines, optionLine
end

function GameRunner:endGame()
        vim.on_key(nil, self.listenerId)
        local lines = self:renderEndGame()
        self.state = states.gameEnd
        self.window.buffer:setInstructions({})
        self.window.buffer:render(lines)
end

function GameRunner:run()
        local idx = math.random(1, #self.rounds)
        self.round = self.rounds[idx]
        self.round:setupGame()
        self:setupKeyRestrictions()

        self.window.buffer:debugLine(string.format("Round %d / %d", self.currentRound, self.config.roundCount))

        self.window.buffer:setInstructions(self.round.getInstructionsSummary())
        local lines, cursorLine, cursorCol = self.round:render()
        self.window.buffer:render(lines)

        cursorLine = cursorLine or 0
        cursorCol = cursorCol or 0

        local instuctionLen = #self.round.getInstructionsSummary()
        local curRoundLineLen = 1
        cursorLine = cursorLine + curRoundLineLen + instuctionLen

        log.info("Setting current line to", cursorLine, cursorCol)
        if cursorLine > 0 then
                vim.api.nvim_win_set_cursor(0, { cursorLine, cursorCol })
        end

        runningId = runningId + 1
        self.running = true
        self:timer()
end

function GameRunner:timer()
        local ok, msg = pcall(function()
                if not self.ended then
                        local endTime = GameUtils.getTime()
                        local totalTime = endTime - self.startTime

                        if not totalTime then
                                totalTime = 0
                        end

                        local str = string.format("Timer: %d", totalTime)

                        local lines = self.round.getInstructionsSummary()
                        vim.list_extend(lines, { str })

                        self.window.buffer:setInstructions(lines)
                        self.window.buffer:renderInstructions()

                        local gameRunner = self
                        vim.defer_fn(function()
                                if not gameRunner.ended then
                                        self:timer()
                                end
                        end, 1000)
                end
        end)

        if not ok then
                log.info("Error: GameRunner#countdown", msg)
        end
end

function GameRunner:setupKeyRestrictions()
        if not self.round.keyset then
                return
        end

        local currentRound = self.round
        local gameRunner = self

        self.listenerId = vim.on_key(function(key)
                log.info("GameRunner:setupKeyRestrictions", key)
                if currentRound.keyset and not currentRound.keyset[key] then
                        gameRunner.hasLost = true
                        gameRunner.round.lostReason = string.format("You pressed forbidden key: %s", key)
                        gameRunner:endGame()
                end
        end)

        log.info("GameRunner:setupKeyRestrictions", self.listenerId)
end

return GameRunner
