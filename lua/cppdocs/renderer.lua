

local M= {}

local function read_files(path)
    local f = io.open(path, "r")
    if not f then return nil end 
    local content = f:read("*a")
    f:close()
    return content
    
end

local function extract_main(html)
  local start = html:find('<div id="mw%-content%-text"')
  if not start then
    return "Content not found"
  end

  -- take everything after this div
  local content = html:sub(start)

  
  local end_pos = content:find('<div class="printfooter"')
  if end_pos then
    content = content:sub(1, end_pos)
  end

  return content
end



local function strip_tags(text)
  -- remove scripts and styles first
  text = text:gsub("<script.->.-</script>", "")
  text = text:gsub("<style.->.-</style>", "")

  for level = 1, 6 do
    local open_tag = "<h" .. level .. "[^>]->"
    local close_tag = "</h" .. level .. ">"
    text = text:gsub(open_tag, "\n\n" .. string.rep("#", level) .. " ")
    text = text:gsub(close_tag, "\n\n")
  end

  text = text:gsub("<br%s*/?>", "\n")
  text = text:gsub("</p>", "\n\n")
  text = text:gsub("<p[^>]->", "")
  text = text:gsub("</div>", "\n")
  text = text:gsub("<div[^>]->", "")
  text = text:gsub("</li>", "\n")
  text = text:gsub("<li[^>]->", "- ")
  text = text:gsub("</dt>", "\n")
  text = text:gsub("<dt[^>]->", "\n")
  text = text:gsub("</dd>", "\n")
  text = text:gsub("<dd[^>]->", "  ")
  text = text:gsub("</tr>", "\n")
  text = text:gsub("<tr[^>]->", "\n")
  text = text:gsub("</td>", "\t")
  text = text:gsub("</th>", "\t")
  text = text:gsub("<t[dh][^>]->", "")
  text = text:gsub("<ul[^>]->", "\n")
  text = text:gsub("</ul>", "\n")
  text = text:gsub("<ol[^>]->", "\n")
  text = text:gsub("</ol>", "\n")
  text = text:gsub("<pre[^>]->", "\n```text\n")
  text = text:gsub("</pre>", "\n```\n")
  text = text:gsub("<code[^>]->", "`")
  text = text:gsub("</code>", "`")
  text = text:gsub("<a[^>]->", "")
  text = text:gsub("</a>", " ")
  text = text:gsub("<span[^>]->", "")
  text = text:gsub("</span>", " ")

  -- remove all tags
  text = text:gsub("<.->", "")

  -- decode basic HTML entities
  text = text:gsub("&lt;", "<")
  text = text:gsub("&gt;", ">")
  text = text:gsub("&amp;", "&")
  text = text:gsub("&nbsp;", " ")

  local lines = {}
  local previous_blank = false
  local in_code_block = false

  local function is_heading(line)
    if line == "" then
      return false
    end

    if line:find("::", 1, true) then
      return false
    end

    if #line > 60 then
      return false
    end

    if line:match("^%d+") or line:match("^[%-%(]") then
      return false
    end

    return line:match("^[A-Z][A-Za-z0-9%s%-%/]+$") ~= nil
  end

  for line in text:gmatch("[^\r\n]+") do
    if line:match("^```") then
      table.insert(lines, line)
      in_code_block = not in_code_block
      previous_blank = false
    elseif in_code_block then
      line = line:gsub("%s+$", "")
      table.insert(lines, line)
      previous_blank = false
    else
      line = line:gsub("%s+", " ")
      line = line:gsub("^%s+", "")
      line = line:gsub("%s+$", "")

      if line == "" then
        if not previous_blank then
          table.insert(lines, "")
          previous_blank = true
        end
      else
        if is_heading(line) then
          if #lines > 0 and lines[#lines] ~= "" then
            table.insert(lines, "")
          end

          if #lines == 0 then
            table.insert(lines, "# " .. line)
          else
            table.insert(lines, "## " .. line)
          end
          table.insert(lines, "")
        else
          table.insert(lines, line)
        end

        previous_blank = false
      end
    end
  end

  return table.concat(lines, "\n")
end

local function truncate_top_level_dump(lines)
  local first_heading = nil

  for i = 1, math.min(#lines, 120) do
    if lines[i]:match("^##%s+") then
      first_heading = i
      break
    end
  end

  if not first_heading then
    return lines
  end

  local block_end = first_heading - 1
  local heading_count = 0

  for i = first_heading, #lines do
    local line = lines[i]
    if line:match("^##%s+") then
      heading_count = heading_count + 1
      block_end = i
    elseif line == "" then
      block_end = i
    else
      break
    end
  end

  local keep_headings = 6
  if heading_count <= keep_headings then
    return lines
  end

  local out = {}
  for i = 1, first_heading - 1 do
    table.insert(out, lines[i])
  end

  local kept = 0
  for i = first_heading, block_end do
    local line = lines[i]
    if line:match("^##%s+") then
      kept = kept + 1
      if kept <= keep_headings then
        table.insert(out, line)
      end
    elseif kept <= keep_headings then
      table.insert(out, line)
    end
  end

  table.insert(out, "")
  table.insert(out, "... " .. (heading_count - keep_headings) .. " more top-level sections omitted ...")
  table.insert(out, "")

  for i = block_end + 1, #lines do
    table.insert(out, lines[i])
  end

  return out
end

function M.render(path)
    local html = read_files(path)
    if not html then
        print("Failed to read file")
        return 

    end

    local main = extract_main(html)
    local clean = strip_tags(main)

    vim.cmd("botright vnew")
    local buf = vim.api.nvim_get_current_buf()

    local lines = {}
    for line in clean:gmatch("[^\r\n]+") do
        table.insert(lines,line) 
    end

    lines = truncate_top_level_dump(lines)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    for line_number, line in ipairs(lines) do
      local idx = line_number - 1
      if line:find("std::", 1, true) then
        vim.api.nvim_buf_add_highlight(buf, -1, "Title", idx, 0, -1)
      end
      if line:match("^##") then
        vim.api.nvim_buf_add_highlight(buf, -1, "Function", idx, 0, -1)
      end
    end

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true 
    vim.bo[buf].filetype = "markdown"
    vim.wo.wrap = true
    vim.wo.linebreak = true

    vim.keymap.set("n", "q", "<cmd>close<cr>", {
      buffer = buf,
      silent = true,
      nowait = true,
    })
    
end

return M 
