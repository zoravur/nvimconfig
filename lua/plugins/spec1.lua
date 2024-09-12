return {
-- LSP Support
   {
     "neovim/nvim-lspconfig",
     dependencies = {
       "hrsh7th/cmp-nvim-lsp",
       "hrsh7th/nvim-cmp",
   --    "L3MON4D3/LuaSnip",
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
  --     "L3MON4D3/LuaSnip",
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
 
     -- Enhanced syntax highlighting
   {
     'nvim-treesitter/nvim-treesitter',
     build = ':TSUpdate',
     config = function()
       require'nvim-treesitter.configs'.setup {
         ensure_installed = { "cpp", "c", "lua", "vim", "vimdoc", "query" },
         highlight = {
           enable = true,
           additional_vim_regex_highlighting = false,
         },
         indent = { enable = true },
       }
     end
   },
}
