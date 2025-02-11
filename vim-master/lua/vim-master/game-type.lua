---@class Game
---@field getInstructionsSummary fun(): string[]
---@field getExplanation fun(): GameExplanation
---@field getConfig fun(): table
---@field checkForWin fun(): boolean
---@field checkForLose fun(): boolean
---@field render fun(): string[], number, number?
---@field close fun()?
---@field flag string
---@field window Window
---@field timeToWin number


---@class GameExplanation
---@field title string
---@field description string[]
---@field examples string[]
---@field controls string[]

return {}
