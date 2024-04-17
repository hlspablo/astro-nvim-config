return {
  "stevearc/conform.nvim",
  opts = {
    format_on_save = {
      timeout_ms = 3000,
      lsp_fallback = true,
    },
    formatters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      javascriptreact = { "eslint_d" },
    },
  },
}
