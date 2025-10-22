# dbt-lsp.nvim

> Neovim plugin for dbt (data build tool) Language Server Protocol support

[![Tests](https://github.com/edmondop/dbt-lsp.nvim/actions/workflows/tests.yml/badge.svg)](https://github.com/edmondop/dbt-lsp.nvim/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- Easy integration with dbt LSP server
- Socket-based LSP communication
- Mason.nvim integration for simple installation
- Automatic dbt project detection (`dbt_project.yml`)
- Configurable socket port and settings
- Comprehensive test suite
- Works with SQL and YAML files

## Requirements

- Neovim 0.11.0+
- [mason.nvim](https://github.com/williamboman/mason.nvim) (optional, for easy installation)
- A dbt project with `dbt_project.yml`

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

**Simple setup (works with any Mason configuration):**

```lua
{
  'edmondop/dbt-lsp.nvim',
  dependencies = { 'williamboman/mason.nvim' },
  lazy = false,
  config = function()
    require('dbt-lsp').setup()
  end,
}
```

**Lazy-load on filetype (optional):**

```lua
{
  'edmondop/dbt-lsp.nvim',
  dependencies = { 'williamboman/mason.nvim' },
  ft = { 'sql', 'yaml' },
  config = function()
    require('dbt-lsp').setup()
  end,
}
```

> **Note:** The plugin automatically injects the dbt-lsp registry into Mason, regardless of how Mason is configured (lazy-loaded with `cmd = "Mason"`, eager-loaded, etc.). The registry injection uses multiple retry strategies to ensure it works in all scenarios.

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'edmondop/dbt-lsp.nvim',
  requires = { 'williamboman/mason.nvim' },  -- optional
  config = function()
    require('dbt-lsp').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'edmondop/dbt-lsp.nvim'

lua << EOF
require('dbt-lsp').setup()
EOF
```

## LSP Server Installation

### Option 1: Using Mason (Recommended)

The plugin automatically registers a custom Mason registry for dbt-lsp. Simply run:

```vim
:MasonInstall dbt-lsp
```

**How automatic registry injection works:**

The plugin uses multiple strategies to ensure the registry is injected regardless of your Mason configuration:

1. **Immediate injection**: When `setup()` is called, if Mason is already loaded
2. **Deferred injection**: Retries after 100ms and 1000ms delays (handles Mason loading shortly after)
3. **UIEnter hook**: Retries when UI finishes loading (handles lazy-loaded Mason)
4. **FileType trigger**: Retries when opening dbt files (handles `cmd = "Mason"` configs)

This means you **don't need to modify your Mason configuration** - the plugin works with any setup:
- `cmd = "Mason"` (lazy-load on command)
- `lazy = false` (eager load)
- Any custom priority or load order

For manual setup without a plugin manager:

```lua
require('mason').setup()
require('dbt-lsp').setup()  -- Registry auto-injected
```

### Option 2: Manual Installation

Install the latest version:

```bash
curl -fsSL https://raw.githubusercontent.com/dbt-labs/dbt-fusion/main/crates/dbt-common/assets/install.sh | sh -s -- --package dbt-lsp
```

Install a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/dbt-labs/dbt-fusion/main/crates/dbt-common/assets/install.sh | sh -s -- --package dbt-lsp --version 2.0.0-preview.45
```

This will install `dbt-lsp` to `~/.local/bin/dbt-lsp`.

To find available versions, check the [versions.json](https://public.cdn.getdbt.com/fs/versions.json) file.

## Health Check

Check your installation status:

```vim
:checkhealth dbt-lsp
```

This will verify:
- Neovim version (>= 0.11.0)
- Mason registry injection status (if Mason is installed)
- dbt-lsp binary installation
- dbt project detection

If the health check shows warnings about registry injection, it's likely just a timing issue. The registry will be automatically injected when Mason finishes loading or when you open a dbt file.

## Configuration

### Default Configuration

```lua
require('dbt-lsp').setup({
  cmd = { 'dbt-lsp' },
  filetypes = { 'sql', 'yaml' },
  root_dir = nil,
  settings = {},
  socket_port = 7658,
})
```

### Custom Configuration

```lua
require('dbt-lsp').setup({
  socket_port = 9000,
  filetypes = { 'sql' },
  settings = {
    dbt = {},
  },
})
```

### Advanced: Per-Project Configuration

You can set project-specific configuration using `vim.g.dbt_lsp_config`:

```lua
vim.g.dbt_lsp_config = {
  socket_port = 8000,
  root_dir = vim.fn.getcwd() .. '/dbt_project',
}
```

## Usage

Once installed and configured, the LSP will automatically start when you open SQL or YAML files within a dbt project (detected by the presence of `dbt_project.yml`).

### Example Project Structure

```
my-dbt-project/
├── dbt_project.yml          # Auto-detected root
├── models/
│   ├── staging/
│   │   └── stg_customers.sql  # LSP active here
│   └── marts/
│       └── dim_customers.sql  # LSP active here
└── macros/
    └── my_macro.sql          # LSP active here
```

### LSP Features

The features provided by the dbt LSP server are documented at [dbt-fusion](https://github.com/dbt-labs/dbt-fusion).

## Development

### Running Tests

```bash
make test
```

### Linting

```bash
make lint
```

### Formatting

```bash
make format
```

### Install Development Dependencies

```bash
make install-deps
```

## Testing the LSP

To manually test that the LSP server is working:

```bash
# Check if dbt-lsp is installed
which dbt-lsp

# Test the server (requires a dbt project)
dbt-lsp --socket 7658 --project-dir /path/to/your/dbt/project
```

## How It Works

Unlike standard LSP servers that communicate via stdin/stdout, the dbt LSP uses **socket-based communication**. This plugin:

1. Detects when you open a file in a dbt project
2. Finds the project root by locating `dbt_project.yml`
3. Starts the dbt-lsp server with the `--socket` and `--project-dir` flags
4. Connects the Neovim LSP client to the socket

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `make test`
5. Run linting: `make lint`
6. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details

## Acknowledgments

- [dbt-labs](https://github.com/dbt-labs/dbt-fusion) for the dbt LSP server
- [mason.nvim](https://github.com/williamboman/mason.nvim) for the package manager framework

## Support

- [Report bugs](https://github.com/edmondop/dbt-lsp.nvim/issues)
- [Discussions](https://github.com/edmondop/dbt-lsp.nvim/discussions)
- [Documentation](https://github.com/edmondop/dbt-lsp.nvim/wiki)
