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
| Custom SQL Queries | Run SQL queries on your data, see results instantly   |
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
    limit = 250,
    layout = "vertical",
    files_types = {
        parquet = true,
        csv = true,
        tsv = true,
    },
}
```

| Parameter               | Type      | Description                                                                                                                   |
| :---------------------- | :-------- | :---------------------------------------------------------------------------------------------------------------------------- |
| **`limit`**             | `number`  | Maximum number of rows to fetch when displaying data. Use smaller values for very large files to prevent potential slowdowns. |
| **`layout`**            | `string`  | Main UI layout: `"vertical"` (metadata window on top/left, data on bottom/right) or `"horizontal"`.                           |
| **`files_types`**       | `table`   | Specifies which file formats are supported and enabled. Set a format to `false` to disable it.                                |
| **files_types.parquet** | `boolean` | Enable/disable support for `.parquet` files.                                                                                  |
| **files_types.csv**     | `boolean` | Enable/disable support for `.csv` files.                                                                                      |
| **files_types.tsv**     | `boolean` | Enable/disable support for `.tsv` files.                                                                                      |

---

#### Telescope Options

`telescope_opts`

These options control the appearance and behavior of the initial file selector.

```lua
{
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
        placeholder_sql = {
            "SELECT * FROM f LIMIT 1000;",
            "-- Warning: Large result could slow down / crash.",
            "-- To query the file, use 'f' as the table name.",
        },
    },
}
```

| Parameter                       | Type    | Description                                                                                      |
| :------------------------------ | :------ | :----------------------------------------------------------------------------------------------- |
| **`query_sql.placeholder_sql`** | `table` | Lines displayed in the SQL editor when it is opened. Used to give users tips or example queries. |

---

#### Key Mappings

`mappings`

Customize the key bindings for actions within the main UI.

```lua
{
    mappings = {
        quit = "q",
        back = "<BS>",
        focus_meta = "1",
        focus_data = "2",
        toggle_sql = "3",
        rotate_layout = "r",
        execute_sql = "e",
    },
}
```

| Parameter                    | Type     | Description                                            |
| :--------------------------- | :------- | :----------------------------------------------------- |
| **`mappings.quit`**          | `string` | Key to close the main UI and return to Neovim.         |
| **`mappings.back`**          | `string` | Key to go back to the file selection view.             |
| **`mappings.focus_meta`**    | `string` | Key to focus the metadata window.                      |
| **`mappings.focus_data`**    | `string` | Key to focus the data table window.                    |
| **`mappings.toggle_sql`**    | `string` | Key to toggle the SQL query editor window.             |
| **`mappings.rotate_layout`** | `string` | Key to switch between vertical and horizontal layouts. |
| **`mappings.execute_sql`**   | `string` | Key to execute the current SQL query.                  |

---

#### Highlighting Options

`hl`

Configure the colors for various UI elements.

```lua
{
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

No transformation is done on the metadata received from DuckDB, they are displayed as is.
The limitation is that only 40 rows can be displayed in DuckDB output, so if you have more than 40 columns, some will be truncated.

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

Data is extracted by executing a simple `SELECT * FROM f LIMIT <limit>;` query on the file, where `<limit>` is defined in the config (default 250 rows).

When you open the file, DuckDB handles reading the file using COPY TO STDOUT and returning the data in a csv-like format, with columns separated by `|` characters.
So a simple parsing is done to split the data into rows and columns for display in the table view.

When a custom SQL query is executed, the resulting data is fetched with delimiter ',' because we can't make a COPY TO STDOUT with '|' separator when the user can write any SQL query because we need to catch errors.
So the parsing with ',' is more greedy of resources.

### Displaying data

The data table view displays the fetched data in a formatted table with borders and alternating row colors for readability.
Column widths are adjusted based on the maximum width of data in each column.

### Syntax Highlighting

If enabled in the config, syntax highlighting is applied to the data table view.

You can customize the colors used for 9 alternating columns via the `hl.buffer.col1` to `hl.buffer.col9` config options.

The Group names used for highlighting are `DataExplorerCol1`, `DataExplorerCol2`, ..., `DataExplorerCol9`.

---

## User SQL Query

You can write and execute custom SQL queries on the loaded data file.
For displaying the SQL editor, press the mapping defined in the config (default `3`).

The SQL editor window allows you to write any valid SQL query using `f` as the table name representing the loaded data file.
To execute the SQL query, press the mapping defined in the config (default `e`).

When the query is executed, the resulting data is stored in cache (stdout) and displayed in the data table view.
The results of the queries are fetched and displayed in the data table view.

### Error handling

If there is an error in the SQL query (syntax error, invalid table/column names, etc.), the error message from DuckDB is captured and displayed in a separate SQL Error window.
This allows you to see what went wrong and adjust your query accordingly.

# Highlights

You can customize the highlight colors used in DataExplorer via the `hl` config option.
The following highlight groups are defined:

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

# ⚠️ Limitations

**🧩 General**

- Not optimized for large datasets — huge `.csv` / `.parquet` may slow down Neovim.
- No persistent caching — everything resets when you quit.

**📊 Metadata View**

- DuckDB truncates metadata to **40 columns** max.
- Type inference for `.csv`/`.tsv` is sample-based → can be inaccurate.

**📈 Data Table View**

- Default fetch: **250 rows**; increasing this may cause high memory usage.
- Emojis and special characters may misalign columns.

**🧠 SQL Query Editor**

- Queries run synchronously (can block Neovim).
- No auto-limit → always use `LIMIT` manually.
- Minimal SQL editor — no autocomplete or highlighting.
- Only the latest SQL error is shown.
- Parsing uses `,` delimiter for custom queries, which may affect performance on large results.

# 📏 Performances

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

# 📜 Future Plans

- Support for more formats (`.json`, `.sqlite`, etc.)
- Smarter preview caching
- Metadata personalization
- SQL Query history and favorites

# 💪 Motivation

Exploring `.parquet` files directly in Neovim has always been a pain.
Most tools either require leaving the editor or converting data manually.
**DataExplorer.nvim** was created to make exploring and querying structured data files easy — without leaving Neovim.

# 🫵🏼 Contribute & Bug Reports

PRs and feedback are welcome!
If you want to help improve performance, extend support for new formats, or enhance the UI — please open a PR or issue.

# 📜 License

MIT License © 2025 Kyytox
