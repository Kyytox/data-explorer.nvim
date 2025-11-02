<div align="center">

# data-explorer.nvim

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.8+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
[![DuckDB](https://img.shields.io/badge/DuckDB-orange.svg?style=for-the-badge&logo=duckdb)](https://duckdb.org)
[![Telescope](https://img.shields.io/badge/Telescope-purple.svg?style=for-the-badge&logo=nvim-telescope)](https://github.com/nvim-telescope/telescope.nvim)

**Preview**, **Explore**, and **Query** your data files (`parquet`, `csv`, `tsv`) directly inside Neovim

Powered by **DuckDB** and **Telescope**.

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
- [Usage Example](#-usage-example)
- [Limitations](#%EF%B8%8F-limitations)
- [Performances](#-performances)
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

- [**Neovim ≥ 0.10**](https://neovim.io)
- [**DuckDB**](https://duckdb.org), installed and available in your PATH
  (`duckdb` command must be executable from your terminal)
- [**telescope.nvim**](https://www.github.com/nvim-telescope/telescope.nvim)
- [**fd**](https://github.com/sharkdp/fd?tab=readme-ov-file#installation)

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
  dependencies = { "nvim-telescope/telescope.nvim" },
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
require("data-explorer").setup({
	limit = 250, -- Maximum number of rows to fetch
	layout = "vertical", -- Vertical or horizontal
	files_types = {
		parquet = true,
		csv = true,
		tsv = true,
	},

	-- UI/Telescope options
	telescope_opts = {
		layout_strategy = "vertical",
		layout_config = {
			height = 0.4,
			width = 0.9,
			preview_cutoff = 1,
			preview_height = 0.5, -- Used for vertical layout
			preview_width = 0.4, -- Used for horizontal layout
		},
		finder = {
			include_hidden = false, -- Show hidden files
			exclude_dirs = { ".git", "node_modules", "__pycache__", "venv", ".venv" },
		},
	},

	-- Floating window options for main display windows
	window_opts = {
		border = "rounded",
		max_height_metadata = 0.25,
		max_width_metadata = 0.25,
	},

	-- Query SQL
	query_sql = {
		-- Lines displayed in the SQL window when opened
		placeholder_sql = {
			"SELECT * FROM f LIMIT 1000;",
			"-- Warning: Large result could slow down / crash.",
			"-- To query the file, use 'f' as the table name.",
		},
	},

	-- Key mappings
	mappings = {
		quit = "q", -- Close the main UI
		back = "<BS>", -- Go back to file selection
		focus_meta = "1", -- Focus the metadata window
		focus_data = "2", -- Focus the data window
		toggle_sql = "3", -- Toggle the SQL query window
		rotate_layout = "r", -- Rotate the layout
		execute_sql = "e", -- Execute the SQL query
	},

	-- Highlight colors
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

For more details on configuration options:

- [Details Configurations](https://github.com/Kyytox/data-explorer.nvim/blob/master/doc/data-explorer.nvim.txt): TXT file
- `:help data-explorer.nvim`: Neovim help

<br>

## 🚀 API

### DataExplorer

Search for and preview supported data files:

```vim
:lua require("data-explorer").DataExplorer()
```

```
:DataExplorer
```

Telescope will show a list of supported data files in your current working directory.
Selecting a file opens it in the DataExplorer view with metadata and table view.

### DataExplorerFile

Open the currently edited file in DataExplorer (if supported):

```vim
:lua require("data-explorer").DataExplorerFile()
```

```
:DataExplorerFile
```

This bypasses Telescope and directly loads the file into the explorer.

<br>

# 🧠 Usage Example

1. Run `:DataExplorer` to open the Telescope file picker.
2. Select a file
3. Explore the file:

- 1 → focus Metadata
- 2 → focus Data Table
- 3 → toggle SQL editor

4. Write SQL queries using `f` as the table name.
5. Press **e** to execute and view results instantly.
6. Press **q** to quit the explorer.

<br>

## ⚠️ Limitations

- The larger the file, the more time it will take to display the metadata and data, and will consume significant memory.
- Default view limits data to **250 rows** (configurable).
- When running **custom SQL queries**, there is **no default limit** — you must specify one manually (e.g., `SELECT * FROM data LIMIT 100;`).
- Emojis and certain special characters (not all) in data may not render correctly (small column shifts)

<br>

## 📏 Performances

The following table shows approximate load and query times
The file is a copy of [nasa-exoplanet archive data](https://exoplanetarchive.ipac.caltech.edu/cgi-bin/TblView/nph-tblView?app=ExoTbls&config=PS) with a lot of lines duplicated.

With a PC with:

- CPU: AMD Ryzen™ 7 7700 x 16
- RAM: 32 GB
- OS: Arch Linux
- DuckDB version: 0.8.1

There Test are made with different limits for the data view: 250, 1000, 5000 and 20 000 rows.

<br>

| File Type | File Size | Total Rows | Avg Time (250) | Avg Time (1k) | Avg Time (5k) | Avg Time (20k) |
| --------- | --------- | ---------- | -------------- | ------------- | ------------- | -------------- |
| Parquet   | 9 MB      | 500 000    | 0.00339 s      | 0.01183 s     | 0.05608 s     | 0.23005 s      |
| Parquet   | 19 MB     | 1 003 391  | 0.00352 s      | 0.01331 s     | 0.06220 s     | 0.26294 s      |
| CSV       | 31 MB     | 38 170     | 0.00313 s      | 0.01181 s     | 0.05682 s     | 0.24263 s      |
| CSV       | 84 MB     | 101 553    | 0.00352 s      | 0.01306 s     | 0.06429 s     | 0.27679 s      |
| TSV       | 31 MB     | 38 170     | 0.00348 s      | 0.01219 s     | 0.06060 s     | 0.25841 s      |
| TSV       | 84 MB     | 101 553    | 0.00396 s      | 0.01302 s     | 0.06709 s     | 0.28249 s      |

> [!NOTE]
> But who display 20K rows

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
- Metadata personalization
- SQL Query history and favorites

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

## 📜 License

MIT License © 2025 Kyytox
