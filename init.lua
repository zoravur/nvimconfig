-- Enable basic Vim features
vim.cmd('syntax enable')
vim.cmd('filetype plugin indent on')

-- Set basic options
vim.opt.termguicolors = true

-- Set default indentation to 2 spaces
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

-- Set indentation for specific file types
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "cpp", "c" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specifications
local plugins = {
  {
     "neovim/nvim-lspconfig",
     dependencies = {
       "hrsh7th/cmp-nvim-lsp",
       "hrsh7th/nvim-cmp",
       "L3MON4D3/LuaSnip",
     },
     config = function()
       local lspconfig = require('lspconfig')
       local capabilities = require('cmp_nvim_lsp').default_capabilities()

       -- Configure clangd
       lspconfig.clangd.setup({
         capabilities = capabilities,
         cmd = {
           "clangd",
           "--background-index",
           "--clang-tidy",
           "--completion-style=detailed",
           "--header-insertion=iwyu",
           "--pch-storage=memory",
         },
         filetypes = {"c", "cpp", "objc", "objcpp"},
         root_dir = lspconfig.util.root_pattern(
           '.clangd',
           '.clang-tidy',
           '.clang-format',
           'compile_commands.json',
           'compile_flags.txt',
           'configure.ac',
           '.git'
         ),
       })

       -- Keybindings for LSP functionality
       vim.api.nvim_create_autocmd('LspAttach', {
         group = vim.api.nvim_create_augroup('UserLspConfig', {}),
         callback = function(ev)
           local opts = { buffer = ev.buf }
           vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
           vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
           vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
           vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
           vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
           vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
           vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
           vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
           vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
         end,
       })
     end,
   },

-- Autocompletion
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
           expand = function(args)
             luasnip.lsp_expand(args.body)
           end,
         },
         mapping = cmp.mapping.preset.insert({
           ['<C-d>'] = cmp.mapping.scroll_docs(-4),
           ['<C-f>'] = cmp.mapping.scroll_docs(4),
           ['<C-Space>'] = cmp.mapping.complete(),
           ['<CR>'] = cmp.mapping.confirm {
             behavior = cmp.ConfirmBehavior.Replace,
             select = true,
           },
           ['<Tab>'] = cmp.mapping(function(fallback)
             if cmp.visible() then
               cmp.select_next_item()
             elseif luasnip.expand_or_jumpable() then
               luasnip.expand_or_jump()
             else
               fallback()
             end
           end, { 'i', 's' }),
           ['<S-Tab>'] = cmp.mapping(function(fallback)
             if cmp.visible() then
               cmp.select_prev_item()
             elseif luasnip.jumpable(-1) then
               luasnip.jump(-1)
             else
               fallback()
             end
           end, { 'i', 's' }),
         }),
         sources = {
           { name = 'nvim_lsp' },
           { name = 'luasnip' },
         },
       })
     end,
   },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "query" },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
      }
    end
  },
--    {
--      'folke/tokyonight.nvim',
--      lazy = false,
--      priority = 1000,
--      config = function()
--        vim.cmd[[colorscheme tokyonight]]
--      end
--    },
    {
      'nvimdev/zephyr-nvim',
      lazy = false,
      priority = 1000,
      config = function() 
        vim.cmd[[colorscheme zephyr]]
      end
    },
--   {
--     "nyngwang/nvimgelion",
--     priority = 1000 , -- make sure to load this before all the other start plugins
--     config = function()
--       -- load the colorscheme here
--       vim.cmd([[colorscheme nvimgelion]])
--     end,
--   },
}

-- Setup lazy.nvim
require("lazy").setup(plugins)
