---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## Describe the bug

A clear and concise description of what the bug is.

## To Reproduce

Steps to reproduce the behavior:

1. Open file '...'
2. Run command '...'
3. See error

## Expected behavior

A clear and concise description of what you expected to happen.

## Environment

- OS: [e.g. macOS 14.0, Ubuntu 22.04]
- Neovim version: [output of `nvim --version`]
- Plugin version: [e.g. v0.1.0 or commit hash]
- dbt-lsp version: [output of `dbt-lsp --version`]

## Configuration

```lua
-- Your dbt-lsp.nvim configuration
require('dbt-lsp').setup({
  -- paste your config here
})
```

## Plugin Manager

- [ ] lazy.nvim
- [ ] packer.nvim
- [ ] vim-plug
- [ ] Other: _____

## Logs

<details>
<summary>LSP Logs</summary>

```
Paste output from :lua vim.cmd('edit ' .. vim.lsp.get_log_path())
```

</details>

<details>
<summary>Neovim Health</summary>

```
Paste output from :checkhealth
```

</details>

## Additional context

Add any other context about the problem here.
