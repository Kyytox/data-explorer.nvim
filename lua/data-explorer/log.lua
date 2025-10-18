local M = {}

-- Niveaux de log
M.levels = {
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
}

-- Chemin du fichier de log (par défaut : /tmp/nvim_data_explorer.log)
M.log_file_path = "/media/kytox/Dev/data-explorer.nvim/logs/data_explorer.log"

-- Niveau de log minimum à afficher (par défaut : INFO)
M.min_level = M.levels.INFO

-- Initialise le fichier de log (efface le contenu existant)
function M.setup(log_file_path, min_level)
	M.log_file_path = log_file_path or M.log_file_path
	M.min_level = min_level or M.min_level
	local file = io.open(M.log_file_path, "w")
	if file then
		file:write("=== Début des logs ===\n")
		file:close()
	end
end

-- Écrit un message dans le fichier de log
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
		error("Impossible d'ouvrir le fichier de log : " .. M.log_file_path)
	end
end

-- Fonctions publiques pour chaque niveau de log
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
