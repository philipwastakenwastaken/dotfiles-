-- Define the modules that hold our plugin specs.
local modules = {
	"plugins.lsp",
	"plugins.blinkcmp",
	"plugins.telescope",
	"plugins.ui",
	"plugins.treesitter",
	"plugins.conform",
	"plugins.sleuth",
	"plugins.yazi",
	"plugins.dashboard",
}

local plugins = {}

for _, module in ipairs(modules) do
	local module_plugins = require(module)
	for _, plugin in ipairs(module_plugins) do
		table.insert(plugins, plugin)
	end
end

return plugins
