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
  local node_fields = node_at_cursor:parent():next_sibling():next_sibling()
  if node_fields == nil then
    return {}
  end
	local fields_text = vim.treesitter.get_node_text(node_fields:child(1), 0)
  local fields = vim.fn.split(fields_text, ", ")
  return {task_id = fields[1], priority = fields[2]}
  
end

return M
