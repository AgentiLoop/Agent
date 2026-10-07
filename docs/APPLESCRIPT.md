# Scripting Agent! with AppleScript

Agent! is a scriptable app. AppleScript, JavaScript for Automation (JXA), `osascript`, Shortcuts ("Run AppleScript"), and any other app can run tasks, manage tabs, drive auto-pilot, and change settings.

The dictionary is `Agent/Resources/Agent.sdef` (Standard Suite + **Agent! Suite**). To browse it, open Script Editor → **File › Open Dictionary…** → Agent!.

> The first time a script controls Agent!, macOS asks for permission to automate it (System Settings › Privacy & Security › Automation).

## Quick start

```applescript
tell application "Agent!"
    run task "list the files in my Downloads folder" in folder "/Users/me/Downloads"
    repeat while task running
        delay 1
    end repeat
    if task error is not "" then error task error
    return task summary
end tell
```

From Terminal:

```sh
osascript -e 'tell application "Agent!" to run task "what time is it?"'
osascript -e 'tell application "Agent!" to get activity log'
```

## Application properties

Unless noted, these act on the **Main** tab. Settings are the same values as the Settings window and are saved.

| Property | Type | Access | Description |
|---|---|---|---|
| `task running` | boolean | r | Whether the Main tab is running a task. |
| `activity log` | text | r | Full text of the Main tab activity log. |
| `task summary` | text | r | Completion summary of the Main tab's most recent task. Empty while a task runs, after it is stopped, or before any task. |
| `task error` | text | r | Last error logged by the Main tab's most recent task (empty when none). |
| `prompt history` | list of text | r | Prompts submitted in the Main tab, oldest first (the task field's ↑ history). |
| `task history` | list of text | r | Recent task summaries, `[time] prompt → summary`, oldest first (History window, Task Summaries). |
| `error history` | list of text | r | Recent errors, `[time] type: message`, oldest first (History window, Error History). |
| `project folder` | text | rw | Main tab project folder (absolute path). |
| `task input` | text | rw | Main tab task field text. |
| `provider` | text | rw | LLM provider display name, e.g. `"Claude"`. An unknown name gives an error that lists the choices. |
| `model` | text | rw | Model ID for the Main tab's provider. |
| `max iterations` | integer | rw | Maximum LLM turns per task (1 or more). |
| `max retries` | integer | rw | Maximum retries after a failed LLM request. |
| `max tokens` | integer | rw | Maximum output tokens per response (0 = provider default). |
| `token budget` | integer | rw | Per-task token budget, input + output (0 = unlimited). |
| `temperature` | real | rw | Temperature of the Main tab's provider (0–2). |
| `reasoning effort` | text | rw | `off`, `low`, `medium` or `high` (any capitalization). |
| `auto verify` | boolean | rw | After a successful build, launch the app and run accessibility checks. |
| `critic review` | boolean | rw | Have the LLM review the task's diff before the task can complete. |
| `visual tests` | boolean | rw | Allow the LLM to define click/verify UI tests. |
| `auto pull request` | boolean | rw | After a task completes, create a branch, commit, push and open a pull request. |
| `auto scaffold` | boolean | rw | Allow the LLM to create new Xcode projects from templates. |
| `auto screenshot` | boolean | rw | Take a screenshot after UI actions. |
| `force vision` | boolean | rw | Send images to every provider. |
| `messages monitor` | boolean | rw | Watch Messages for incoming Agent! commands. |
| `task auto complete` | boolean | rw | Show prompt-history suggestions while typing in the task field. |
| `user agent enabled` | boolean | rw | Whether the user Launch Agent is enabled. Setting false shuts it down. |
| `launch daemon enabled` | boolean | rw | Whether the root Launch Daemon is enabled. Setting false shuts it down. |
| `tool groups` | list of text | r | Every tool group name, as in the Tools window. |
| `tool names` | list of text | r | Every built-in tool name, as in the Tools window. |
| `disabled tool groups` | list of text | rw | Groups switched off for every provider (the Tools window's group switches). Turning `User` or `Root` off or on also turns the Launch Agent or Launch Daemon off or on. |
| `disabled tools` | list of text | rw | Tools switched off for the Main tab's provider (the Tools window's tool buttons). |
| `mcp servers` | list of text | r | Every MCP server name, as in the MCP Servers window. |
| `enabled mcp servers` | list of text | rw | MCP servers switched on (the MCP Servers window's switches). Switching one on connects it; switching it off disconnects it. Connecting takes a moment — check `connected mcp servers`. |
| `connected mcp servers` | list of text | r | MCP servers connected right now. |
| `mcp tools` | list of text | r | Every tool of the connected MCP servers, as `server.tool`. |
| `disabled mcp tools` | list of text | rw | MCP tools switched off (the MCP Servers window's tool buttons), as `server.tool`. |

Out-of-range values (for example `max iterations` 0, `temperature` 5, `reasoning effort` "extreme", or a negative count) and unknown tool, group or MCP server names give an error and change nothing.

```applescript
tell application "Agent!"
    set provider to "Claude"
    set max iterations to 50
    set reasoning effort to "high"
    set critic review to true
    {provider, model, temperature}
end tell
```

## Tabs

`tab` elements are in tab-bar order. **`tab 1` is always the Main tab** (id `"main"`).

| Property | Type | Access | Description |
|---|---|---|---|
| `id` | text | r | Unique identifier (`"main"` for the Main tab). |
| `name` | text | r | Tab title. |
| `task running` | boolean | r | Whether the tab is running a task. |
| `activity log` | text | r | Full text of the tab's activity log. |
| `task summary` | text | r | Completion summary of the tab's most recent task (empty while running, after a stop, or before any task). |
| `task error` | text | r | Last error logged by the tab's most recent task (empty when none). |
| `prompt history` | list of text | r | Prompts submitted in the tab, oldest first. |
| `task history` | list of text | r | Recent task summaries. LLM tabs (including tabs made by `make new tab`) share the Main tab's list, as in the History window. |
| `error history` | list of text | r | Recent errors. LLM tabs share the Main tab's list. |
| `task input` | text | rw | The tab's task field text. |
| `project folder` | text | rw | The tab's project folder. |
| `provider` | text | rw* | Provider name. *Settable only on the Main tab or in `make new tab with properties`. |
| `model` | text | rw* | Model ID. Settable like `provider`. |
| `selected` | boolean | rw | Whether the tab is selected. Set to true to select it. |
| `queued tasks` | list of text | r | Prompts waiting to run after the current task. |
| `auto pilot running` | boolean | r | Whether an auto-pilot session is active. |
| `auto pilot goal` | text | r | The session goal (empty when none). |
| `auto pilot cycle` | integer | r | Current cycle number (0 when no session). |
| `auto pilot status` | text | r | One-line status: cycle, elapsed, time left, branch, goal. |

Tabs respond to `close`, `select`, `clear log`, `stop task`, `clear queue` and `stop auto pilot`. Use `clear history … in tab t` for a tab's history.

```applescript
tell application "Agent!"
    -- New LLM tab; properties apply only to the new tab, never to Main
    set t to make new tab with properties {project folder:"/Users/me/Projects/MyApp", provider:"Claude"}
    run task "build the project and fix any errors" in tab t
    repeat while task running of t
        delay 2
    end repeat
    set theSummary to task summary of t
    close t
    return theSummary
end tell
```

```applescript
tell application "Agent!"
    name of every tab
    select tab 2
    set task input of tab 1 to "draft text, not yet run"
end tell
```

## Commands

### `run task`
`run task "prompt" [in folder "path"] [in tab t]` → boolean
Runs a task (Main tab by default). `in folder` sets the project folder first. Gives an error if a task is already running in that tab — use `queue task` to wait in line instead.

### `queue task`
`queue task "prompt" [in tab t]` → integer
Runs the task now if the tab is idle (returns 0); otherwise adds it to the tab's queue, like submitting while a task runs, and returns its position (1, 2, …). An empty prompt gives an error.

### `clear queue`
`clear queue [t]` or `clear queue [in tab t]` → integer
Removes the tab's queued tasks; the running task keeps going. Returns how many were removed.

### `clear history`
`clear history prompts|task summaries|errors [in tab t]` → integer
Clears one kind of history, like the History window's Clear button, and returns how many entries were removed. Without `in tab` it clears the Main tab's. Task summaries and errors of LLM tabs are shared with the Main tab, so clearing them in an LLM tab clears Main's too.

### `stop task`
`stop task [t]` or `stop task [in tab t]`
Stops the running task.

### `clear log`
`clear log [t]` or `clear log [in tab t]`
Clears the tab's activity log.

### `start auto pilot`
`start auto pilot ["goal"] [hours N] [isolated bool] [in tab t]` → boolean
Starts an auto-pilot session (same as `/auto`): the tab works in cycles until the goal is reached, the time runs out, or it is stopped. Omit the goal to have Agent! review the project and ask for one. `isolated true` works in a separate git worktree; `false` uses the shared checkout (default: isolate only when another auto-pilot tab is on the same project). Errors if auto-pilot is already running in that tab or the tab has no project folder.

### `stop auto pilot`
`stop auto pilot [t] [in tab t] [after cycle bool]`
Ends the session now and stops the running task (Stop All). With `after cycle true` it ends when the current cycle finishes (`/auto stop`). Errors if auto-pilot isn't running.

### `memory`
`memory "view"|"create"|"str_replace"|"insert"|"delete"|"rename" [path "/memories/…"] [content "…"] [find text "…"] [replacement "…"] [line number N] [destination "/memories/…"] [project scope bool]` → text
Reads or edits Agent!'s memory: the same `/memories` files the agent's `memory` tool uses. Global memory (shared by every project) is the default; `project scope true` uses the Main tab's project folder. Returns the tool's result text (`view` returns a file's text, or the file list for a folder). `view` defaults `path` to `/memories`; `create` takes the whole file as `content`; `str_replace` needs `find text` and `replacement`; `insert` puts `content` before 0-based `line number`; `rename` moves `path` to `destination`. Failures, such as a path outside `/memories` or `find text` that isn't found exactly once, raise an AppleScript error.

### `call tool`
`call tool "name" [with input "{…JSON…}"] [in tab tab N]` → text
Runs one of the agent's tools directly, without the LLM, and returns its result text. It runs on the Main tab unless `in tab` names another tab; then it uses that tab's project folder and appears in that tab's log and Steps list, the same as the tab's own tool calls. It takes the same tool names and arguments the agent uses (`git`, `file`, `user_shell`, `xcode`, `agent_script`, `accessibility`, `plan`, …); `call tool "list_tools"` lists the enabled ones. `with input` is a JSON object of the tool's arguments; omit it for tools that need none. Bad JSON, an empty name, an unknown tool or a closed tab raise an AppleScript error; a tool's own failure comes back as its result text. `root_shell` is refused unless `launch daemon enabled` is true. The command waits for the tool to finish, so long tools may need `with timeout of … seconds`.
### Standard Suite
`select`, `close`, `count`, `exists`, `make`, `get`/`set`, `quit` and the `window` class work as in other Cocoa apps.

## Examples

**Queue several tasks**

```applescript
tell application "Agent!"
    queue task "update the README"
    queue task "run the tests"
    queued tasks of tab 1
end tell
```

**Read and clear history**

```applescript
tell application "Agent!"
    set recent to task history
    set n to count of (error history)
    clear history prompts in tab 1
    {n, recent}
end tell
```

**Edit memory**

```applescript
tell application "Agent!"
    memory "create" path "/memories/notes.md" content "Prefers tabs over spaces."
    memory "str_replace" path "/memories/notes.md" find text "tabs" replacement "spaces"
    memory "view" path "/memories/notes.md"
end tell
```

**Run a tool without the LLM**
```applescript
tell application "Agent!"
    call tool "user_shell" with input "{\"command\":\"sw_vers\"}"
    call tool "git" with input "{\"action\":\"status\"}"
    call tool "user_shell" with input "{\"command\":\"pwd\"}" in tab tab 2
end tell
```

**Turn tools off and back on**
```applescript
tell application "Agent!"
    set saved to disabled tools
    set disabled tools to saved & {"xcode", "git"}
    set disabled tool groups to {"Experimental", "Sub-agents"}
    {tool groups, disabled tools}
end tell
```

**Switch MCP servers and their tools**
```applescript
tell application "Agent!"
    set enabled mcp servers to {"xcode"}
    repeat until connected mcp servers contains "xcode"
        delay 1
    end repeat
    set disabled mcp tools to {"xcode.BuildProject"}
    {mcp tools, disabled mcp tools}
end tell
```

**Auto-pilot for two hours, then check on it**

```applescript
tell application "Agent!"
    set project folder to "/Users/me/Projects/MyApp"
    start auto pilot "add unit tests for the networking layer" hours 2
    delay 60
    auto pilot status of tab 1
end tell
```

**JavaScript for Automation**

```javascript
const agent = Application("Agent!");
agent.runTask("summarize today's git log", { inFolder: "/Users/me/Projects/MyApp" });
while (agent.taskRunning()) delay(1);
agent.activityLog();
```

## How it works (for contributors)

- `Info.plist` sets `NSAppleScriptEnabled` = YES and `OSAScriptingDefinition` = `Agent.sdef`.
- `Agent/Resources/Agent.sdef` includes the Cocoa Standard Suite via XInclude and defines the Agent! Suite. Application properties map to `@objc` KVC keys on the app delegate; the `tab` class maps to `ScriptingTab`; each command maps to an `NSScriptCommand` subclass.
- `Agent/Services/AppleScriptSupport.swift` implements those keys, `ScriptingTab`, and the command classes. Errors are reported with `scriptErrorNumber`/`scriptErrorString`, so scripts see normal AppleScript errors.
