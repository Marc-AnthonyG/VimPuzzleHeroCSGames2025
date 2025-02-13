local bind = require("vim-master.bind")
local log = require("vim-master.log")

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

---Creates a new Buffer instance
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
    if vim.api.nvim_buf_detach then
        vim.api.nvim_buf_detach(self.bufh)
    end
end

function Buffer:_scheduledOnLine()
    if self == nil or self.onChangeList == nil then
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
    local instructionLen = #self.instructions
    local currentLen = #self.lastRenderedInstruction + 1 + (#self.lastRendered or 0)

    -- Clear entire buffer first
    vim.api.nvim_buf_set_lines(self.bufh, 0, currentLen, false, {})

    self.lastRendered = lines
    local idx = 0

    -- Add debug line if it exists
    if self.debugLineStr ~= nil then
        vim.api.nvim_buf_set_lines(self.bufh, idx, idx + 1, false, { self.debugLineStr })
        idx = idx + 1
    end

    -- Add instructions if they exist
    if instructionLen > 0 then
        vim.api.nvim_buf_set_lines(self.bufh, idx, idx + instructionLen, false, self.instructions)
        idx = idx + instructionLen
    end

    -- Add the new lines
    if #lines > 0 then
        vim.api.nvim_buf_set_lines(self.bufh, idx, idx + #lines, false, lines)
    end
end

function Buffer:renderInstructions()
    local instructionLen = #self.instructions
    if instructionLen > 0 then
        -- Clear existing instructions first
        vim.api.nvim_buf_set_lines(self.bufh, 1, 1 + #self.lastRenderedInstruction, false, {})
        -- Add new instructions
        vim.api.nvim_buf_set_lines(self.bufh, 1, 1 + instructionLen, false, self.instructions)
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

    -- Delete game lines instead of replacing with empty strings
    vim.api.nvim_buf_set_lines(self.bufh, startOffset, startOffset + len, false, {})
end

function Buffer:getGameLines()
    local startOffset = #self.instructions + 1
    local len = #self.lastRendered

    return vim.api.nvim_buf_get_lines(self.bufh, startOffset, startOffset + len, false)
end

function Buffer:clear()
    local currentLen = #self.lastRenderedInstruction + 1 + (#self.lastRendered or 0)

    self.instructions = {}
    self.debugLineStr = nil
    self.lastRendered = {}
    self.lastRenderedInstruction = {}

    -- Delete all lines instead of replacing with empty strings
    vim.api.nvim_buf_set_lines(self.bufh, 0, currentLen, false, {})
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
