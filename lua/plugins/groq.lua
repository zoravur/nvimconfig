-- ~/.config/nvim/lua/plugins/groq.lua
-- Clean, single-source Groq completion module for Neovim

local M = {}
local api = vim.api

-- --- dependencies ----------------------------------------------------------
local curl_ok, curl = pcall(require, "plenary.curl")
if not curl_ok then
  vim.notify("plenary.curl not found; install nvim-lua/plenary.nvim", vim.log.levels.ERROR)
  return
end

-- --- state -----------------------------------------------------------------
local ns = api.nvim_create_namespace("groq_ghost")
_G.groq_current_completion = ""

-- --- internal: call Groq Responses API -------------------------------------
---@param prompt string
---@return string
local function groq_complete()
  local key = os.getenv("GROQ_API_KEY")
  if not key or key == "" then
    vim.notify("Missing GROQ_API_KEY", vim.log.levels.ERROR)
    return ""
  end

  -- 1️⃣  capture entire file
  local buf = api.nvim_get_current_buf()
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)

  -- 2️⃣  mark cursor position
  local row, col = unpack(api.nvim_win_get_cursor(0))
  lines[row] = lines[row]:sub(1, col) .. "/*<CURSOR>*/" .. lines[row]:sub(col + 1)

  -- 3️⃣  join file into text
  local file_text = table.concat(lines, "\n")

  -- TODO(@ChatGPT): Please replace the hardcoded language tag with the 
  -- correct tag for the language. Also, our comment style has to be 
  -- correct for every language... we can start with /**/ types, and then
  -- move on to other comment styles as needed.
  local prompt = string.format([[
You are a code completion engine.
Given the full file below, replace the marker /*<CURSOR>*/ with concise code that fits the surrounding context.
Return *only* the text that should be inserted at the cursor.

```cpp
%s
```
]], file_text)

  local res = curl.post("https://api.groq.com/openai/v1/responses", {
    headers = {
      ["Authorization"] = "Bearer " .. key,
      ["Content-Type"] = "application/json",
    },
    body = vim.fn.json_encode({
      model = "openai/gpt-oss-120b",
      input = prompt,
      temperature = 0.2,
      max_output_tokens = 512,
      reasoning = { effort = "low" },
    }),
    timeout = 8000,
  })

  if not res or res.status ~= 200 then
    vim.notify(("Groq HTTP %s"):format(res and res.status or "nil"), vim.log.levels.ERROR)
    return ""
  end

  local ok, parsed = pcall(vim.fn.json_decode, res.body)
  if not ok or not parsed or not parsed.output then
    vim.notify("Groq parse error", vim.log.levels.ERROR)
    return ""
  end

  for _, item in ipairs(parsed.output) do
    if item.type == "message" and item.content then
      for _, c in ipairs(item.content) do
        if c.type == "output_text" then
          return vim.trim(c.text)
        end
      end
    end
  end

  return ""
end

-- local function groq_complete(prompt)
--   local key = os.getenv("GROQ_API_KEY")
--   if not key or key == "" then
--     vim.notify("Missing GROQ_API_KEY environment variable", vim.log.levels.ERROR)
--     return ""
--   end
-- 
--   local res = curl.post("https://api.groq.com/openai/v1/responses", {
--     headers = {
--       ["Authorization"] = "Bearer " .. key,
--       ["Content-Type"] = "application/json",
--     },
--     body = vim.fn.json_encode({
--       model = "openai/gpt-oss-120b", -- or another Groq model
--       input = string.format(
--         "You are a concise code completion engine. Complete this snippet:\n%s",
--         prompt
--       ),
--       reasoning = { effort = "low" },
--       temperature = 0.2,
--       max_output_tokens = 512,
--     }),
--     timeout = 5000,
--   })
-- 
--   if not res or res.status ~= 200 then
--     vim.notify(("Groq HTTP %s"):format(res and res.status or "nil"), vim.log.levels.ERROR)
--     return ""
--   end
-- 
--   local ok, parsed = pcall(vim.fn.json_decode, res.body)
--   if not ok or not parsed then
--     vim.notify("Groq response parse error", vim.log.levels.ERROR)
--     return ""
--   end
-- 
--   if not parsed.output then
--     vim.notify("Groq: no output field", vim.log.levels.WARN)
--     return ""
--   end
-- 
--   -- handle new /responses shape
--   for _, item in ipairs(parsed.output) do
--     if item.type == "message" and item.content then
--       for _, c in ipairs(item.content) do
--         if c.type == "output_text" then
--           return c.text
--         end
--       end
--     -- elseif item.type == "reasoning" and item.content then
--     --   for _, c in ipairs(item.content) do
--     --     if c.type == "reasoning_text" then
--     --       return c.text
--     --     end
--     --   end
--     end
--   end
-- 
--   return ""
-- end
M.complete = groq_complete

