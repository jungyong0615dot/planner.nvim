## Todo list framework

0. Goal
- theres no all-in-one apps for planner.
- build personalized planner, while borrowing multiple platforms' pros

1. Create neovim plugin for todolist app
- Unified plugin for all kinds of apps
  - clickup, jira, microsoft todo, todoist
- Read specified task and render in neovim buffer
- When edit buffer, automatically update into app
- Get updates from app periodically
- List tasks from section (clickup: list, todoist: project)
- Open task from list
- Async update
- Beutifully render list of tasks (dates, priority, etc)
- Telescope based search

2. create centralized todolist sync system
- Database for centralized list (cdb)
- Centralized task has only one unique task id, update_ts
- Triggers (webhook) from each app, in n8n
  - CRUD should be synced from cdb

3. make nvim connected with cdb
4. Publish plugin
5. Improve plugin
- Daily/weekly progress
- plan share

### 1. Create neovim plugin for todolist app
#### Read specified task and render in neovim buffer
- [x] requirements
  - [x] nvim buffer template

```markdown
# TASK
## TITLE
TITLE_OF_CONTENTS

## CONTENTS
CONTENTS_OF_TASK

> 

# SUBTASKS
- [STATUS] [SUBTASK_KEY] [PRIORITY] [DUE] ITEM1
- [STATUS] [SUBTASK_KEY] [PRIORITY] [DUE] ITEM1

> subtasks should be ordered with same order in app
> will not use table because of the treesitter
> when theres no subtasks, show "no subtasks"
> bulk updates (crud) should be implemented
> go to subtasks: won't be implemented
> jira epic will be regarded as list, not the task


# FIELDS

## PRIORITY
MEDIUM
> autocomplete priority

## DUE_DATE 
2023-01-01
> date type handler


> each fields goes subhead


# COMMENTS
## USER_NAME / TIMESTAMP
COMMENT_TEXT
## USER_NAME / TIMESTAMP
COMMENT_TEXT

```

  - [x] REST API requirements
    - required: title, text, subtasks list, comments
    - required fields: due, priority
    - optional fields: start date

  - [x] neovim template requirements
    - required:
      - treesitter support:
        - multiple status for items list
        - date picker
      - markdown converter
    - good to have:
      - api, plugins

- [x] plugin repo construct
  - buf
    - floating.lua
    - autocmd/
  - api
    - clickup
    - todoist
  - ts (treesitter)
  - tl (telescope)
  - utils
  > each dir includes init.lua

- [x] try out neorg treesitter 
- [x] Implement floating
- [x] Neorg task template
- [x] Implement templating using mock data
- [-] Implement async rest
- [ ] clickup task renderer
  - [ ]

