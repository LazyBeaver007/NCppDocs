local indexer = require("../lua.cppdocs.indexer")
local search = require("../lua.cppdocs.search")

local index = nil 

local function ensure_index()
    if not index then
        index = indexer.build_index("D:/html_book_20190607/reference/en")
    end
    
end

vim.api.nvim_create_user_command("CppSearch", function (opts)
   local query = opts.args 

   if query == "" then
       print("Usage: :CppSearch <query>")
       return
   end
   
   ensure_index()

   local result = search.search(index,query)

   if #result == 0 then
       print("No result found")
       return 
   end

   local best = result[1]
   print("Opening: "..best.key)

   vim.cmd("edit " ..best.path)
end, {
    nargs = 1
})

