-- Instalar o lazy nvim se não tiver sido instalado ainda
-- guardar na pasta stdpath("data")/lazy/lazy.nvim
-- No linux fica em ~/.local/share/nvim/lazy/lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

local l = require"home.list"
local function has_lazy_plugin(plugin)
  local plugins = l.filter(require("lazy").plugins(), function(p) return p.name == plugin end)
  return (#plugins) >= 1
end

-- Utility function to extend or override a config table, similar to the way
-- that Plugin.opts works.
---@param config table
---@param custom function | table | nil
local function extend_or_override(config, custom, ...)
  if type(custom) == "function" then
    config = custom(config, ...) or config
  elseif custom then
    config = vim.tbl_deep_extend("force", config, custom) --[[@as table]]
  end
  return config
end

-- Configurar plugins
require("lazy").setup({
	{
    "dracula/vim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd("colorscheme dracula")
    end
	},
	"nvim-lua/plenary.nvim",

  -- Treesitter: colorir trechos do código conforme a linguagem de programação do arquivo aberto
	{
		"nvim-treesitter/nvim-treesitter",
		config = function()
			vim.cmd.TSUpdate()

			local nvim_configs = require("nvim-treesitter.configs")
			nvim_configs.setup({
				ensure_installed = {
					"c",
					"lua",
					"vim",
					"rust",
					"vimdoc",
					"query",
					"markdown",
					"markdown_inline",
					"haskell",
          "java",
				},

				-- Instalar parsers sincronamente (only applied to `ensure_installed`)
				sync_install = false,

				auto_install = true,

				-- Lista de parsers para ignorar a instalação (ou "all")
				ignore_install = { "javascript" },
				highlight = {
					enable = true,
				},
			})
		end,
	},

  -- Telescope: busca em arquivos
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		config = function()
			local builtin = require("telescope.builtin")

      -- Buscar entre os nomes dos arquivos
			vim.keymap.set("n", "<leader>pf", builtin.find_files)
      -- Buscar no conteúdo dos arquivos
			vim.keymap.set("n", "<leader>ps", function()
				builtin.grep_string({ search = vim.fn.input("Grep >") })
			end)

      -- Buscar no conteúdo dos arquivos monitorados pelo git
			vim.keymap.set("n", "<leader>gs", builtin.git_files, {})
		end,
	},

  -- Harpoon: janela de arquivos favoritos
	{
		"ThePrimeagen/harpoon",
		config = function()
			local mark = require("harpoon.mark")
			local ui = require("harpoon.ui")

      -- Adicionar arquivo atual nos favoritos
			vim.keymap.set("n", "<leader>ah", mark.add_file)

      -- Listar arquivos favoritos
			vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

      -- Outros atalhos:
      -- "dd" = dentro da lista de favoritos, remover o arquivo sob o cursor
      -- "q"  = fechar a janela de favoritos
		end,
	},

  -- Undotree: Gerenciar versões do arquivo no computador 
	{
		"mbbill/undotree",
		config = function()
      -- Abrir ao lado árvore de versões do arquivo
			vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
		end,
	},

  -- Configuração do LSP
  {
    -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },

    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      -- Mason must be loaded before its dependents so we need to set it up here.
      -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
      { 'mason-org/mason.nvim', opts = { ensure_installed = { "java", "java-debug-adapter" } }, },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by blink.cmp
      {
        'saghen/blink.cmp',
        version = "1.*",
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {

          keymap = {
            -- super-tab para ter atalhos semelhantes ao VSCode
            preset = 'super-tab',
          },
          -- Default list of enabled providers defined so that you can extend it
          -- elsewhere in your config, without redefining it, due to `opts_extend`
          sources = {
            default = { 'lsp', 'path', 'snippets', 'buffer' },
          },
          fuzzy = { implementation = "prefer_rust_with_warning" },

          -- Toggle do autocomplete
          enabled = function()
            if vim.b.completion == nil then
              return true
            end
            return vim.b.completion
          end
        }
      },
    },
    opts = {
      setup = {
        jdtls = function()
          return true
        end
      }
    },

		config = function()
      -- Toggle do autocomplete: se estiver ligado, desligar, e se
      -- estiver desligado, ligar
      vim.keymap.set("n", "<leader>at", function()
        if vim.b.completion == nil then
          vim.b.completion = true
        end
        vim.b.completion = not vim.b.completion
      end)

			require("home.lsp")
		end,
	},

  -- LSP de Java integrado ao DAP
  -- Requer baixar o java-debug: https://github.com/microsoft/java-debug
  --   1. Ir em releases e baixar a ultima versao
  --   2. Extrair o fonte e instalar com o comando:
  --      ./mvnw clean install -Djdk.xml.maxGeneralEntitySizeLimit=1000000 -Djdk.xml.totalEntitySizeLimit=1000000
  --
  -- Requer inicializar a aplicação com jvmArgs: 
  {
    "mfussenegger/nvim-jdtls",
    priority = -20,
    ft = { "java" },
    opts = function()
      local cmd = { vim.fn.exepath("jdtls") }
      if has_lazy_plugin("mason.nvim") then
        local lombok_jar = vim.fn.expand("$MASON/share/jdtls/lombok.jar")
        table.insert(cmd, string.format("--jvm-arg=-javaagent:%s", lombok_jar))
      end
      return {
        root_dir = function(path)
          return vim.fs.root(path, vim.lsp.config.jdtls.root_markers)
        end,

        -- How to find the project name for a given root dir.
        project_name = function(root_dir)
          return root_dir and vim.fs.basename(root_dir)
        end,

        -- Where are the config and workspace dirs for a project?
        jdtls_config_dir = function(project_name)
          return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/config"
        end,
        jdtls_workspace_dir = function(project_name)
          return vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"
        end,

        -- How to run jdtls. This can be overridden to a full java command-line
        -- if the Python wrapper script doesn't suffice.
        cmd = cmd,
        full_cmd = function(opts)
          local fname = vim.api.nvim_buf_get_name(0)
          local root_dir = opts.root_dir(fname)
          local project_name = opts.project_name(root_dir)
          local cmd = vim.deepcopy(opts.cmd)
          if project_name then
            vim.list_extend(cmd, {
              "-configuration",
              opts.jdtls_config_dir(project_name),
              "-data",
              opts.jdtls_workspace_dir(project_name),
            })
          end
          return cmd
        end,

        -- These depend on nvim-dap, but can additionally be disabled by setting false here.
        dap = { hotcodereplace = "auto", config_overrides = {} },
        -- Can set this to false to disable main class scan, which is a performance killer for large project
        dap_main = {},
        test = true,
        settings = {
          java = {
            inlayHints = {
              parameterNames = {
                enabled = "all",
              },
            },
          },
        },
      }
    end,
    config = function(_, opts)
      -- Find the extra bundles that should be passed on the jdtls command-line
      -- if nvim-dap is enabled with java debug/test.
      local bundles = {} ---@type string[]
      if has_lazy_plugin("mason.nvim") then
        local mason_registry = require("mason-registry")
        if opts.dap and has_lazy_plugin("nvim-dap") and mason_registry.is_installed("java-debug-adapter") then
          bundles = vim.fn.glob("$MASON/share/java-debug-adapter/com.microsoft.java.debug.plugin-*jar", false, true)
          -- java-test also depends on java-debug-adapter.
          if opts.test and mason_registry.is_installed("java-test") then
            vim.list_extend(bundles, vim.fn.glob("$MASON/share/java-test/*.jar", false, true))
          end

        end
      end
      local function attach_jdtls()
        local fname = vim.api.nvim_buf_get_name(0)

        -- Configuration can be augmented and overridden by opts.jdtls
        local config = extend_or_override({
          cmd = opts.full_cmd(opts),
          root_dir = opts.root_dir(fname),
          init_options = {
            bundles = bundles,
          },
          settings = opts.settings,
          -- enable CMP capabilities
          capabilities = has_lazy_plugin("cmp-nvim-lsp") and require("cmp_nvim_lsp").default_capabilities() or nil,
        }, opts.jdtls)

        -- Existing server will be reused if the root_dir matches.
        require("jdtls").start_or_attach(config)
        -- not need to require("jdtls.setup").add_commands(), start automatically adds commands
      end

      -- Attach the jdtls for each java buffer. HOWEVER, this plugin loads
      -- depending on filetype, so this autocmd doesn't run for the first file.
      -- For that, we call directly below.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "java" },
        callback = attach_jdtls,
      })

      -- Setup keymap and dap after the lsp is fully attached.
      -- https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
      -- https://neovim.io/doc/user/lsp.html#LspAttach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "jdtls" then

            if has_lazy_plugin("mason.nvim") then
              local mason_registry = require("mason-registry")
              if opts.dap and has_lazy_plugin("nvim-dap") and mason_registry.is_installed("java-debug-adapter") then
                -- custom init for Java debugger
                require("jdtls").setup_dap(opts.dap)
                if opts.dap_main then
                  require("jdtls.dap").setup_dap_main_class_configs(opts.dap_main)
                end
              end
            end

            -- User can set additional keymaps in opts.on_attach
            if opts.on_attach then
              opts.on_attach(args)
            end
          end
        end,
      })

      -- Avoid race condition by calling attach the first time, since the autocmd won't fire.
      attach_jdtls()
    end,
  },

  {
    'mfussenegger/nvim-dap',
    dependencies = {
      -- Creates a beautiful debugger UI
      'rcarriga/nvim-dap-ui',

      -- Required dependency for nvim-dap-ui
      'nvim-neotest/nvim-nio',

      -- Installs the debug adapters for you
      'mason-org/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',

    },
    keys = {
      -- Basic debugging keymaps, feel free to change to your liking!
      {
        '<F5>',
        function()
          require('dap').continue()
        end,
        desc = 'Debug: Start/Continue',
      },
      {
        '<F11>',
        function()
          require('dap').step_into()
        end,
        desc = 'Debug: Step Into',
      },
      {
        '<F10>',
        function()
          require('dap').step_over()
        end,
        desc = 'Debug: Step Over',
      },
      {
        '<F3>',
        function()
          require('dap').step_out()
        end,
        desc = 'Debug: Step Out',
      },
      {
        '<leader>b',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'Debug: Toggle Breakpoint',
      },
      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      {
        '<F7>',
        function()
          require('dapui').toggle()
        end,
        desc = 'Debug: See last session result.',
      },
    },
    opts = function()
      local dap = require("dap")
      dap.configurations.java = {
        {
          type = "java",
          request = "attach",
          name = "Debug (Attach) - Remote",
          hostName = "127.0.0.1",
          port = 5005,
        }
      }
    end,
    config = function()
      local dap = require"dap"
      local dapui = require"dapui"

      require("mason-nvim-dap").setup {
        -- Makes a best effort to setup the various debuggers with
        -- reasonable debug configurations
        automatic_installation = true,

        -- You can provide additional configuration to the handlers,
        -- see mason-nvim-dap README for more information
        handlers = {},

        -- You'll need to check that you have the required things installed
        -- online, please don't ask me how to install them :)
        ensure_installed = {
          -- Update this to ensure that you have the debuggers for the langs you want
          "java"
        },
      }

      -- Dap UI setup
      -- For more information, see |:help nvim-dap-ui|
      dapui.setup {
        -- Set icons to characters that are more likely to work in every terminal.
        --    Feel free to remove or use ones that you like more! :)
        --    Don't feel like these are good choices.
        icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
        controls = {
          enabled = true,
          icons = {
            pause = '⏸',
            play = '▶',
            step_into = '⤵️',
            step_over = '↪️',
            step_out = '⤴️',
            step_back = 'b',
            run_last = '▶▶',
            terminate = '⏹',
            disconnect = '⏏',
          },
        },
      }

      -- Change breakpoint icons
      vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
      vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
      local breakpoint_icons = vim.g.have_nerd_font
          and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
        or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
      for type, icon in pairs(breakpoint_icons) do
        local tp = 'Dap' .. type
        local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
        vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
      end

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close

    end,
  },

  { "nanotee/sqls.nvim",
    lazy = false,
    config = function()
      vim.keymap.set("v", "<leader>sqx", function()
        local enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
        vim.api.nvim_feedkeys(":SqlsExecuteQuery" .. enter, "n", false)
      end)
      vim.keymap.set("n", "<leader>sqlco", vim.cmd.SqlsShowConnections)
      vim.keymap.set("n", "<leader>sqldb", vim.cmd.SqlsShowDatabases)
      vim.keymap.set("n", "<leader>sqco", vim.cmd.SqlsSwitchConnection)
      vim.keymap.set("n", "<leader>sqdb", vim.cmd.SqlsSwitchDatabase)
    end
  },

})
