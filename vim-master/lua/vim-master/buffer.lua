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
    local idx = 1
    local instructionLen = #self.instructions

    self:clear()
    self.lastRendered = lines

    if self.debugLineStr ~= nil then
        vim.api.nvim_buf_set_lines(
            self.bufh, 0, 1, false, { self.debugLineStr })
    end

    if instructionLen > 0 then
        vim.api.nvim_buf_set_lines(
            self.bufh, idx, idx + instructionLen, false, self.instructions)
        idx = idx + instructionLen
    end

    log.trace("Buffer:Rendering")
    vim.api.nvim_buf_set_lines(self.bufh, idx, idx + #lines, false, lines)
end

function Buffer:renderInstructions()
    local instructionLen = #self.instructions
    if instructionLen > 0 then
        vim.api.nvim_buf_set_lines(
            self.bufh, 1, 1 + instructionLen, false, self.instructions)
    end
end

function Buffer:debugLine(line)
    if line ~= nil then
        self.debugLineStr = line
    end
end

---Sets the new lines you want to display in the buffer
---@param lines string[]
function Buffer:setInstructions(lines)
    self.lastRenderedInstruction = self.instructions
    self.instructions = lines
end

function Buffer:clearGameLines()
    local startOffset = #self.instructions + 1
    local len = #self.lastRendered

    vim.api.nvim_buf_set_lines(
        self.bufh, startOffset, startOffset + len, false, createEmpty(len))
end

function Buffer:getGameLines()
    local startOffset = #self.instructions + 1
    local len = #self.lastRendered

    local lines = vim.api.nvim_buf_get_lines(
        self.bufh, startOffset, startOffset + len, false)

    log.trace("Buffer:getGameLines", startOffset, len, vim.inspect(lines))

    return lines
end

function Buffer:clear()
    local len = #self.lastRenderedInstruction + 1 + (#self.lastRendered or 0)

    vim.api.nvim_buf_set_lines(
        self.bufh, 0, len, false, createEmpty(len))
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
