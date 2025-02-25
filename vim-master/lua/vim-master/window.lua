local Buffer = require('vim-master.buffer')
local log = require('vim-master.log')

---@class Window
---@field buffer Buffer
---@field isValid fun(self: Window): boolean
---@field close fun(self: Window)
local WindowHandler = {}

local function generateConfig()
	local vimStats = vim.api.nvim_list_uis()[1]
	local w = vimStats.width
	local h = vimStats.height

	return {
		row = 0,
		col = 0,
		width = w,
		height = h,
		relative = 'editor',
	}
end

---Creates a new Window instance
---@return Window
function WindowHandler:new()
	local newWindow = {
		config = generateConfig(),
		rowPadding = 0,
		colPadding = 0,
		bufh = 0,
		buffer = nil,
		winId = 0,
	}

	self.__index = self
	return setmetatable(newWindow, self)
end

function WindowHandler:close()
	if self.winId ~= 0 then
		vim.api.nvim_win_close(self.winId, true)
	end

	self.winId = 0

	log.info('window#close', debug.traceback())
	if self.buffer then
		self.buffer:close()
	end

	self.bufh = 0
	self.buffer = nil
end

function WindowHandler:isValid()
	return vim.api.nvim_win_is_valid(self.winId)
end

function WindowHandler:show()
	if self.bufh == 0 then
		self.bufh = vim.api.nvim_create_buf(false, true)
		self.buffer = Buffer:new(self.bufh)
	end

	if self.winId == 0 then
		self.winId = vim.api.nvim_open_win(self.bufh, true, self.config)
	else
		vim.api.nvim_win_set_config(self.winId, self.config)
	end
end

function WindowHandler:onResize()
	if not vim.api.nvim_win_is_valid(self.winId) then
		return false
	end

	local ok, msg = pcall(function()
		print('onResize before', vim.inspect(self.config))
		self.config = generateConfig()
		print('onResize', vim.inspect(self.config))
		self:show()
	end)

	if not ok then
		log.info('WindowHandler:onResize', msg)
	end

	return ok
end

return WindowHandler
