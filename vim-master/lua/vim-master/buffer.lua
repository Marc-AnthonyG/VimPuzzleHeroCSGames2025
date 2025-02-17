local bind = require("vim-master.bind")
local log = require("vim-master.log")

local function createEmpty(count)
    local lines = {}
    for idx = 1, count, 1 do
        lines[idx] = ""
    end

    return lines
end

---@class Buffer
---@field bufh number Buffer handle
---@field onChange function|nil Callback for buffer changes
---@field clear fun(self: Buffer) Clear the buffer
---@field getGameLines fun(self: Buffer): string[] Get the current game lines
---@field setInstructions fun(self: Buffer, lines: string[]) Set instruction lines
---@field renderInstructions fun(self: Buffer) Render instruction lines
---@field render fun(self: Buffer, lines: string[]) Render lines to buffer
---@field instructions string[] Instructions to display
local Buffer = {}

---Creates a new Words game instance
---@param bufh number
---@return Buffer
function Buffer:new(bufh)
    local onChangeList = {}
    local newBuf = {
        bufh = bufh,
        instructions = {},
        onChangeList = onChangeList,
        lastRendered = {},
        lastRenderedInstruction = {},
    }

    self.__index = self
    local createdObject = setmetatable(newBuf, self)

    createdObject:attach()
    return createdObject
end

function Buffer:close()
    self.onChangeList = {}
    -- TODO: Teejaay fix this

    if vim.api.nvim_buf_detach then
        vim.api.nvim_buf_detach(self.bufh)
    end
end

function Buffer:_scheduledOnLine()
    if self == nil or self.onChangeList == nil then
        ---@diagnostic disable-next-line: need-check-nil
        return
    end

    for _, fn in ipairs(self.onChangeList) do
        local ok, errMessage = pcall(
            fn, buf, changedtick, firstline, lastline, linedata, more)

        if not ok then
            log.info("Buffer:_scheduledOnLine: is not ok", errMessage)
            ok, errMessage = pcall(function()
                self:close()
            end)

            if not ok then
                log.info("AGAIN?????????", errMessage)
            end
        end
    end
end

function Buffer:onLine()
    vim.schedule(function()
        self:_scheduledOnLine()
    end)
end

function Buffer:attach()
    vim.api.nvim_buf_attach(self.bufh, true, {
        on_lines = bind(self, "onLine")
    })
end

function Buffer:render(lines)
    self.lastRendered = lines

    -- Clear buffer content
    vim.api.nvim_buf_set_lines(self.bufh, 0, -1, false, {})

    if self.debugLineStr then
        vim.api.nvim_buf_set_lines(self.bufh, 0, 1, false, { self.debugLineStr })
    end

    local currentLine = 1
    if #self.instructions > 0 then
        self.lastRenderedInstruction = self.instructions
        vim.api.nvim_buf_set_lines(self.bufh, currentLine, currentLine + #self.instructions,
            false, self.instructions)
        currentLine = currentLine + #self.instructions
    end

    vim.api.nvim_buf_set_lines(self.bufh, currentLine, -1, false, lines)
end

function Buffer:renderInstructions()
    local oldLen = self.lastRenderedInstruction and #self.lastRenderedInstruction or 0

    vim.api.nvim_buf_set_lines(self.bufh, 1, 1 + oldLen, false, self.instructions)

    self.lastRenderedInstruction = self.instructions
end

function Buffer:debugLine(line)
    if line ~= nil then
        self.debugLineStr = line
    end
end

---Sets the new lines you want to display in the buffer
---@param lines string[]
function Buffer:setInstructions(lines)
    self.instructions = lines
end

function Buffer:clearGameLines()
    local startOffset = #self.instructions + 1

    vim.api.nvim_buf_set_lines(self.bufh, startOffset, -1, false, {})
end

function Buffer:getGameLines()
    local startOffset = #self.instructions + 1

    return vim.api.nvim_buf_get_lines(self.bufh, startOffset, -1, false)
end

function Buffer:clear()
    self.instructions = {}
    self.debugLineStr = nil
    self.lastRendered = {}
    self.lastRenderedInstruction = {}

    vim.api.nvim_buf_set_lines(self.bufh, 0, -1, false, {})
end

function Buffer:onChange(cb)
    table.insert(self.onChangeList, cb)
end

function Buffer:removeListener(cb)
    local idx = 1
    local found = false
    while idx <= #self.onChangeList and found == false do
        found = self.onChangeList[idx] == cb
        if found == false then
            idx = idx + 1
        end
    end

    if found then
        log.info("Buffer:removeListener removing listener")
        table.remove(self.onChangeList, idx)
    end
end

return Buffer
