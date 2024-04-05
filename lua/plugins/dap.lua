local js_based_languages = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

---@param config {args?:string[]|fun():string[]?}
local function get_args(config)
  local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
  config = vim.deepcopy(config)

  ---@cast args string[]
  config.args = function()
    ---@diagnostic disable-next-line: redundant-parameter
    local new_args = vim.fn.input("Run with args: ", table.concat(args, " ")) --[[@as string]]
    return vim.split(vim.fn.expand(new_args) --[[@as string]], " ")
  end

  return config
end

return {
  "mfussenegger/nvim-dap",
  dependencies = {
    { "stevearc/overseer.nvim", opts = { dap = false } },
    {
      "microsoft/vscode-js-debug",
      build = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
    },
    -- vscode-js-debug adapter
    {
      "mxsdev/nvim-dap-vscode-js",
      opts = {
        debugger_path = vim.fn.resolve(vim.fn.stdpath "data" .. "/lazy/vscode-js-debug"),
        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
      },
    },
    { "theHamsta/nvim-dap-virtual-text", opts = {} },
  },
  optional = true,
  keys = {
    {
      "<leader>da",
      function()
        if vim.fn.filereadable ".vscode/launch.json" then
          local dap_vscode = require "dap.ext.vscode"
          dap_vscode.json_decode = require("overseer.json").decode
          dap_vscode.load_launchjs(nil, {
            ["chrome"] = js_based_languages,
            ["node"] = js_based_languages,
            ["pwa-node"] = js_based_languages,
            ["pwa-chrome"] = js_based_languages,
            ["node-terminal"] = js_based_languages,
          })
        end
        require("dap").continue { before = get_args }
      end,
      desc = "Run with Args",
    },
  },
  config = function()
    local dap = require "dap"
    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "node",
        args = {
          require("mason-registry").get_package("js-debug-adapter"):get_install_path()
            .. "/js-debug/src/dapDebugServer.js",
          "${port}",
        },
      },
    }

    -- Use overseer for running preLaunchTask and postDebugTask.
    require("overseer").patch_dap(true)

    for _, language in ipairs(js_based_languages) do
      dap.configurations[language] = {
        -- Debug single nodejs files
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          -- cwd = vim.fn.getcwd(),
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
        -- Debug nodejs processes (make sure to add --inspect when you run the process)
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach",
          processId = require("dap.utils").pick_process,
          -- cwd = vim.fn.getcwd(),
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
        {
          type = "pwa-node",
          request = "launch",
          name = "Debug Jest Tests",
          runtimeExecutable = "node",
          runtimeArgs = { "${workspaceFolder}/node_modules/.bin/jest", "--runInBand" },
          rootPath = "${workspaceFolder}",
          -- cwd = vim.fn.getcwd(),
          cwd = "${workspaceFolder}",
          console = "integratedTerminal",
          internalConsoleOptions = "neverOpen",
          -- args = {'${file}', '--coverage', 'false'},
          -- sourceMaps = true,
          -- skipFiles = {'<node_internals>/**', 'node_modules/**'},
        },
        {
          type = "pwa-node",
          request = "launch",
          name = "Debug Vitest Tests",
          cwd = vim.fn.getcwd(),
          program = "${workspaceFolder}/node_modules/vitest/vitest.mjs",
          args = { "run", "${file}" },
          autoAttachChildProcesses = true,
          smartStep = true,
          skipFiles = { "<node_internals>/**", "node_modules/**" },
        },
        -- Debug web applications (client side)
        {
          type = "pwa-chrome",
          request = "launch",
          name = "Launch & Debug Chrome",
          url = function()
            local co = coroutine.running()
            return coroutine.create(function()
              vim.ui.input({ prompt = "Enter URL: ", default = "http://localhost:3000" }, function(url)
                if url == nil or url == "" then
                  return
                else
                  coroutine.resume(co, url)
                end
              end)
            end)
          end,
          webRoot = vim.fn.getcwd(),
          protocol = "inspector",
          sourceMaps = true,
          userDataDir = false,
        },
        -- Divider for the launch.json derived configs
        {
          name = "----- ↓ launch.json configs (if available) ↓ -----",
          type = "",
          request = "launch",
        },
      }
    end
  end,
}
