local indexer = require("cppdocs.indexer")
local search = require("cppdocs.search")
local renderer = require("cppdocs.renderer")
local config = require("cppdocs.config")

local index = nil

local function ensure_index()
    if not index then
        local docs_root = config.get().docs_root
        if not docs_root or docs_root == "" then
            print("cppdocs: docs_root is not configured")
            index = {}
            return
        end

        index = indexer.build_index(docs_root)
        if next(index) == nil then
            print("cppdocs: no HTML docs found under " .. docs_root)
        end
    end
end

vim.api.nvim_create_user_command("CppSearch", function(opts)
    local query = opts.args

    if query == "" then
        print("Usage: :CppSearch <query>")
        return
    end

    ensure_index()

    local result = search.search(index, query)

    if #result == 0 then
        print("No result found")
        return
    end

    local best = result[1]
    print("Opening: " .. best.key)

    renderer.render(best.path)
end, {
    nargs = 1,
})

