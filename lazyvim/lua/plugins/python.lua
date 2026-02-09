return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- ty: type checking diagnostics only
      opts.servers.ty = {
        settings = {
          ty = {
            -- disableLanguageServices = true,
            -- showSyntaxErrors = false,
          },
        },
      }

      -- Pyright: language services only, no type checking or linting
      opts.servers.pyright = vim.tbl_deep_extend("force", opts.servers.pyright or {}, {
        settings = {
          pyright = {
            disableOrganizeImports = true,
          },
          python = {
            analysis = {
              ignore = { "*" },
              typeCheckingMode = "off",
            },
          },
        },
      })

      -- Ruff: linting, formatting, import sorting
      opts.servers.ruff = vim.tbl_deep_extend("force", opts.servers.ruff or {}, {
        init_options = {
          settings = {
            logLevel = "error",
          },
        },
        keys = {
          {
            "<leader>co",
            LazyVim.lsp.action["source.organizeImports"],
            desc = "Organize Imports",
          },
        },
      })

      -- Disable hover from ruff so pyright handles it
      opts.setup = opts.setup or {}
      opts.setup.ruff = function()
        Snacks.util.lsp.on({ name = "ruff" }, function(_, client)
          client.server_capabilities.hoverProvider = false
        end)
      end
    end,
  },

  -- Ensure mason installs all three
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "ruff",
        "ty",
        "pyright",
      },
    },
  },
}
