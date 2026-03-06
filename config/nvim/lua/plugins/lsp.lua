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
						ensure_installed = { "lua_ls", "jsonls", "bicep", "azure_pipelines_ls", "pyright" },
						automatic_installation = true,
					})
				end,
			},
		},
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Apply capabilities globally to all servers
			vim.lsp.config("*", { capabilities = capabilities })

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

			vim.lsp.config("bicep", {
				cmd = { "bicep-langserver" },
				root_dir = function(bufnr, cb)
					local root = vim.fs.root(bufnr, { ".sln", ".csproj" })
					cb(root or vim.uv.cwd())
				end,
			})

			vim.lsp.config("jsonls", {
				filetypes = { "json", "jsonc" },
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

			local pes_exe = vim.fn.exepath("powershell-editor-services")
			local pes_root = vim.fn.fnamemodify(pes_exe, ":h:h") .. "/lib/powershell-editor-services"

			vim.lsp.config("powershell_es", {
				bundle_path = pes_root,
				filetypes = { "ps1", "psm1", "psd1" },
				root_dir = function(bufnr, cb)
					cb(vim.fs.root(bufnr, { "PSScriptAnalyzerSettings.psd1", ".git" }))
				end,
			})

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
				"pyright",
				"ruff",
				"rust_analyzer",
				"lua_ls",
				"bicep",
				"jsonls",
				"powershell_es",
				"azure_pipelines_ls",
			})
		end,
	},
}
