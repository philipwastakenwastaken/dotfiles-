return {
	-- nvim-lspconfig with Mason dependencies
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"saghen/blink.cmp", -- Replace nvim-cmp dependency with blink.cmp
			{
				"williamboman/mason.nvim",
				config = function()
					require("mason").setup()
				end,
			},
			{
				"williamboman/mason-lspconfig.nvim",
				config = function()
					require("mason-lspconfig").setup({
						ensure_installed = { "lua_ls", "jsonls", "bicep", "azure_pipelines_ls" },
						automatic_installation = true,
					})
				end,
			},
		},
		config = function()
			local lspconfig = require("lspconfig")
			-- Use blink.cmp to get the enhanced LSP capabilities
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			lspconfig.lua_ls.setup({
				capabilities = capabilities,
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						diagnostics = { globals = { "vim" } },
						workspace = {
							library = vim.api.nvim_get_runtime_file("", true),
							checkThirdParty = false,
						},
						telemetry = { enable = false },
					},
				},
			})

			local root_candidates = vim.fs.find({ ".sln", ".csproj" }, { upward = true })
			local root_dir = root_candidates[1] and vim.fs.dirname(root_candidates[1]) or vim.loop.cwd()
			lspconfig.bicep.setup({
				cmd = { "bicep-langserver" },
				capabilities = capabilities,
				root_dir = root_dir,
			})

			-- Explicit configuration for jsonls
			lspconfig.jsonls.setup({
				capabilities = capabilities,
				filetypes = { "json", "jsonc" },
				settings = {
					json = {
						-- Define custom schemas. For example, use the package.json schema for package.json files:
						schemas = {
							{
								fileMatch = { "package.json" },
								url = "https://json.schemastore.org/package.json",
							},
							-- Add additional schemas here if needed.
						},
						validate = { enable = true },
					},
				},
			})
		end,
	},
}
