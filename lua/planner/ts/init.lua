local M = {}
local ts_utils = require("nvim-treesitter.ts_utils")

-- local parent_node = current_node:parent()
-- vim.print(vim.treesitter.get_node_text(parent_node, 0))

M.get_node_at_cursor = function()
	return ts_utils.get_node_at_cursor()
end

M.is_task_status_node = function(node)
	local todo_exist = string.find(node:type(), "todo_item_")
	if todo_exist == nil then
		return false
	end
	return true
end

M.get_fields_of_subtask = function(node_at_cursor)
	local node_fields = node_at_cursor:parent()

	while node_fields ~= nil and node_fields:type() ~= "ordered_list2" do
		node_fields = node_fields:next_sibling()
	end

	if node_fields == nil then
		return {}
	end

	local fields_text = vim.treesitter.get_node_text(node_fields:child(1), 0)
	local fields = vim.fn.split(fields_text, ", ")
	return { task_id = fields[1], priority = fields[2] }
end

M.get_title_of_subtask = function(node_at_cursor)
	local node_fields = node_at_cursor:parent()
	while node_fields ~= nil and node_fields:type() ~= "paragraph" do
		node_fields = node_fields:next_sibling()
	end
	if node_fields == nil then
		return {}
	end
	local subtask_title = vim.treesitter.get_node_text(node_fields, 0)
	return string.sub(subtask_title, 2, #subtask_title) -- remove the leading space
end

M.get_task_description = function(node_at_cursor)
	local section_node = node_at_cursor
	while section_node ~= nil and section_node:type() ~= "heading1" and section_node:type() ~= "ranged_verbatim_tag" do
		section_node = section_node:parent()
	end
	return vim.treesitter.get_node_text(section_node:child(3), 0)
end

M.get_line_section = function(node_at_cursor)
	local section_node = node_at_cursor
	while section_node ~= nil and section_node:type() ~= "heading1" and section_node:type() ~= "ranged_verbatim_tag" do
		section_node = section_node:parent()
	end
	return { title = vim.treesitter.get_node_text(section_node:child(1), 0), node = section_node }
end

return M
