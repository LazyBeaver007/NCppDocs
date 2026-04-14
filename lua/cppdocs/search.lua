--fuzzy search 

local M = {}

local function score_match(query,key)
    query = query:lower()
    key = key:lower()


    if key == query then
        return 100
    end

    if key:find(query,1,true) then
        return 80
    end

    local score = 0 
    local qi = 0 

    for i = 1, #key do
        if key:sub(i,i) == query:sub(qi, qi) then
            score = score + 5 
            qi = qi +1 
            if qi > #query then break 
            end
        end
    end

    return score
    
end

function M.search(index, query)
    local results = {}
    for key, path in pairs(index) do 
        local score = score_match(query, key)
        if score > 0 then
            table.insert(results, {
                key = key,
                path = path,
                score = score
            })
        end
end

table.sort(results, function(a,b)
    return a.score > b.score 
end
)
return results 

end 

return M
