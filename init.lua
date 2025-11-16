-- Set space as the leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable basic Vim features
vim.cmd('syntax enable')
vim.cmd('filetype plugin indent on')

-- Set basic options
vim.opt.termguicolors = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.number = true
vim.opt.relativenumber = true

vim.cmd.colorscheme("ziggy")

-- Set indentation for specific file types
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "cpp", "c", "go", "templ", "rust" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specifications
local plugins = {

  ---------------------------------------------------------------------------
  -- LSP (new-style config, no deprecated API)
  ---------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    ft = { "cpp", "go", "lua", "templ", "python", "rust" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/nvim-cmp",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      -- Load lspconfig ONCE so server definitions register with vim.lsp.config
      require("lspconfig")

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Native root finder
      local function root(patterns)
        return vim.fs.root(0, patterns)
      end

      ---------------------------------------------------------------------
      -- Helper: merge opts into built-in server config table
      -- (because vim.lsp.config[server] is NOT a function on 0.11)
      ---------------------------------------------------------------------
      local function setup(server, opts)
        local base = vim.lsp.config[server]
        if type(base) ~= "table" then
          vim.notify("No LSP config found for " .. server, vim.log.levels.ERROR)
          return
        end

        -- Deep merge our overrides into the base config table
        local cfg = vim.tbl_deep_extend("force", base, opts)

        -- Autostart per filetype
        vim.api.nvim_create_autocmd("FileType", {
          pattern = opts.filetypes or base.filetypes,
          callback = function(args)
            vim.lsp.start(cfg, { bufnr = args.buf })
          end,
        })
      end

      ---------------------------------------------------------------------
      -- clangd
      ---------------------------------------------------------------------
      setup("clangd", {
        capabilities = capabilities,
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--completion-style=detailed",
          "--header-insertion=iwyu",
          "--pch-storage=memory",
        },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_dir = root({
          ".clangd",
          ".clang-tidy",
          ".clang-format",
          "compile_commands.json",
          "compile_flags.txt",
          "configure.ac",
          ".git",
        }),
      })

      ---------------------------------------------------------------------
      -- gopls
      ---------------------------------------------------------------------
      setup("gopls", {
        capabilities = capabilities,
        cmd = { "gopls", "serve" },
        filetypes = { "go", "gomod" },
        root_dir = root({ "go.work", "go.mod", ".git" }),
        settings = {
          gopls = {
            analyses = { unusedparams = true },
            staticcheck = true,
          },
        },
        on_attach = function(client, bufnr)
          if client.server_capabilities.documentFormattingProvider then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ async = false })
              end,
            })
          end
        end,
      })

      ---------------------------------------------------------------------
      -- lua_ls
      ---------------------------------------------------------------------
      setup("lua_ls", {
        capabilities = capabilities,
        cmd = { vim.fn.expand("/home/$USER/Downloads/luals/bin/lua-language-server") },
        root_dir = root({ ".git", ".luarc.json", ".luacheckrc" }),
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })

      ---------------------------------------------------------------------
      -- rust_analyzer (no rust-tools)
      ---------------------------------------------------------------------
      setup("rust_analyzer", {
        capabilities = capabilities,
        root_dir = root({ "Cargo.toml", ".git" }),
        settings = {
          ["rust-analyzer"] = {
            checkOnSave = { command = "clippy" },
            cargo = { allFeatures = true },
            procMacro = { enable = true },
          },
        },
        on_attach = function(_, bufnr)
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function() vim.lsp.buf.format({ async = false }) end,
          })
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end,
      })

      ---------------------------------------------------------------------
      -- templ
      ---------------------------------------------------------------------
      setup("templ", {
        capabilities = capabilities,
        filetypes = { "templ" },
        root_dir = root({ "go.mod", ".git" }),
      })

      ---------------------------------------------------------------------
      -- pyright
      ---------------------------------------------------------------------
      setup("pyright", {
        capabilities = capabilities,
        root_dir = root({ "pyproject.toml", "setup.py", ".git" }),
      })

      ---------------------------------------------------------------------
      -- Global LSP keymaps
      ---------------------------------------------------------------------
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
          vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        end,
      })
    end
  },

  ---------------------------------------------------------------------------
  -- CMP
  ---------------------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { 'i', 's' }),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        },
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- Treesitter
  ---------------------------------------------------------------------------
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "query", "go", "rust" },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
      }
    end
  },

  ---------------------------------------------------------------------------
  -- Telescope
  ---------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
          },
          file_ignore_patterns = { "node_modules" },
          dynamic_preview_title = true,
          path_display = { "smart" },
        },
        pickers = {
          find_files = {
            theme = "dropdown",
            previewer = false,
            hidden = true,
          },
          live_grep = {
            theme = "dropdown",
            previewer = true,
          },
          buffers = {
            theme = "dropdown",
            previewer = false,
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })

      telescope.load_extension("fzf")

      vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags" })
    end,
  },

  ---------------------------------------------------------------------------
  -- nvim-tree
  ---------------------------------------------------------------------------
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup({
        sort_by = "case_sensitive",
        view = { width = 30, side = "left" },
        renderer = { group_empty = true },
        filters = { dotfiles = true },
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- vimtex
  ---------------------------------------------------------------------------
  {
    'lervag/vimtex',
    config = function()
      vim.g.vimtex_view_method = 'zathura'
      vim.g.vimtex_compiler_method = 'latexmk'
    end,
  },

  ---------------------------------------------------------------------------
  -- Onedark theme
  ---------------------------------------------------------------------------
  {
    "navarasu/onedark.nvim",
    priority = 1000,
    config = function()
      require('onedark').setup({ style = 'darker' })
      require('onedark').load()
    end,
  },

  ---------------------------------------------------------------------------
  -- Plenary with your custom plugin
  ---------------------------------------------------------------------------
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
    config = function()
      require("plugins.groq")
    end,
  },
}

-- Startup lazy.nvim
require("lazy").setup(plugins)

-- Diagnostics float
vim.keymap.set('n', '<leader>cd', function()
  vim.diagnostic.open_float(nil, { focus = false })
end, { desc = "Show diagnostics under cursor" })

