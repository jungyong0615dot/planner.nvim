local M = {}

local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

M.picker_tasks = function(tasks, callback)

  pickers
    .new({}, {
      prompt_title = "Select a task",
      results_title = "Details",
      finder = finders.new_table {
        results = tasks,
        entry_maker = function(entry)
          return {
            value = entry["id"],
            display = entry["name"],
            ordinal = entry["name"],
          }
        end,
      },
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = actions_state.get_selected_entry()
          actions.close(prompt_bufnr)
          print("Open:", selection.display)
          print("Value:", selection.value)

          callback(selection.value)
        end)
        return true
      end,
    })
    :find()

end

return M
