---@class Game
---@field getInstructionsSummary fun(): string[]
---@field getExplanation fun(): GameExplanation
---@field setupGame fun()
---@field checkForWin fun(): boolean
---@field checkForLose fun(): boolean
---@field render fun(): string[], number, number?
---@field flag string
---@field window Window
---@field timeToWin number
---@field lostReason string
---@field keyset table<string, boolean>


---@class GameExplanation
---@field title string
---@field description string[]
---@field examples string[]
---@field controls string[]

return {}
