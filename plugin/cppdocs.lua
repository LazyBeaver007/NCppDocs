local function safe_require(mod)
    local ok, value = pcall(require, mod)
    if ok then
        return value
    end

    local lua_path = "lua/" .. mod:gsub("%.", "/") .. ".lua"
    vim.notify(
        ("cppdocs: failed to load `%s`.\n"
            .. "Install this plugin so its root is on `runtimepath` and `%s` exists.\n"
            .. "Original error:\n%s"):format(mod, lua_path, value),
        vim.log.levels.ERROR
    )

    return nil
end

local indexer = safe_require("cppdocs.indexer")
local search = safe_require("cppdocs.search")
local renderer = safe_require("cppdocs.renderer")
local config = safe_require("cppdocs.config")

if not (indexer and search and renderer and config) then
    return
end

local index = nil

local function ensure_index()
    if not index then
        local docs_root = config.get().docs_root
        if not docs_root or docs_root == "" then
            print("cppdocs: docs_root is not configured")
            index = {}
            return
        end

        local stat = vim.loop.fs_stat(docs_root)
        if not stat or stat.type ~= "directory" then
            print("cppdocs: docs_root is not a directory: " .. docs_root)
            index = {}
            return
        end

        index = indexer.build_index(docs_root)
        if next(index) == nil then
            print("cppdocs: no HTML docs found under " .. docs_root)
        else
            print("cppdocs: indexed " .. vim.tbl_count(index) .. " pages")
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

vim.api.nvim_create_user_command("CppReindex", function()
    index = nil
    ensure_index()
end, {})

