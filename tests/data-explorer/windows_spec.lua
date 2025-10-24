local config_windows = require("data-explorer.ui.config_windows")

-- describe("get_highlight_for_window", function()
--  it("returns SQL window highlights for win_sql", function()
--    local result = config_windows.get_highlight_for_window("win_sql")
--    assert.are.equal(
--      "Normal:DataExplorerSQLWindow,FloatBorder:DataExplorerSQLBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter",
--      result
--    )
--  end)
--
--  it("returns SQL error window highlights for win_sql_err", function()
--    local result = config_windows.get_highlight_for_window("win_sql_err")
--    assert.are.equal(
--      "Normal:DataExplorerSQLErrWindow,FloatBorder:DataExplorerSQLErrBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter",
--      result
--    )
--  end)
--
--  it("returns default highlights for unknown key", function()
--    local result = config_windows.get_highlight_for_window("unknown_key")
--    assert.are.equal(
--      "Normal:DataExplorerWindow,FloatBorder:DataExplorerBorder,FloatTitle:DataExplorerTitle,FloatFooter:DataExplorerFooter",
--      result
--    )
--  end)

describe("calculate_window_layout", function()
	it("returns correct dimensions for typical input", function()
		local opts = {
			window_opts = {
				hide_window_help = true, -- Hide help window on main display
			},
		}
		local width = 120
		local height = 40
		local nb_metadata_lines = 10
		local nb_data_lines = 20
		local dims = config_windows.calculate_window_layout(opts, width, height, nb_metadata_lines, nb_data_lines)
		assert.is_table(dims)
		assert.is_table(dims.vertical)
		assert.is_table(dims.horizontal)

		-- Vertical layout checks
		assert.is_number(dims.vertical.meta_width)
		assert.is_number(dims.vertical.meta_height)
		assert.is_number(dims.vertical.data_width)
		assert.is_number(dims.vertical.data_height)
		assert.is_number(dims.vertical.data_row_start)

		-- Horizontal layout checks
		assert.is_number(dims.horizontal.meta_width)
		assert.is_number(dims.horizontal.meta_height)
		assert.is_number(dims.horizontal.data_width)
		assert.is_number(dims.horizontal.data_height)
		assert.is_number(dims.horizontal.data_col_start)
	end)

	it("handles small terminal sizes gracefully", function()
		local opts = {
			window_opts = {
				hide_window_help = false,
			},
		}
		local dims = config_windows.calculate_window_layout(opts, 200, 50, 5, 20)
		assert.is_true(dims.vertical.meta_height == 5)
		assert.is_true(dims.vertical.data_height == 21)
		assert.is_true(dims.vertical.meta_width == 196)
		assert.is_true(dims.vertical.data_width == 196)
		assert.is_true(dims.horizontal.meta_height == 20)
		assert.is_true(dims.horizontal.data_height == 20)
		assert.is_true(dims.horizontal.meta_width == 49)
		assert.is_true(dims.horizontal.data_width == 146)
	end)
end)
