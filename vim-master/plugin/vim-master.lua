if vim.fn.has('nvim-0.5') == 1 then
	-- Define the function to start the Vim challenge
	local function VimMasterChallenge()
		-- Clear previous loaded instances of the 'vim-master' package
		for k in pairs(package.loaded) do
			if k:match('^vim%-master') then
				package.loaded[k] = nil
			end
		end
		require('vim-master').menu()
	end

	-- Create a command that calls VimMasterChallenge
	vim.api.nvim_create_user_command('VimChallenge', VimMasterChallenge, {})

	-- Set up autocommand group for VimResized event
	vim.api.nvim_create_augroup('VimChallenge', { clear = true })
	vim.api.nvim_create_autocmd('VimResized', {
		group = 'VimChallenge',
		callback = function()
			require('vim-master').onVimResize()
		end,
	})
else
	print('You need nvim v0.5 or above to get better at vim')
end
