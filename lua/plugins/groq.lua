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
      model = "openai/gpt-oss-120b", -- or another Groq model
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

  if not res or res.status ~= 200 then
    vim.notify(("Groq HTTP %s"):format(res and res.status or "nil"), vim.log.levels.ERROR)
    return ""
  end

  local ok, parsed = pcall(vim.fn.json_decode, res.body)
  if not ok or not parsed then
    vim.notify("Groq response parse error", vim.log.levels.ERROR)
    return ""
  end

  if not parsed.output then
    vim.notify("Groq: no output field", vim.log.levels.WARN)
    return ""
  end

  -- handle new /responses shape
  for _, item in ipairs(parsed.output) do
    if item.type == "message" and item.content then
      for _, c in ipairs(item.content) do
        if c.type == "output_text" then
          return c.text
        end
      end
    -- elseif item.type == "reasoning" and item.content then
    --   for _, c in ipairs(item.content) do
    --     if c.type == "reasoning_text" then
    --       return c.text
    --     end
    --   end
    end
  end

  return ""
end
M.complete = groq_complete

-- --- internal: render ghost lines -----------------------------------------
local function show_ghost(text)
  api.nvim_buf_clear_namespace(0, ns, 0, -1)
  if text == "" then return end

  _G.groq_current_completion = text
  local row = api.nvim_win_get_cursor(0)[1] - 1
  local virt = vim.split(text, "\n")

  api.nvim_buf_set_extmark(0, ns, row, 0, {
    virt_lines = vim.tbl_map(function(line)
      return { { line, "Comment" } }
    end, virt),
    virt_lines_above = false,
  })
end

local function clear_ghost()
  api.nvim_buf_clear_namespace(0, ns, 0, -1)
  _G.groq_current_completion = ""
end

-- --- user-facing commands / mappings --------------------------------------
api.nvim_create_user_command("GroqComplete", function()
  local line = api.nvim_get_current_line()
  local result = groq_complete(line)
  show_ghost(result)
end, { desc = "Request Groq completion for current line" })

-- Ctrl-S: request completion (invoke)
vim.keymap.set({ "i", "n" }, "<C-s>", function()
  local line = api.nvim_get_current_line()
  local result = groq_complete(line)
  show_ghost(result)
end, { desc = "Request Groq completion" })

-- Tab: accept ghost if present, else fallback
vim.keymap.set({ "i", "n" }, "<Tab>", function()
  if _G.groq_current_completion ~= "" then
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local lines = vim.split(_G.groq_current_completion, "\n")
    clear_ghost()
    vim.schedule(function()
      api.nvim_buf_set_text(0, row, 0, row, 0, lines)

    end)
    return ""
  else
    return api.nvim_replace_termcodes("<Tab>", true, true, true)
  end
end, { expr = true, desc = "Accept Groq ghost or tab" })

-- autocl eanup when editing
api.nvim_create_autocmd({ "TextChangedI", "InsertLeave" }, {
  callback = clear_ghost,
})

return M

