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
vim.keymap.set("n", "<leader>fs", builtin.grep_string, { desc = "Telescope string grep" })
vim.keymap.set("n", "<leader>fj", builtin.jumplist, { desc = "Telescope jump list" })
vim.keymap.set("n", "<leader>fe", builtin.diagnostics, { desc = "Telescope diagnostics" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>fi", builtin.lsp_implementations, { desc = "Telescope LSP implementations" })
vim.keymap.set("n", "<leader>fd", builtin.lsp_definitions, { desc = "Telescope LSP definitions" })
vim.keymap.set("n", "<leader>ft", builtin.lsp_type_definitions, { desc = "Telescope LSP type definitions" })
vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "Telescope LSP references" })
vim.keymap.set("n", "<leader>fc", function()
	builtin.find_files({
		cwd = vim.fn.stdpath("config"),
	})
end, { desc = "Telescope nvim config" })

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
