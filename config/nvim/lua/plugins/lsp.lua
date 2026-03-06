return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"saghen/blink.cmp",
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
						ensure_installed = { "lua_ls", "jsonls", "bicep", "azure_pipelines_ls", "pyright" },
						automatic_installation = true,
					})
				end,
			},
		},
		config = function()
			-- Apply blink.cmp capabilities to all servers
			vim.lsp.config("*", {
				capabilities = require("blink.cmp").get_lsp_capabilities(),
			})

			-- Servers that need custom configuration
			-- (servers not listed here use lspconfig defaults and just need vim.lsp.enable)

			-- Inject Neovim runtime into lua_ls when no project .luarc.json is present
			vim.lsp.config("lua_ls", {
				on_init = function(client)
					if client.workspace_folders then
						local path = client.workspace_folders[1].name
						if
							path ~= vim.fn.stdpath("config")
							and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
						then
							return
						end
					end
					client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
						runtime = { version = "LuaJIT" },
						workspace = {
							checkThirdParty = false,
							library = { vim.env.VIMRUNTIME },
						},
					})
				end,
				settings = {
					Lua = { telemetry = { enable = false } },
				},
			})

			-- Root at the nearest .sln/.csproj instead of lspconfig's default
			vim.lsp.config("bicep", {
				cmd = { "bicep-langserver" },
				root_dir = function(bufnr, cb)
					cb(vim.fs.root(bufnr, { ".sln", ".csproj" }) or vim.uv.cwd())
				end,
			})

			vim.lsp.config("jsonls", {
				settings = {
					json = {
						schemas = {
							{
								fileMatch = { "package.json" },
								url = "https://json.schemastore.org/package.json",
							},
						},
						validate = { enable = true },
					},
				},
			})

			-- bundle_path is resolved from the Nix-installed wrapper location
			vim.lsp.config("powershell_es", {
				bundle_path = vim.fn.fnamemodify(vim.fn.exepath("powershell-editor-services"), ":h:h")
					.. "/lib/powershell-editor-services",
				root_dir = function(bufnr, cb)
					cb(vim.fs.root(bufnr, { "PSScriptAnalyzerSettings.psd1", ".git" }))
				end,
			})

			-- Root at the pipelines/ subdirectory so schema paths resolve correctly
			vim.lsp.config("azure_pipelines_ls", {
				root_dir = function(bufnr, cb)
					local root = vim.fs.root(bufnr, { "pipelines" })
					cb(root and vim.fs.joinpath(root, "pipelines") or nil)
				end,
				settings = {
					yaml = {
						schemas = {
							["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = {
								"/azure-pipeline*.y*l",
								"/*.azure*",
								"Azure-Pipelines/**/*.y*l",
								"Pipelines/*.y*l",
								"pipelines/*.y*l",
								"pipelines/**/*.y*l",
							},
						},
					},
				},
			})

			vim.lsp.enable({
				"pyright",       -- defaults only
				"ruff",          -- defaults only
				"rust_analyzer", -- defaults only
				"roslyn_ls",     -- defaults only
				"lua_ls",
				"bicep",
				"jsonls",
				"powershell_es",
				"azure_pipelines_ls",
			})
		end,
	},
}
