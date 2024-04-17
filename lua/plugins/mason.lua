-- Customize Mason plugins

---@type LazySpec
return {
  -- use mason-lspconfig to configure LSP installations
  {
    "williamboman/mason-lspconfig.nvim",
    -- overrides `require("mason-lspconfig").setup(...)`
    opts = function(_, opts)
      -- add more things to the ensure_installed table protecting against community packs modifying it
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "tsserver",
        "lua_ls",
        -- add more arguments for adding more language servers
      })
    end,
  },
  -- use mason-null-ls to configure Formatters/Linter installation for null-ls sources

  {
    "jay-babu/mason-null-ls.nvim",
    opts = function(_, opts)
      -- Ensures these tools are installed, avoiding modifications by other packages
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "eslint_d",
        "prettierd",
        "stylua",
      })

      opts.handlers = {
        -- Handler for prettierd formatting
        prettierd = function()
          require("null-ls").register(require("null-ls").builtins.formatting.prettierd.with {
            condition = function(utils)
              -- Checks for common Prettier configuration files
              return utils.root_has_file "package.json"
                or utils.root_has_file ".prettierrc"
                or utils.root_has_file ".prettierrc.json"
                or utils.root_has_file ".prettierrc.yaml"
                or utils.root_has_file ".prettierrc.yml"
                or utils.root_has_file ".prettierrc.js"
            end,
          })
        end,
      }
    end,
  },

  -- disable dap
  -- {
  --   "jay-babu/mason-nvim-dap.nvim",
  --   -- overrides `require("mason-nvim-dap").setup(...)`
  --   opts = function(_, opts)
  --     -- add more things to the ensure_installed table protecting against community packs modifying it
  --     opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
  --       "python",
  --       -- add more arguments for adding more debuggers
  --     })
  --   end,
  -- },
}
