require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		cs = { "csharpier" },
		rust = { "rustfmt" }
	},
	format_on_save = {
		-- These options will be passed to conform.format()
		timeout_ms = 2000,
		lsp_format = "never",
	},
})
