# <center>Data-Explorer.nvim</center>

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.8+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
[![DuckDB](https://img.shields.io/badge/DuckDB-orange.svg?style=for-the-badge&logo=duckdb)](https://duckdb.org)
[![Telescope.nvim](https://img.shields.io/badge/Telescope-purple.svg?style=for-the-badge&logo=nvim-telescope)](https://nvim-telescope.github.io/)

Explore, preview, and query your data files directly inside Neovim — powered by **DuckDB** and **Telescope**.

---

- [Caution](#caution)
- [Requirements](#requirements)
- [Features](#features)
- [Installation](#installation)
- [Config](#config)
  - [Default Configuration](#default-configuration)
  - [Parameters Details](#parameters-details)
- [API](#api)
  - [DataExplorer Command](#dataexplorer-command)
  - [DataExplorerFile Command](#dataexplorerfile-command)
- [SQL Queries](#sql-queries)
- [Architecture](#architecture)
- [Limitations](#limitations)
- [Future Plans](#future-plans)
- [Motivation](#motivation)
- [Contribute & Bug Reports](#contribute--bug-reports)
- [License](#license)

---

## 🚧 Caution

This plugin is still under active development.
If you encounter issues, have ideas for improvements, or want to contribute — please open an issue or a pull request!

---

## ⚡️ Requirements

- **Neovim ≥ 0.8**
- **DuckDB** installed and available in your PATH
  (`duckdb` command must be executable from your terminal)
- **nvim-telescope/telescope.nvim**
- **nvim-lua/plenary.nvim**

---

## 🎄 Features

| Feature      | Description                        |
| ------------ | ---------------------------------- |
| File types   | `.parquet`, `.csv`, `.tsv`         |
| UI           | Telescope + floating windows       |
| Commands     | `DataExplorer`, `DataExplorerFile` |
| Configurable | Limit, Layouts, mappings, colors   |
| SQL Support  | [DuckDB](https://duckdb.org)       |

- **Telescope integration** – search and preview files with metadata preview
- **Metadata display** – show column names, types, and other details
- **Table view** – display file contents in a formatted, colorized table
- **DuckDB backend** – use SQL to explore data interactively
- **Custom SQL queries** – run SQL queries on your data, see results instantly
- **Configurable UI & colors** – floating windows, layout control, highlights

---

## 🔌 Installation

Example with **lazy.nvim**:

```lua
{
  "yourname/DataExplorer.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
  config = function()
    require("data-explorer").setup()
  end,
}
```

Or with **vim-plug**:

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'kyytox/data-explorer.nvim'
```

---

## SQL Queries

From the main Data view:

- Press **`3`** to toggle the SQL query window.
- Write any valid DuckDB SQL query.
- Press **`e`** to execute it.
- Errors (if any) appear in a separate floating window.

> Tip: When writing your own SQL queries, **remember to use a `LIMIT` clause** — otherwise large files may take a long time to load or cause high memory usage.

---

## ⚙️ Config

### Default Configuration

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
      header = "#8b1d21",
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

---

## 🚀 API

### DataExplorer

Search for and preview supported data files:

```vim
:lua require("data-explorer").DataExplorer()
```

Telescope will show available `.parquet`, `.csv`, and `.tsv` files.
Selecting a file opens it in the DataExplorer view with metadata and table view.

### DataExplorerFile

Open the currently edited file in DataExplorer (if supported):

```vim
:lua require("data-explorer").DataExplorerFile()
```

This bypasses Telescope and directly loads the file into the explorer.

---

## ⛩️ Architecture

```
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
                       │ └────────────┘ │     │        │
    ┌─────────────┐    │ ┌────────────┐ ◄─────┘        │
    │  SQL Error  │    │ │  Metadata  │ │              │
    └──────▲──────┘    │ │  Metadata  │ │              │
           │           │ └────────────┘ │              │Back
           │           │ ┌────────────┐ │              │to Files
           │           │ │    Data    │ │              │Selection
    ┌──────┴──────┐    │ │            │ │              │
    │  SQL Query  ◄────┤ │    Data    │ ├──────────────┘
    │    Prompt   │    │ │            │ │
    └──────┬──────┘    │ │    Data    │ │
           │           │ └────────────┘ │
           │           └────────▲───────┘
           │                    │
           └────────────────────┘
```

## ⚠️ Limitations

- Not optimized for **large datasets** — reading big `.parquet` or `.csv` files may consume significant memory.
- Default view limits data to **250 rows** (configurable).
- When running **custom SQL queries**, there is **no default limit** — you must specify one manually (e.g., `SELECT * FROM data LIMIT 100;`).
- Emojis and special characters (not all) in data may not render correctly (small column shifts)

---

## 📜 Future Plans

- Support for more formats (`.json`, `.sqlite`, etc.)
- Smarter preview caching
- SQL Query history and favorites

---

## 💪 Motivation

Inspecting `.parquet`, `.csv`, or `.tsv` files directly in Neovim has always been a pain.
Most tools either require leaving the editor or converting data manually.
**DataExplorer.nvim** was created to make exploring and querying structured data files easy — without leaving Neovim.

---

## 🫵🏼 Contribute & Bug Reports

PRs and feedback are welcome!
If you want to help improve performance, extend support for new formats, or enhance the UI — please open a PR or issue.

---

## License

MIT License © 2025 Kyytox
