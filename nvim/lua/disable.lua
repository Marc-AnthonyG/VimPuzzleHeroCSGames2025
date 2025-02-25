local openVimChallenge = function()
	vim.cmd('VimChallenge')
end

-- Auto open plugin on nvim start
vim.api.nvim_create_autocmd('VimEnter', {
	callback = openVimChallenge,
})

vim.api.nvim_create_autocmd('WinClosed', {
	callback = openVimChallenge,
})

-- List of default keymaps that create windows
local window_creating_maps = {
	-- Basic window splits
	'<C-w>s', -- horizontal split
	'<C-w>v', -- vertical split
	'<C-w>n', -- new window
	'<C-w><C-s>', -- horizontal split (CTRL variant)
	'<C-w><C-v>', -- vertical split (CTRL variant)
	'<C-w><C-n>', -- new window (CTRL variant)

	-- Additional window commands
	'<C-w>^', -- split and edit alternate file
	'<C-w><C-^>', -- split and edit alternate file (CTRL variant)
}

-- Create an empty callback function
local void_function = function() end

-- Apply the void mapping to both normal and visual modes
for _, mapping in ipairs(window_creating_maps) do
	vim.keymap.set('n', mapping, void_function, { silent = true })
	vim.keymap.set('v', mapping, void_function, { silent = true })
end

-- Block the commands that create windows
local window_commands = {
	'Split',
	'Vsplit',
	'New',
	'Vnew',
	'Splitbelow',
	'Splitright',
	'Diffsplit',
}

for _, cmd in ipairs(window_commands) do
	vim.api.nvim_create_user_command(cmd, function() end, {})
end
