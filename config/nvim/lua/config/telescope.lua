local telescope = require("telescope")
local actions = require("telescope.actions")

telescope.setup({
	extensions = {
		fzf = {
			fuzzy = true,
			override_generic_sorter = true,
			override_file_sorter = true,
			case_mode = "smart_case",
		},
	},
})

pcall(function()
	telescope.load_extension("fzf")
end)

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })

vim.keymap.set("n", "<leader>fb", function()
	builtin.buffers({
		initial_mode = "normal",
		sort_mru = true,
		sort_lastused = true,
		attach_mappings = function(_, map)
			-- In insert mode, press Ctrl-d to delete the selected buffer
			map("i", "<C-d>", actions.delete_buffer)
			-- In normal mode, press 'd' to delete the selected buffer
			map("n", "d", actions.delete_buffer)
			return true
		end,
	})
end, { desc = "Telescope buffers" })

vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
