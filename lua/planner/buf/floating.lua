local M = {}
local utils = require("planner.utils")

M.open = function(text)
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")
	local win_height = math.ceil(height * 0.9 - 4)
	local win_width = math.ceil(width * 0.9)
	local row = math.ceil((height - win_height) / 2 - 1)
	local col = math.ceil((width - win_width) / 2)
	local buf = vim.api.nvim_create_buf(true, true)
  local save_name = vim.fn.tempname() .. ".norg"

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n"))
	vim.api.nvim_buf_set_option(buf, "filetype", "norg")
	vim.b[buf].parent_buf = vim.api.nvim_get_current_buf()

  -- show buf as fullscreen
  vim.fn.bufload(buf)
  vim.api.nvim_buf_set_name(buf, save_name)

	-- local _ = vim.api.nvim_open_win(buf, true, {
	-- 	relative = "editor",
	-- 	row = row,
	-- 	col = col,
	-- 	width = win_width,
	-- 	height = win_height,
	-- 	border = "rounded",
	-- })
	vim.w.is_floating_scratch = true
  return buf
end

--- open floating buffer with task template
---@param title string
---@param description string
---@param subtasks string
M.task = function(app, title, description, subtasks, author, categories, created, updated, version, fields)
	local template = [[
@document.meta
title: {title}
authors: {author}
categories: {categories}
created: {created}
updated: {updated}
version: {version}
{fields}
@end
___
* DESCRIPTION 
{description}
___
* SUBTASKS
{subtasks}
  ]]

	local task_render_text = utils.interpolate(template, {
		title = title,
		description = description,
		subtasks = subtasks,
		author = author,
		categories = categories,
		created = created,
		updated = updated,
		version = version,
		fields = fields,
	})
	local bufnr = M.open(task_render_text)
  return bufnr
end

return M
