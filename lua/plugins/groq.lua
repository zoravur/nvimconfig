-- ~/.config/nvim/lua/plugins/groq.lua

local M = {}

local curl_ok, curl = pcall(require, "plenary.curl")
if not curl_ok then
  vim.notify("plenary.curl not found; install nvim-lua/plenary.nvim", vim.log.levels.ERROR)
  return
end

local api = vim.api

--- Call Groq’s OpenAI-compatible API for completions
---@param prompt string
---@return string
local function groq_complete(prompt)
  local key = os.getenv("GROQ_API_KEY")
  if not key or key == "" then
    vim.notify("Missing GROQ_API_KEY environment variable", vim.log.levels.ERROR)
    return ""
  end

  local res = curl.post("https://api.groq.com/openai/v1/responses", {
    headers = {
      ["Authorization"] = "Bearer " .. key,
      ["Content-Type"] = "application/json",

    },
    body = vim.fn.json_encode({
      model = "openai/gpt-oss-120b",  -- use any valid Groq model
      input = string.format(
        "You are a concise code completion engine. Complete this snippet:\n%s",
        prompt
      ),
      reasoning = { effort = "low" },
      temperature = 0.2,
      max_output_tokens = 512,
    }),
    timeout = 5000,
  })

  if not res then
    vim.notify("Groq request failed (no response)", vim.log.levels.ERROR)
    return ""
  end

  -- Print the full response for debugging
  -- print("=== Groq Debug ===")
  -- print("Status:", res.status)
  -- print("Headers:", vim.inspect(res.headers))
  -- print("Body:", res.body)
  -- print("==================")

  if res.status ~= 200 then
    vim.notify("Groq HTTP " .. res.status, vim.log.levels.ERROR)
    return ""
  end


  local ok, parsed = pcall(vim.fn.json_decode, res.body)
  if not ok or not parsed then
    vim.notify("Groq response parse error", vim.log.levels.ERROR)
    return ""
  end

  -- Handle the new /responses format
  if parsed.output and type(parsed.output) == "table" then
    for _, item in ipairs(parsed.output) do
      if item.type == "message" and item.content then
        for _, c in ipairs(item.content) do
          if c.type == "output_text" then
            return c.text
          end
        end
      end
    end
  end

  vim.notify("Groq response had no text output", vim.log.levels.WARN)
  return ""
end

--- Simple command: :GroqComplete
-- api.nvim_create_user_command("GroqComplete", function()
--   local line = api.nvim_get_current_line()
--   local result = groq_complete(line)
--   if result ~= "" then
--     api.nvim_echo({ { result, "Comment" } }, false, {})
--     api.nvim_buf_clear_namespace(0, -1, 0, -1)
-- 
--     -- Put ghost text one line below the cursor
--     local row, col = unpack(api.nvim_win_get_cursor(0))
--     row = row - 1  -- convert to 0-index
-- 
--     api.nvim_buf_set_extmark(0, api.nvim_create_namespace("groq_ghost"), row, col, {
--       virt_text = { { result, "Comment" } },  -- grey text
--       virt_text_pos = "overlay",
--     })
-- 
--   end
-- end, { desc = "Ask Groq for completion of current line" })
-- 
_G.groq_current_completion = ""

api.nvim_create_user_command("GroqComplete", function()
  local line = api.nvim_get_current_line()
  local result = groq_complete(line)
  if result == "" then return end

  _G.groq_current_completion = result

  local ns = api.nvim_create_namespace("groq_ghost")
  api.nvim_buf_clear_namespace(0, ns, 0, -1)

  local row = api.nvim_win_get_cursor(0)[1] - 1
  local virt = vim.split(result, "\n")

  api.nvim_buf_set_extmark(0, ns, row, 0, {
    virt_lines = vim.tbl_map(function(l)
      return { { l, "Comment" } }
    end, virt),
    virt_lines_above = false,
  })
end, {})

-- keymap set


vim.keymap.set({ "i", "n" }, "<C-s>", function()
  local line = api.nvim_get_current_line()
  local result = groq_complete(line)
  if result == "" then return end

  _G.groq_current_completion = result

  local ns = api.nvim_create_namespace("groq_ghost")
  api.nvim_buf_clear_namespace(0, ns, 0, -1)

  local row = api.nvim_win_get_cursor(0)[1] - 1
  local virt = vim.split(result, "\n")

  api.nvim_buf_set_extmark(0, ns, row, 0, {
    virt_lines = vim.tbl_map(function(l)
      return { { l, "Comment" } }
    end, virt),
    virt_lines_above = false,
  })
end, { desc = "Accept Groq ghost text" })

vim.keymap.set({"i", "n"}, "<Tab>", function()
  if _G.groq_current_completion ~= "" then
    local ns = vim.api.nvim_create_namespace("groq_ghost")
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local lines = vim.split(_G.groq_current_completion, "\n")

    vim.schedule(function()
      vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, lines)
      _G.groq_current_completion = ""
    end)

    return ""
  else
    return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
  end
end, { expr = true, desc = "Accept Groq ghost or tab" })

vim.api.nvim_create_autocmd({ "TextChangedI", "InsertLeave" }, {
  callback = function()
    api.nvim_buf_clear_namespace(0, api.nvim_create_namespace("groq_ghost"), 0, -1)
  end, 
}) 


M.complete = groq_complete
return M

