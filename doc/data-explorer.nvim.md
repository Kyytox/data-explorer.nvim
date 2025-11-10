# data-explorer.nvim

**Preview**, **Explore**, and **Query** your data files (`parquet`, `csv`, `tsv`) directly inside Neovim
Powered by **DuckDB** and **Telescope**.

# 🚧 Caution

This plugin is still under active development.
If you encounter issues, have ideas for improvements, or want to contribute — please open an issue or a pull request!

# ⚡️ Requirements

- [**Neovim ≥ 0.10**](https://neovim.io)
- [**DuckDB**](https://duckdb.org), installed and available in your PATH
  (`duckdb` command must be executable from your terminal)
- [**telescope.nvim**](https://www.github.com/nvim-telescope/telescope.nvim)
- [**fd**](https://github.com/sharkdp/fd?tab=readme-ov-file#installation)

# 🎄 Features

| Feature            | Description                                           |
| ------------------ | ----------------------------------------------------- |
| Supported Formats  | `.parquet`, `.csv`, `.tsv`                            |
| SQL system         | [DuckDB](https://duckdb.org)                          |
| File Search        | Find data files using Telescope                       |
| Metadata Display   | Show column names, types, and other details           |
| Table View         | Display file contents in a formatted, colorized table |
| Pagination         | Navigate large datasets page by page                  |
| Custom SQL Queries | Run SQL queries on your data, see results instantly   |
| SQL Query History  | History of executed SQL queries                       |
| Configurable       | Limit, Layouts, mappings, colors, highlights          |
| Commands           | `DataExplorer`, `DataExplorerFile`                    |

# 🔌 Installation

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

# ⚙️ Config

The configuration is passed to the plugin's `setup` function: `require("data-explorer").setup({...})`.

When the setup configuration is launched, a validation of the user options is done.
If an option is not valid, an WARNING notification is shown with the invalid option name and the default value used instead.
After all options are validated, default values are applied for any missing options.

#### Core Options

```lua
{
    use_storage_duckdb = false,
    limit = 50,
    layout = "vertical",
    files_types = {
        parquet = true,
        csv = true,
        tsv = true,
    },
}
```

| Parameter                | Type      | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| :----------------------- | :-------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`use_storage_duckdb`** | `boolean` | If the value is `true`, a persistent DuckDB database file (`data_explorer.duckdb`) is used in your Neovim data directory. The data file is then read only once. Therefore, page changes and custom SQL queries will read the table from this file, which improves performance for medium to large files, but the initial load may be somewhat slow. If the value is `false`, the file will be read with every action, which can be resource-intensive for medium and large files. |
| **`limit`**              | `number`  | Maximum number of rows to fetch when displaying data. Use smaller values for very large files to prevent potential slowdowns.                                                                                                                                                                                                                                                                                                                                                     |
| **`layout`**             | `string`  | Main UI layout: `"vertical"` (metadata window on top/left, data on bottom/right) or `"horizontal"`.                                                                                                                                                                                                                                                                                                                                                                               |
| **`files_types`**        | `table`   | Specifies which file formats are supported and enabled. Set a format to `false` to disable it.                                                                                                                                                                                                                                                                                                                                                                                    |
| **files_types.parquet**  | `boolean` | Enable/disable support for `.parquet` files.                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| **files_types.csv**      | `boolean` | Enable/disable support for `.csv` files.                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| **files_types.tsv**      | `boolean` | Enable/disable support for `.tsv` files.                                                                                                                                                                                                                                                                                                                                                                                                                                          |

---

#### Telescope Options

`telescope_opts`

These options control the appearance and behavior of the initial file selector.

```lua
{
    telescope_opts = {
        layout_strategy = "vertical",
        layout_config = {
            height = 0.7,
            width = 0.9,
            preview_cutoff = 1,
            preview_height = 0.6,
            preview_width = 0.4,
        },
        finder = {
            include_hidden = false,
            exclude_dirs = { ".git", "node_modules", "__pycache__", "venv", ".venv", "miniconda3" },
        },
    },
}
```

| Parameter                                         | Type      | Description                                                                          |
| :------------------------------------------------ | :-------- | :----------------------------------------------------------------------------------- |
| **`telescope_opts.layout_strategy`**              | `string`  | Layout strategy for the Telescope picker. Examples: `"vertical"`, `"horizontal"`.    |
| **`telescope_opts.layout_config`**                | `table`   | Configuration for the chosen layout strategy.                                        |
| **`telescope_opts.layout_config.height`**         | `number`  | Height ratio of the Telescope window (`0.0` to `1.0`).                               |
| **`telescope_opts.layout_config.width`**          | `number`  | Width ratio of the Telescope window (`0.0` to `1.0`).                                |
| **`telescope_opts.layout_config.preview_cutoff`** | `number`  | Minimum width (in columns) to show the preview window.                               |
| **`telescope_opts.layout_config.preview_height`** | `number`  | Height ratio of the preview window when using **vertical** layout (`0.0` to `1.0`).  |
| **`telescope_opts.layout_config.preview_width`**  | `number`  | Width ratio of the preview window when using **horizontal** layout (`0.0` to `1.0`). |
| **`telescope_opts.finder.include_hidden`**        | `boolean` | Whether to include hidden files in the file search.                                  |
| **`telescope_opts.finder.exclude_dirs`**          | `table`   | List of directory names to exclude from the file search.                             |

---

#### Floating Window Options

`window_opts`

These options apply to the main data display windows (Data and Metadata).

```lua
{
    window_opts = {
        border = "rounded",
        max_height_metadata = 0.25,
        max_width_metadata = 0.25,
    },
}
```

| Parameter                             | Type     | Description                                                                                         |
| :------------------------------------ | :------- | :-------------------------------------------------------------------------------------------------- |
| **`window_opts.border`**              | `string` | Border style for the floating windows. Examples: `"none"`, `"single"`, `"double"`, `"rounded"`.     |
| **`window_opts.max_height_metadata`** | `number` | Maximum height ratio for the metadata window when using the **horizontal** layout (`0.0` to `1.0`). |
| **`window_opts.max_width_metadata`**  | `number` | Maximum width ratio for the metadata window when using the **vertical** layout (`0.0` to `1.0`).    |

---

#### SQL Query Options

`query_sql`

These options configure the SQL query editor behavior.

```lua
{
    query_sql = {
        history_size = 25,
    },
}
```

| Parameter                    | Type     | Description                                                              |
| :--------------------------- | :------- | :----------------------------------------------------------------------- |
| **`query_sql.history_size`** | `number` | Number of previous SQL queries to keep in history (not yet implemented). |

---

#### Key Mappings

`mappings`

Customize the key bindings for actions within the main UI.

```lua
{
    mappings = {
        quit = "q",
        back = "<BS>",
        next_page = "J",
        prev_page = "K",
        focus_meta = "1",
        focus_data = "2",
        toggle_sql = "3",
        rotate_layout = "r",
        execute_sql = "e",
        prev_history = "<Up>",
        next_history = "<Down>",
    },
}
```

| Parameter                    | Type     | Description                                            |
| :--------------------------- | :------- | :----------------------------------------------------- |
| **`mappings.quit`**          | `string` | Key to close the main UI and return to Neovim.         |
| **`mappings.back`**          | `string` | Key to go back to the file selection view.             |
| **`mappings.next_page`**     | `string` | Key to go to the next page in the data table view.     |
| **`mappings.prev_page`**     | `string` | Key to go to the previous page in the data table view. |
| **`mappings.focus_meta`**    | `string` | Key to focus the metadata window.                      |
| **`mappings.focus_data`**    | `string` | Key to focus the data table window.                    |
| **`mappings.toggle_sql`**    | `string` | Key to toggle the SQL query editor window.             |
| **`mappings.rotate_layout`** | `string` | Key to switch between vertical and horizontal layouts. |
| **`mappings.execute_sql`**   | `string` | Key to execute the current SQL query.                  |
| **`mappings.prev_history`**  | `string` | Key to navigate to the previous SQL query in history.  |
| **`mappings.next_history`**  | `string` | Key to navigate to the next SQL query in history.      |

---

#### Highlighting Options

`hl`

Configure the colors for various UI elements.

```lua
{
    hl = {
      windows = {
          bg = "#151515",
          fg = "#cdd6f4",
          title = "#D97706",
          footer = "#F87171",
          sql_fg = "#3B82F6",
          sql_bg = "#1e1e2e",
          sql_err_fg = "#EF4444",
          sql_err_bg = "#3b1d2a",
      },
      buffer = {
          hl_enable = true,
          header = "white",
          col1 = "#EF4444",
          col2 = "#3B82F6",
          col3 = "#10B981",
          col4 = "#FBBF24",
          col5 = "#A78BFA",
          col6 = "#06B6D4",
          col7 = "#F59E0B",
          col8 = "#63A5F7",
          col9 = "#22C55E",
      },
	},
}
```

| Parameter                                 | Type      | Description                                                   |
| :---------------------------------------- | :-------- | :------------------------------------------------------------ |
| **`hl.windows.bg`**                       | `string`  | Background color for main UI windows.                         |
| **`hl.windows.fg`**                       | `string`  | Foreground color for main UI windows.                         |
| **`hl.windows.title`**                    | `string`  | Color of the window title.                                    |
| **`hl.windows.footer`**                   | `string`  | Color of the footer/help line.                                |
| **`hl.windows.sql_fg`**                   | `string`  | Foreground color for SQL editor window.                       |
| **`hl.windows.sql_bg`**                   | `string`  | Background color for SQL editor window.                       |
| **`hl.windows.sql_err_fg`**               | `string`  | Foreground color for SQL error window.                        |
| **`hl.windows.sql_err_bg`**               | `string`  | Background color for SQL error window.                        |
| **`hl.buffer.hl_enable`**                 | `boolean` | Enable/disable syntax highlighting in the data table view.    |
| **`hl.buffer.header`**                    | `string`  | Highlight for column headers in data table view.              |
| **`hl.buffer.col1` ... `hl.buffer.col9`** | `string`  | Foreground colors for alternating columns in data table view. |

# 🚀 API

## DataExplorer

Search for and preview supported data files:

```vim
:lua require("data-explorer").DataExplorer()
```

```
:DataExplorer
```

Telescope will show a list of supported data files in your current working directory.
Selecting a file opens it in the DataExplorer view with metadata and table view.

## DataExplorerFile

Open the currently edited file in DataExplorer (if supported):

```vim
:lua require("data-explorer").DataExplorerFile()
```

```
:DataExplorerFile
```

This bypasses Telescope and directly loads the file into the explorer.

# 🧠 Usage Example

1. Run `:DataExplorer` to open the Telescope file picker.
2. Select a file.
3. Explore the file:

- 1 → focus Metadata
- 2 → focus Data Table
- 3 → toggle SQL editor

4. Write SQL queries using `f` as the table name.
5. Press **e** to execute and view results instantly.
6. Press **q** to quit the explorer.

# ⛩️ Architecture

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

# Windows Layout

The main DataExplorer window is divided into multiple sections:

- **Metadata View**: Displays column names, types, and statistics about the data.
- **Data Table View**: Shows the actual data in a formatted table.
- **SQL Query Prompt**: An optional window to write and execute custom SQL queries (hidden by default).

The layout can be either vertical (metadata on the left, data on the right) or horizontal (metadata on top, data below).

`Horizontal Layout:`

```

          ┌────────────────┐
          │ ┌────────────┐ │
          │ │  Metadata  │ │
          │ │  Metadata  │ │
          │ └────────────┘ │
          │ ┌────────────┐ │
          │ │    Data    │ │
          │ │            │ │
          │ │    Data    │ │
          │ │            │ │
          │ │    Data    │ │
          │ │            │ │
          │ │    Data    │ │
          │ └────────────┘ │
          └────────────────┘
```

The max height of metadata window is 30% (by default) of the total height, but can be configured via `max_height_metadata` option.
The data window takes all the remaining height.

`Vertical Layout:`

```

    ┌─────────────────────────────────┐
    │┌───────┐┌──────────────────────┐│
    ││       ││                      ││
    ││ Meta  ││   Data     Data      ││
    ││       ││                      ││
    ││ Meta  ││   Data     Data      ││
    ││       ││                      ││
    ││ Meta  ││   Data     Data      ││
    ││       ││                      ││
    │└───────┘└──────────────────────┘│
    └─────────────────────────────────┘
```

The max width of the metadata window is 25% (by default) of the total width, but can be configured via `max_width_metadata` option.
The data window takes all the remaining width.

# Modules

## Metadata View

### Metadata Extraction

There are read where you find a file in telescope and display it in the preview window.
When a metadata is read, he is saved in cache but only for the current session when you close the explorer, the cache is cleared.

No transformation is done on the data received from DuckDB, they are displayed as is with mode `duckbox` (mode of DuckDB to display data in tabular format).

#### csv-tsv extract

For `.csv` and `.tsv` files, DuckDB creates a temporary table to infer column names and types by reading a sample of the data.

The metadata table for `.csv` and `.tsv` files includes the foll owing columns:

| Column Name | Description                                          |
| ----------- | ---------------------------------------------------- |
| `Column`    | Name of the column                                   |
| `Type`      | Inferred data type of the column                     |
| `Unique`    | Number of unique values in column in percent         |
| `Nulls`     | Number of null values in column in percent           |
| `Min`       | Minimum value in the column (Max 40 chars displayed) |
| `Max`       | Maximum value in the column (Max 40 chars displayed) |
| `Average`   | Average value for numeric columns                    |
| `StdDev`    | Standard deviation for numeric columns               |
| `q25`       | 25th percentile value for numeric columns            |
| `q50`       | 50th percentile (median) for numeric columns         |
| `q75`       | 75th percentile value for numeric columns            |
| `Count`     | Total number of rows in the column                   |

#### parquet display

For `.parquet` files, DuckDB can directly read the schema without loading the entire file, making it efficient for large datasets, DuckDB use the function `parquet_metadata` to extract metadata.

The metadata table for `.parquet` files includes the following columns:

| Column Name | Description                        |
| ----------- | ---------------------------------- |
| `Column`    | Name of the column                 |
| `Type`      | Data type of the column            |
| `Min`       | Minimum value in the column        |
| `Max`       | Maximum value in the column        |
| `Nulls`     | Number of null values in column    |
| `Count`     | Total number of rows in the column |

---

## Data Table View

### Data Extraction

According to the configuration option `use_storage_duckdb`, if is true, the data is loaded into a persistent DuckDB database file located in the Neovim cache directory (`~/.cache/nvim/data_explorer/data_explorer.db`).

**Advantage**:

- The file is read once and the data is stored in table, so when you change page or execute SQL queries, the data is fetched from the local database file, which is faster for large files.
- You can read large files
- If you have complex SQL queries, they will be faster.

**Disadvantage**:

- Reading a file may take longer because the data needs to be written to disk.

If `use_storage_duckdb` is false, the file is read each time you change page or execute SQL queries.

**Advantage**:

- No persistent storage is used, so no disk space is consumed.
- Reading small and medium files is faster (with the appropriate RAM) because there is no overhead of writing to disk.

**Disadvantage**:

- Large files may be slow to read each time you change page or execute SQL queries.

### Displaying data

No transformation is done on the data received from DuckDB, they are displayed as is with mode `duckbox` (mode of DuckDB to display data in tabular format).

A pagination system is implemented to navigate through the data table view.
By default, 50 rows are fetched and displayed at a time (configurable via the `limit` option).

### Syntax Highlighting

If enabled in the config, syntax highlighting is applied to the data table view.

You can customize the colors used for 9 alternating columns via the `hl.buffer.col1` to `hl.buffer.col9` configuration options.

The Group names used for highlighting are `DataExplorerCol1`, `DataExplorerCol2`, ..., `DataExplorerCol9`.

---

## User SQL Query

You can write and execute custom SQL queries on the loaded data file.
For displaying the SQL editor, press the mapping defined in the config (default `3`).

The SQL editor window allows you to write any valid SQL query using `f` as the table name representing the loaded data file.
To execute the SQL query, press the mapping defined in the config (default `e`).

A verification of the SQL query is done before execution to ensure it is valid. You need to write a SQL with a statement `FROM f` to query the loaded file (f is the table name representing the loaded file).

If configuration option `use_storage_duckdb` is true, the query is executed against the persistent DuckDB database file.
If false, the query is executed directly against the data file each time.

When the query is executed, the resulting data is stored in cache (stdout) and displayed in the data table view.
The results of the queries are fetched and displayed in the data table view.

### Displaying Query Results

The results of the executed SQL query are displayed in the data table view, replacing the previous data.
No transformation is done on the data received from DuckDB, they are displayed as is with mode `duckbox` (mode of DuckDB to display data in tabular format).

The same pagination system from the Data Table View is applied to the query results.
By default, 50 rows are fetched and displayed at a time (configurable via the `limit` option).

### Error handling

If there is an error in the SQL query (syntax error, invalid table/column names, etc.), the error message from DuckDB is captured and displayed in a separate SQL Error window.
This allows you to see what went wrong and adjust your query accordingly.

### History

A history of valid executed SQL queries is stored in cache file in the Neovim cache directory (`~/.cache/nvim/data_explorer/sql_history.log`). You can navigate through the history using the configured mappings (default `<Up>` and `<Down>`).

The history size is configurable via the `query_sql.history_size` option.

# Highlights

You can customize the highlight colors used in DataExplorer via the `hl` configuration option.

## Window Highlights

You can customize the colors used for various UI elements via the `hl.windows` configuration options.

| Highlight Group                           | Options Used From Config                         | Description                                                   |
| ----------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------- |
| `DataExplorerWindow`                      | `hl.windows.bg`                                  | Background color for main UI windows.                         |
| `DataExplorerBorder`                      | `hl.windows.bg`, `hl.windows.fg`                 | Border color for main UI windows.                             |
| `DataExplorerTitle`                       | `hl.windows.bg`, `hl.windows.title`              | Color of the window title.                                    |
| `DataExplorerFooter`                      | `hl.windows.bg`, `hl.windows.footer`             | Color of the footer/help line.                                |
| `DataExplorerSQLBorder`                   | `hl.windows.sql_bg`, `hl.windows.sql_fg`         | Border color for SQL editor window.                           |
| `DataExplorerSQLWindow`                   | `hl.windows.sql_bg`                              | Background color for SQL editor window.                       |
| `DataExplorerSQLErrBorder`                | `hl.windows.sql_err_bg`, `hl.windows.sql_err_fg` | Border color for SQL error window.                            |
| `DataExplorerSQLErrWindow`                | `hl.windows.sql_err_bg`                          | Background color for SQL error window.                        |
| `DataExplorerColHeader`                   | `hl.buffer.header`                               | Highlight for column headers in data table view.              |
| `DataExplorerCol1` ... `DataExplorerCol9` | `hl.buffer.col1` ... `hl.buffer.col9`            | Foreground colors for alternating columns in data table view. |

## Data Buffer Highlights

You can customize the colors used for syntax highlighting in the data table view via the `hl.buffer` configuration options.
| Highlight Group | Options Used From Config | Description |
| ---------------------- | ------------------------ | ------------------------------------------------ |
| `DataExplorerColHeader` | `hl.buffer.header` | Highlight for column headers in data table view. |
| `DataExplorerCol1` | `hl.buffer.col1` | Foreground color for column 1 in data table view. |
| ..... | ... | ... |
| `DataExplorerCol9` | `hl.buffer.col9` | Foreground color for column 9 in data table view. |

# ⚠️ Limitations

**🧩 General**

- If you don't set true to config `use_storage_duckdb`, large files may be slow to read each time you change page or execute SQL queries.
- No persistent caching — everything resets when you quit.

**📊 Metadata View**

- It may take a little while for larger files because the entire file is read to properly determine the types

**📈 Data Table View**

- Emojis and special characters may misalign columns.

**🧠 SQL Query Editor**

- Minimal SQL editor — no autocomplete or highlighting.
- Only the latest SQL error is shown.

# 📏 Performances

The following table shows approximate load and query times
The file is a copy of [nasa-exoplanet archive data](https://exoplanetarchive.ipac.caltech.edu/cgi-bin/TblView/nph-tblView?app=ExoTbls&config=PS) with a lot of lines duplicated.

With a PC with:

- CPU: AMD Ryzen™ 7 7700X
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

# 📜 Future Plans

- Support for more formats (`.json`, `.sqlite`, etc.)
- Smarter preview caching
- Metadata personalization
- Reopen last file explored

# 💪 Motivation

Exploring `.parquet` files directly in Neovim has always been a pain and required jumping between multiple tools.

While working on a separate side project, I constantly needed a quick, native way to preview, validate, and query these data files to confirm my assumptions and ensure data integrity-all without having to jump to an external tool.

So, I created **data-explorer.nvim**.

# 🫵🏼 Contribute & Bug Reports

PRs and feedback are welcome!
If you want to help improve performance, extend support for new formats, or enhance the UI — please open a PR or issue.

# 📜 License

MIT License © 2025 Kyytox
