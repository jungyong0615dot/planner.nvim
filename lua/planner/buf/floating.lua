local M = {}
local utils = require("planner.utils")

M.open = function(text)
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")
	local win_height = math.ceil(height * 0.7 - 4)
	local win_width = math.ceil(width * 0.7)
	local row = math.ceil((height - win_height) / 2 - 1)
	local col = math.ceil((width - win_width) / 2)
	local buf = vim.api.nvim_create_buf(true, true)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n"))
	vim.api.nvim_buf_set_option(buf, "filetype", "norg")
	vim.b[buf].parent_buf = vim.api.nvim_get_current_buf()
	local _ = vim.api.nvim_open_win(buf, true, {
		-- style = "minimal",
		relative = "editor",
		row = row,
		col = col,
		width = win_width,
		height = win_height,
		border = "rounded",
	})
	vim.w.is_floating_scratch = true
end

--- open floating buffer with task template
---@param title string
---@param description string
---@param subtasks string
M.task = function(title, description, subtasks)
	local template = [[
@document.meta
title: {title}
categories: docs
created: 2021-09-05
@end

* DESCRIPTION 
  {description}

* SUBTASKS
  {subtasks}
  ]]

	local task_render_text =
		utils.interpolate(template, { title = title, description = description, subtasks = subtasks })
	M.open(task_render_text)
end

return M
