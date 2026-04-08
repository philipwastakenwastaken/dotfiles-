local parsers = {
	"bicep",
	"c_sharp",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"powershell",
	"python",
	"query",
	"rust",
	"vim",
	"vimdoc",
	"yaml",
}

local function install_parsers()
	local ok, nvim_treesitter = pcall(require, "nvim-treesitter")
	if ok and type(nvim_treesitter.install) == "function" then
		nvim_treesitter.install(parsers):wait(300000)
		return
	end

	vim.cmd("TSUpdate")
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = install_parsers,
		config = function()
			local ok, nvim_treesitter = pcall(require, "nvim-treesitter")
			if ok and type(nvim_treesitter.setup) == "function" then
				nvim_treesitter.setup({})

				local group = vim.api.nvim_create_augroup("treesitter-start", { clear = true })
				vim.api.nvim_create_autocmd("FileType", {
					group = group,
					callback = function(args)
						if not pcall(vim.treesitter.start, args.buf) then
							return
						end

						-- Keep indentexpr on the filetypes with a stable indent query.
						if vim.bo[args.buf].filetype == "lua" then
							vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
						end
					end,
				})
				return
			end

			-- Bridge startup while Lazy updates from the archived 0.11 branch to the 0.12 rewrite.
			require("nvim-treesitter.configs").setup({
				ensure_installed = parsers,
				sync_install = false,
				auto_install = true,
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
				indent = {
					enable = true,
				},
			})
		end,
	},
}
