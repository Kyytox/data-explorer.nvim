# Data Explorer

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

---

# 🦆 DataExplorer.nvim

> Explore, preview, and query your data files (`.parquet`, `.csv`, `.tsv`, `.json`) directly inside Neovim — powered by [DuckDB](https://duckdb.org/) and [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).

---

## ⚠️ WIP

This plugin is still in early development.
If you encounter bugs, want to suggest improvements, or just want to discuss ideas, please [open an issue](https://github.com/yourname/dataexplorer.nvim/issues) — feedback is super welcome!

---

## 🎯 Motivation

Working with `.parquet` files in Neovim was always a pain — there was no simple way to **inspect metadata** or **preview data** without leaving the editor.

`DataExplorer.nvim` was born to fix that.
It lets you **browse structured data files**, **view metadata**, and **run SQL queries** directly inside Neovim using DuckDB as the backend engine.

It’s perfect for:

- Data engineers exploring datasets
- Developers debugging CSV/JSON logs
- Anyone curious about the content of tabular files without opening a heavy IDE

---

## ⚙️ Requirements

- **Neovim ≥ 0.9**
- **[DuckDB](https://duckdb.org/docs/installation/index.html)** installed and available in your `$PATH`
- **[Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)**
- **[plenary.nvim](https://github.com/nvim-lua/plenary.nvim)**

---

## 🚀 Installation

Example using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "yourname/dataexplorer.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
  config = function()
    require("dataexplorer").setup()
  end,
}
```

---

## 🧩 Features

- 📂 Browse `.parquet`, `.csv`, `.tsv`, `.json` files from Telescope
- 🧠 Preview **file metadata** (columns, types, row count, etc.)
- 📊 View data in a **scrollable table view** inside Neovim
- 🧮 Run **SQL queries** directly on the selected file
- ⚠️ Display **query errors** in a dedicated floating window
- ⚡ Limit row preview size to avoid loading huge files (default: 10,000 rows)

---

## 🔧 Commands

| Command             | Description                                                                                                        |
| ------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `:DataExplorer`     | Opens Telescope to select a supported data file and preview metadata. Once selected, displays the table view.      |
| `:DataExplorerFile` | Opens the current buffer’s file directly (if it’s a supported format). Same as `DataExplorer` but skips Telescope. |

---

## 🧠 Usage

### 🔍 Browse & Preview

Launch the file browser:

```vim
:DataExplorer
```

This opens Telescope where you can fuzzy-search for `.parquet`, `.csv`, `.tsv`, or `.json` files.
Preview shows metadata (columns, types, number of rows).
Press `<CR>` to open the selected file in **table view**.

### 🧮 Query the Data

Once in table view, open the query prompt:

```
:DataExplorerQuery
```

Write your SQL (DuckDB syntax). Example:

```sql
SELECT column1, COUNT(*) FROM file GROUP BY column1 LIMIT 100;
```

Results will be displayed in the same floating table window.
If there’s a syntax or execution error, it appears in an **SQL Error window**.

> ⚠️ DuckDB is not optimized for very large datasets —
> a **default limit of 10,000 rows** is enforced when previewing data.
> You can override this limit manually in your SQL query (e.g. `LIMIT 5000`).

---

## 🧰 Configuration

You can customize the behavior via `setup()`:

```lua
require("dataexplorer").setup({
  default_limit = 10000, -- default row limit for previews
  window = {
    width = 0.8,
    height = 0.6,
  },
})
```

---

## 🪶 Telescope Integration

The plugin registers itself as a Telescope picker.

To load it manually:

```lua
require("telescope").load_extension("dataexplorer")
```

Then call:

```vim
:Telescope dataexplorer files
```

---

## 🧩 Architecture Overview

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

---

## 🧱 Limitations

- DuckDB works best with **small to medium-sized datasets**.
  Large files may cause slowdowns or crashes.
- When running custom SQL queries, **no limit** is enforced unless you add one manually (`LIMIT 10000`).
- Currently, only **local files** are supported (no S3, HTTP, etc.).

---

## 🧑‍💻 Example Workflow

1. Run `:DataExplorer`
2. Search for `users.parquet` via Telescope
3. Preview metadata in the Telescope window
4. Press `<CR>` → open data table
5. Type `:DataExplorerQuery` and enter:

   ```sql
   SELECT country, COUNT(*) FROM users GROUP BY country ORDER BY COUNT(*) DESC LIMIT 50;
   ```

6. View the result directly in Neovim 🎉

---

## 🐛 Logging

Logs are written to:

```vim
:echo stdpath("cache") .. "/dataexplorer.log"
```

You can set the log level before setup:

```lua
vim.g.dataexplorer_log_level = "debug"
```

Levels: `trace`, `debug`, `info`, `warn`, `error`, `fatal`

---

## 🤝 Contributing

Pull requests and ideas are welcome!
Open an issue or PR on [GitHub](https://github.com/yourname/dataexplorer.nvim).

---

## 🧵 Social

- GitHub Discussions: _coming soon_

---