-- --- internal: render ghost lines -----------------------------------------
local function show_ghost(text)
  api.nvim_buf_clear_namespace(0, ns, 0, -1)
  _G.groq_current_completion = text or ""
  if _G.groq_current_completion == "" then return end

  local row, col = unpack(api.nvim_win_get_cursor(0))
  local zero_row = row - 1
  local parts = vim.split(_G.groq_current_completion, "\n", { plain = true })

  -- First line: inline at cursor
  api.nvim_buf_set_extmark(0, ns, zero_row, col, {
    virt_text = { { parts[1], "Comment" } },
    virt_text_pos = "overlay",
  })

  -- Remaining lines: virtual lines below, padded to cursor column
  if #parts > 1 then
    local pad = string.rep(" ", col)
    local virt_lines = {}
    for i = 2, #parts do
      table.insert(virt_lines, { { pad .. parts[i], "Comment" } })
    end
    api.nvim_buf_set_extmark(0, ns, zero_row, 0, {
      virt_lines = virt_lines,
      virt_lines_above = false,
    })
  end
end

-- local function show_ghost(text)
--   api.nvim_buf_clear_namespace(0, ns, 0, -1)
--   if text == "" then return end
-- 
--   _G.groq_current_completion = text
--   local row = api.nvim_win_get_cursor(0)[1] - 1
--   local virt = vim.split(text, "\n")
-- 
--   api.nvim_buf_set_extmark(0, ns, row, 0, {
--     virt_lines = vim.tbl_map(function(line)
--       return { { line, "Comment" } }
--     end, virt),
--     virt_lines_above = false,
--   })
-- end

local function clear_ghost()
  api.nvim_buf_clear_namespace(0, ns, 0, -1)
  _G.groq_current_completion = ""
end

-- --- user-facing commands / mappings --------------------------------------
api.nvim_create_user_command("GroqComplete", function()
  local line = api.nvim_get_current_line()
  local result = groq_complete()
  show_ghost(result)
end, { desc = "Request Groq completion for current line" })

-- Ctrl-S: request completion (invoke)
vim.keymap.set({ "i", "n" }, "<C-s>", function()
  local line = api.nvim_get_current_line()
  local result = groq_complete()
  show_ghost(result)
end, { desc = "Request Groq completion" })

