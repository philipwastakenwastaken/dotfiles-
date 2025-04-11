return {
	{
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup({})
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha", -- choose from latte, frappe, macchiato, or mocha
				transparent_background = false,
				integrations = {
					treesitter = true,
					native_lsp = {
						enabled = true,
						virtual_text = {
							errors = { "italic" },
							hints = { "italic" },
							warnings = { "italic" },
							information = { "italic" },
						},
						underlines = {
							errors = { "underline" },
							hints = { "underline" },
							warnings = { "underline" },
							information = { "underline" },
						},
					},
					cmp = true,
					gitsigns = true,
				},
			})
			vim.cmd("colorscheme catppuccin")
		end,
	},
	{ "nvim-tree/nvim-web-devicons", opts = {} },
	{ "echasnovski/mini.icons", version = "*" },
}
