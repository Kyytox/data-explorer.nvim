<div align="center">

# data-explorer.nvim

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.8+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
[![DuckDB](https://img.shields.io/badge/DuckDB-orange.svg?style=for-the-badge&logo=duckdb)](https://duckdb.org)
[![Telescope](https://img.shields.io/badge/Telescope-purple.svg?style=for-the-badge&logo=nvim-telescope)](https://github.com/nvim-telescope/telescope.nvim)

**Preview**, **Explore**, and **Query** your data files directly inside Neovim — powered by **DuckDB** and **Telescope**.

</div>

---

- [Caution](#-caution)
- [Requirements](#%EF%B8%8F-requirements)
- [Features](#-features)
- [Installation](#-installation)
- [Config](#%EF%B8%8F-config)
- [API](#-api)
  - [DataExplorer](#dataexplorer)
  - [DataExplorerFile](#dataexplorerfile)
- [Limitations](#%EF%B8%8F-limitations)
- [Architecture](#%EF%B8%8F-architecture)
- [Future Plans](#-future-plans)
- [Motivation](#-motivation)
- [Contribute & Bug Reports](#-contribute--bug-reports)
- [License](#-license)

---

## 🚧 Caution

This plugin is still under active development.
If you encounter issues, have ideas for improvements, or want to contribute — please open an issue or a pull request!

<br>

## ⚡️ Requirements

- **Neovim ≥ 0.8**
- [**DuckDB**](https://duckdb.org), installed and available in your PATH
  (`duckdb` command must be executable from your terminal)
- [**telescope.nvim**](https://www.github.com/nvim-telescope/telescope.nvim)
- [**plenary.nvim**](https://github.com/nvim-lua/plenary.nvim)

<br>

## 🎄 Features

| Feature            | Description                                           |
| ------------------ | ----------------------------------------------------- |
| Supported Formats  | `.parquet`, `.csv`, `.tsv`                            |
| SQL system         | [DuckDB](https://duckdb.org)                          |
| File Search        | Find data files using Telescope                       |
| Metadata Display   | Show column names, types, and other details           |
| Table View         | Display file contents in a formatted, colorized table |
| Custom SQL Queries | Run SQL queries on your data, see results instantly   |
| Configurable       | Limit, Layouts, mappings, colors, highlights          |
| Commands           | `DataExplorer`, `DataExplorerFile`                    |

<br>

## 🔌 Installation

Example with **lazy.nvim**:

```lua
{
  "kyytox/data-explorer.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
  config = function()
    require("data-explorer").setup()
  end,
}
```

Or with **vim-plug**:

```vim
Plug 'kyytox/data-explorer.nvim'
```

<br>

## ⚙️ Config

```lua
require("dataexplorer").setup({
  limit = 250, -- Max number of rows to fetch
  layout = "vertical", -- "vertical" or "horizontal"
  files_types = {
    parquet = true,
    csv = true,
    tsv = true,
  },

	-- Placeholder SQL query
	-- This is shown when opening the SQL window before any query is written
	placeholder_sql = {
		"SELECT * FROM f LIMIT 1000;",
		"-- Warning: Large result could slow down / crash.",
		"-- To query the file, use 'f' as the table name.",
	},

  telescope_opts = {
    layout_strategy = "vertical",
    layout_config = {
      height = 0.4,
      width = 0.9,
      preview_cutoff = 1,
      preview_height = 0.5,
      preview_width = 0.4,
    },
  },

  window_opts = {
    border = "rounded",
    max_height_metadata = 0.30, -- percent of total height (horizontal)
		max_width_metadata = 0.25,  -- percent of total width (vertical)
  },

  mappings = {
    quit = "q",
    back = "<BS>",
    focus_meta = "1",
    focus_data = "2",
    toggle_sql = "3",
    rotate_layout = "r",
    execute_sql = "e",
  },

  hl = {
    windows = {
      bg = "#11111b",
      fg = "#cdd6f4",
      title = "#f5c2e7",
      footer = "#a6e3a1",
      sql_fg = "#89b4fa",
      sql_bg = "#1e1e2e",
      sql_err_fg = "#f38ba8",
      sql_err_bg = "#3b1d2a",
    },
    buffer = {
      hl_enable = true,
      header = "white",
      col1 = "#f38ba8",
      col2 = "#89b4fa",
      col3 = "#a6e3a1",
      col4 = "#f9e2af",
      col5 = "#cba6f7",
      col6 = "#94e2d5",
      col7 = "#f5c2e7",
      col8 = "#89b4fa",
      col9 = "#a6e3a1",
    },
  },
})
```

For more details on configuration options: [Details Configurations](https://github.com/Kyytox/data-explorer.nvim/blob/master/doc/data-explorer.nvim.txt)

<br>

## 🚀 API

### DataExplorer

Search for and preview supported data files:

```vim
:lua require("data-explorer").DataExplorer()
```

Telescope will show a list of supported data files in your current working directory.
Selecting a file opens it in the DataExplorer view with metadata and table view.

### DataExplorerFile

Open the currently edited file in DataExplorer (if supported):

```vim
:lua require("data-explorer").DataExplorerFile()
```

This bypasses Telescope and directly loads the file into the explorer.

<br>

## ⚠️ Limitations

- Not optimized for **large datasets** — reading big `.parquet` or `.csv` files may consume significant memory.
- Default view limits data to **250 rows** (configurable).
- When running **custom SQL queries**, there is **no default limit** — you must specify one manually (e.g., `SELECT * FROM data LIMIT 100;`).
- Emojis and special characters (not all) in data may not render correctly (small column shifts)

<br>

## ⛩️ Architecture

````
                        ┌────────────┐
                   ┌────┼  Commands  ┼────┐
                   │    └────────────┘    │
                   │                      │
         ┌─────────▼──────────┐  ┌────────▼───────┐
         │  DataExplorerFile  │  │  DataExplorer  ├───────┐
         └─────────────┬──────┘  └────────────────┘       │
                       │                                  │
                       └─────┐                     ┌──────▼──────┐
                             │                ┌────┤  Telescope  │
                       ┌─────▼──────────┐     │    └───▲─────────┘
                       │ ┌────────────┐ │     │        │
                       │ │  Metadata  │ │     │        │
    ┌─────────────┐    │ │  Metadata  │ ◄─────┘        │
    │  SQL Error  │    │ └────────────┘ │              │
    └──────▲──────┘    │ ┌────────────┐ │              │
           │           │ │    Data    │ │              │Back
           │           │ │            │ │              │to Files
           │           │ │    Data    │ │              │Selection
    ┌──────┴──────┐    │ │            │ │              │
    │  SQL Query  ◄────┤ │    Data    │ ├──────────────┘
    │    Prompt   │    │ │            │ │
    └──────┬──────┘    │ │    Data    │ │
           │           │ └────────────┘ │
           │           └────────▲───────┘
           │                    │
           └────────────────────┘                                 ```
````

<br>

## 📜 Future Plans

- Support for more formats (`.json`, `.sqlite`, etc.)
- Smarter preview caching
- SQL Query history and favorites

<!-- --- -->

<br>

## 💪 Motivation

Exploring `.parquet` files directly in Neovim has always been a pain.
Most tools either require leaving the editor or converting data manually.
**DataExplorer.nvim** was created to make exploring and querying structured data files easy — without leaving Neovim.

<br>

## 🫵🏼 Contribute & Bug Reports

PRs and feedback are welcome!
If you want to help improve performance, extend support for new formats, or enhance the UI — please open a PR or issue.

<br>

## License

MIT License © 2025 Kyytox
