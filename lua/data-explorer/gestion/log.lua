local M = {}

--- Display a notification in Neovim.
---@param level number: Log level (1=DEBUG, 2=INFO, 3=WARN, 4=ERROR).
---@param message string: Message to display.
function M.display_notify(level, message)
	local title = "Data Explorer"
	if level == M.levels.DEBUG then
		vim.notify(message, vim.log.levels.DEBUG, { title = title })
	elseif level == M.levels.INFO then
		vim.notify(message, vim.log.levels.INFO, { title = title })
	elseif level == M.levels.WARN then
		vim.notify(message, vim.log.levels.WARN, { title = title })
	elseif level == M.levels.ERROR then
		vim.notify(message, vim.log.levels.ERROR, { title = title })
	end
end

M.levels = {
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
}

M.log_file_path = "./logs/data_explorer.log"

M.min_level = M.levels.DEBUG

--- Create folder and file if they do not exist
local function ensure_log_file_exists()
	local log_dir = M.log_file_path:match("^(.*)/[^/]+$") or "."
	os.execute("mkdir -p " .. log_dir)
	local file = io.open(M.log_file_path, "a")
	if file then
		file:close()
	else
		error("Could not create log file: " .. M.log_file_path)
	end
end

function M.setup(log_file_path, min_level)
	ensure_log_file_exists()
	M.log_file_path = log_file_path or M.log_file_path
	M.min_level = min_level or M.min_level
	local file = io.open(M.log_file_path, "w")
	if file then
		file:write("=== Data Explorer Log Started at " .. os.date("%Y-%m-%d %H:%M:%S") .. " ===\n")
		file:close()
	end
end

local function write_log(level, message)
	if level < M.min_level then
		return
	end

	local level_str = "UNKNOWN"
	if level == M.levels.DEBUG then
		level_str = "DEBUG"
	elseif level == M.levels.INFO then
		level_str = "INFO "
	elseif level == M.levels.WARN then
		level_str = "WARN "
	elseif level == M.levels.ERROR then
		level_str = "ERROR"
	end

	local log_message = string.format("[%s] %s: %s\n", os.date("%Y-%m-%d %H:%M:%S"), level_str, message)

	local file = io.open(M.log_file_path, "a")
	if file then
		file:write(log_message)
		file:close()
	else
		error("Could not open log file: " .. M.log_file_path)
	end
end

function M.debug(message)
	write_log(M.levels.DEBUG, message)
end

function M.info(message)
	write_log(M.levels.INFO, message)
end

function M.warn(message)
	write_log(M.levels.WARN, message)
end

function M.error(message)
	write_log(M.levels.ERROR, message)
end

return M
