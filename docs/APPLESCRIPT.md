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
    return activity log
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

Out-of-range values (for example `max iterations` 0, `temperature` 5, `reasoning effort` "extreme", or a negative count) give an error and change nothing.

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

Tabs respond to `close`, `select`, `clear log`, `stop task`, `clear queue` and `stop auto pilot`.

```applescript
tell application "Agent!"
    -- New LLM tab; properties apply only to the new tab, never to Main
    set t to make new tab with properties {project folder:"/Users/me/Projects/MyApp", provider:"Claude"}
    run task "build the project and fix any errors" in tab t
    repeat while task running of t
        delay 2
    end repeat
    set theLog to activity log of t
    close t
    return theLog
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
