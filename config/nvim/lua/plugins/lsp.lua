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
			local util = require("lspconfig.util")
			-- Use blink.cmp to get the enhanced LSP capabilities
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			lspconfig.lua_ls.setup({
				capabilities = capabilities,
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
						runtime = {
							-- Tell the language server which version of Lua you're using
							-- (most likely LuaJIT in the case of Neovim)
							version = "LuaJIT",
						},
						-- Make the server aware of Neovim runtime files
						workspace = {
							checkThirdParty = false,
							library = {
								vim.env.VIMRUNTIME,
								-- Depending on the usage, you might want to add additional paths here.
								-- "${3rd}/luv/library"
								-- "${3rd}/busted/library",
							},
							-- or pull in all of 'runtimepath'. NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
							-- library = vim.api.nvim_get_runtime_file("", true)
						},
					})
				end,
				settings = {
					Lua = { telemetry = { enable = false } },
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

			-- absolute path of the wrapper placed in the Nix store
			local pes_exe = vim.fn.exepath("powershell-editor-services") -- e.g. /nix/store/…/bin/powershell-editor-services
			local pes_root = vim.fn.fnamemodify(pes_exe, ":h:h") .. "/lib/powershell-editor-services"

			lspconfig.powershell_es.setup({
				-- (optional) tell lspconfig where the bundle lives; not strictly required
				bundle_path = pes_root,

				-- filetypes you want the server on
				filetypes = { "ps1", "psm1", "psd1" },

				-- start only inside a Git repo or when that settings file exists
				root_dir = util.root_pattern("PSScriptAnalyzerSettings.psd1", ".git"),
			})

			local function find_pipelines_root(fname)
				local base = util.root_pattern("pipelines")(fname)
				if base then
					return util.path.join(base, "pipelines")
				end
				return nil
			end

			lspconfig.azure_pipelines_ls.setup({
				root_dir = find_pipelines_root,
				capabilities = capabilities,
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
		end,
	},
}
