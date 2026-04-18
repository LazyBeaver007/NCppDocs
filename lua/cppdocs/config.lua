local M = {}

local defaults = {
	docs_root = "D:/html_book_20190607/reference/en",
}

local function copy_table(tbl)
	local out = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			out[k] = copy_table(v)
		else
			out[k] = v
		end
	end
	return out
end

local options = copy_table(defaults)

function M.setup(opts)
	options = copy_table(defaults)
	for k, v in pairs(opts or {}) do
		options[k] = v
	end
end

function M.get()
	return options
end

return M