-- -- Tab: accept ghost if present, else fallback
-- vim.keymap.set({ "i", "n" }, "<Tab>", function()
--   if _G.groq_current_completion ~= "" then
--     local row, col = unpack(api.nvim_win_get_cursor(0))
--     local lines = vim.split(_G.groq_current_completion, "\n")
--     clear_ghost()
--     vim.schedule(function()
--       api.nvim_buf_set_text(0, row, 0, row, 0, lines)
-- 
--     end)
--     return ""
--   else
--     return api.nvim_replace_termcodes("<Tab>", true, true, true)
--   end
-- end, { expr = true, desc = "Accept Groq ghost or tab" })
-- Optional toggle: split “after-cursor” onto its own new line
-- local split_after = (M.split_after == true)
-- 
-- vim.keymap.set({ "i", "n" }, "<Tab>", function()
--   if _G.groq_current_completion == "" then
--     return api.nvim_replace_termcodes("<Tab>", true, true, true)
--   end
-- 
--   local row, col = unpack(api.nvim_win_get_cursor(0))
--   local zero_row = row - 1
--   local cur_line = api.nvim_get_current_line()
--   local before = cur_line:sub(1, col)
--   local after  = cur_line:sub(col + 1)
-- 
--   local comp = _G.groq_current_completion
--   _G.groq_current_completion = ""
--   api.nvim_buf_clear_namespace(0, ns, 0, -1)
-- 
--   local lines = vim.split(comp, "\n", { plain = true })
--   if #lines == 0 then return "" end
-- 
--   -- stitch current line into multiple lines:
--   -- line 1: before + first completion line
--   local out = {}
--   out[1] = before .. lines[1]
-- 
--   -- middle completion lines (as-is)
--   for i = 2, #lines - 1 do
--     table.insert(out, lines[i])
--   end
-- 
--   -- last completion line + after-cursor (or split-after onto its own new line)
--   if #lines > 1 then
--     local last = lines[#lines]
--     if split_after and after ~= "" then
--       table.insert(out, last)
--       table.insert(out, after)
--     else
--       table.insert(out, last .. after)
--     end
--   else
--     -- single-line completion
--     if split_after and after ~= "" and lines[1] ~= "" then
--       out[1] = out[1]
--       table.insert(out, after)
--     else
--       out[1] = out[1] .. after
--     end
--   end
-- 
--   -- Replace current line with `out` (safe, atomic)
--   vim.schedule(function()
--     api.nvim_buf_set_text(0, zero_row, 0, zero_row, #cur_line, out)
--   end)
-- 
--   return ""
-- end, { expr = true, desc = "Accept Groq ghost or Tab" })

-- Optional toggle: put tail ("after") on its own line
local split_after = (M and M.split_after == true)

vim.keymap.set({ "i", "n" }, "<Tab>", function()
  if _G.groq_current_completion == "" then
    return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local zrow     = row - 1
  local cur_line = vim.api.nvim_get_current_line()
  local before   = cur_line:sub(1, col)
  local after    = cur_line:sub(col + 1)

  local comp = _G.groq_current_completion
  _G.groq_current_completion = ""
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

  local parts = vim.split(comp, "\n", { plain = true })
  if #parts == 0 then return "" end

  -- Build replacement lines
  local out = {}
  out[1] = before .. parts[1]
  for i = 2, #parts - 1 do table.insert(out, parts[i]) end

  local cursor_row = zrow     -- 0-index
  local cursor_col = 0        -- set below

  if #parts > 1 then
    local last = parts[#parts]
    if split_after and after ~= "" then
      table.insert(out, last)     -- completion ends here
      table.insert(out, after)    -- tail on its own line
      cursor_row = zrow + (#out - 1) - 1  -- second-to-last line
      cursor_col = #last
    else
      table.insert(out, last .. after)    -- tail appended
      cursor_row = zrow + (#out - 1)      -- last line
      cursor_col = #last                  -- caret before tail
    end
  else
    -- single-line completion
    if split_after and after ~= "" and parts[1] ~= "" then
      table.insert(out, after)
      cursor_row = zrow                   -- first of out
      cursor_col = #out[1]
    else
      out[1] = out[1] .. after
      cursor_row = zrow
      cursor_col = #before + #parts[1]
    end
  end

  -- Apply edit, then move cursor
  vim.schedule(function()
    vim.api.nvim_buf_set_text(0, zrow, 0, zrow, #cur_line, out)
    vim.api.nvim_win_set_cursor(0, { cursor_row + 1, cursor_col })
  end)

  return ""
end, { expr = true, desc = "Accept Groq ghost or Tab" })


-- autocl eanup when editing
api.nvim_create_autocmd({ "TextChangedI", "InsertLeave" }, {
  callback = clear_ghost,
})

return M

