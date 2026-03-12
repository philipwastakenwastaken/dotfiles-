return {
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				cs = { "csharpier" },
				rust = { "rustfmt" },
			},
			formatters = {
				csharpier = {
					command = vim.fn.exepath("dotnet-csharpier"),
					args = { "--write-stdout" },
					stdin = true,
				},
			},
			format_on_save = {
				timeout_ms = 2000,
				lsp_format = "never",
			},
		},
	},
}
