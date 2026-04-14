local M = {}

local function scan_dir(dir, files)
    files = files or {}

    local handle = vim.loop.fs_scandir(dir)
    if not handle then
        return files
    end

    while true do
        local name, type = vim.loop.fs_scandir_next(handle)
        if not name then
            break
        end

        local full_path = dir .. "/" .. name
        if type == "directory" then
            scan_dir(full_path, files)
        elseif type == "file" and name:match("%.html$") then
            table.insert(files, full_path)
        end
    end

    return files
end

local function extract_key(filepath)
    local name = filepath:match("([^/]+)%.html$")
    return name
end

function M.build_index(root_path)
    local index = {}
    local files = scan_dir(root_path)

    for _, file in ipairs(files) do
        local key = extract_key(file)

        if key and not index[key] then
            index[key] = file
        end
    end

    return index
end

return M