# 🦾 AgentiLoop Agent!

### **Agentische KI für deinen Mac-Desktop**

[![Latest Release](https://img.shields.io/github/v/release/AgentiLoop/Agent?label=Download&color=blue&style=for-the-badge)](https://github.com/AgentiLoop/Agent/releases/latest)
[![GitHub Stars](https://img.shields.io/github/stars/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Stars&color=gold)](https://github.com/AgentiLoop/Agent/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Forks&color=white)](https://github.com/AgentiLoop/Agent/fork)
[![macOS 26.4+](https://img.shields.io/badge/macOS-26.4.1-green?style=for-the-badge)](https://github.com/apple)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange?style=for-the-badge)](https://www.swift.org)
<a href="https://www.paypal.com/ncp/payment/9C6RY2UAE5M3S"><img src="https://img.shields.io/badge/Donation-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Tip Jar" /></a>

## README-Übersetzungen

- [English](README.md)
- [Español](README_es.md)
- [Français](README_fr.md)
- [Deutsch](README_de.md)
- [中文 (简体)](README_zh.md)

## Schach in Agent
<img width="1176" height="724" alt="Screenshot 2026-08-23 at 7 34 10 PM" src="https://github.com/user-attachments/assets/d3b2f1e5-1dab-44f7-95f6-008424ee794c" />

## Was ist Agent!?

**Eine App. Jede KI. Volle Kontrolle über deinen Mac.**

Agent! ist eine zu 100 % native Swift-6.2-/SwiftUI-App, die **18 LLM-Anbieter** — Claude, GPT, Gemini, Grok, Mistral, DeepSeek, Qwen, Z.ai, BigModel, Hugging Face, OpenRouter, Ollama (Cloud und lokal), vLLM, LM Studio, Codestral, Mistral Vibe und die geräteinterne **Apple Intelligence** — mit einer autonomen Aufgabenschleife verbindet, die wirklich *etwas tut*: Sie liest deinen Code, behebt den Fehler, baut das Xcode-Projekt, committet den Diff, steuert jede Mac-App über die Accessibility-API, führt Shell-Befehle als du oder als root aus, schickt dir Ergebnisse per iMessage und reagiert auf ein gesprochenes *„Agent!"*.

Kein NPM, kein Electron, kein Abo, keine Telemetrie. Bring deinen eigenen API-Schlüssel mit, lauf komplett lokal oder kostenlos mit Apple Intelligence. Jedes Swift-Paket, von dem die App abhängt, wurde vom selben Autor geschrieben. Siehe [Entstehungsgeschichte](#entstehungsgeschichte) unten.

## Was ist neu 🚀

**v1.1.x — Das Hardened-Harness-Release** · [Releases →](https://github.com/AgentiLoop/Agent/releases/latest)

- **Kontext-Kompaktierung, neu gebaut.** Schwellwert = Modellfenster − reservierte Ausgabe − Puffer, gesteuert durch echte `input_tokens`. Eine anbieterseitige 9-Abschnitte-LLM-Zusammenfassung ersetzt die geräteinternen 4K-Zusammenfassungen; offenes Ziel, Plan-Checkliste und bearbeitete Dateien werden nach jeder Kompaktierung wieder angehängt. Übergroße Tool-Ergebnisse werden beim Entstehen auf die Festplatte ausgelagert und sind über `restore_tool_result` wiederherstellbar. 413-Überläufe laufen durch erzwungene Kompaktierung mit kürzerem Retry; `max_tokens`-Überschreitungen erholen sich durch Eskalation und anschließendes Fortsetzen.
- **Read-before-edit-Gate.** `edit_file` / `apply_diff` / `diff_apply` verweigern Änderungen an Dateien, die das LLM in dieser Aufgabe nicht gelesen hat oder die sich seit dem letzten Lesen auf der Festplatte geändert haben (SHA-256). Die Verweigerung liest die Datei automatisch, sodass der nächste Aufruf die Bearbeitung ist. Externe Dateiänderungen werden in jedem Zug als Diff-Snippets angezeigt.
- **Echte Kontextfenster für lokale Modelle.** LM Studio, Ollama und vLLM melden ihre tatsächliche Kontextlänge pro Modell — keine fest kodierte 32K-Annahme mehr.
- **Schnellere Züge.** Nur-Lese-Tools starten, während die Claude-Antwort noch streamt; eingabebewusste Shell-Parallelität; gejitterter exponentieller Retry mit `Retry-After` bei 429/529; Fehler mitten im SSE-Stream werden bei jedem Anbieter sichtbar.
- **Defense-in-Depth.** `ShellSafetyService` wird jetzt sowohl daemon-seitig (AgentHelper + AgentUser) als auch client-seitig durchgesetzt; Release-Builds lehnen XPC-Clients ohne Team ab; beide XPC-Listener verlangen Code-Signing mit demselben Team, abgeleitet aus der eigenen Signatur der App.
- **Aktivitätsprotokoll.** Keine 50K-Kürzung und kein 500K-Trimmen beim Neustart mehr — große Logs werden abseits des Main-Threads mit einem „Processing tab data…"-Overlay gerendert; optionales Layout „Activity Log Below HUD".
- **App-Menü:** Nach Updates suchen… (GitHub-Releases), Website, GitHub. CI-Build-&-Test-Workflow bei jedem PR; **273 bestandene Tests**.
- Außerdem: `goal_state` mit evidenzgeprüften Kriterien, optionale Kritiker-Diff-Prüfung vor Abschluss, aufgabenbezogenes `rewind_task`, Extended Thinking für Claude, `reasoning_effort`-Durchreichung, Sub-Agenten mit Modell-Override pro Agent (3 parallel, 6 nur lesend), typisierte Tool-Fehler mit Wiederherstellungshinweisen, Event-Hooks.

## Schnellstart (Download)

1. **Lade** [Agent!](https://github.com/AgentiLoop/Agent/releases/latest) herunter und ziehe es in „Programme"
2. **Öffne Agent!** — es richtet alles automatisch ein
3. **Wähle deine KI** — Einstellungen → Anbieter wählen → API-Schlüssel eingeben

## Schnellstart (Aus dem Quellcode bauen)

```bash
git clone https://github.com/AgentiLoop/agent.git
cd Agent
```

**Option A — Xcode (Apple-Developer-Konto):** `Agent.xcodeproj` öffnen, dein Development Team setzen, Target `Agent` bauen & starten, den Helper bei Aufforderung genehmigen.

**Option B — ohne Developer-Konto (nur Xcode Command Line Tools):**
```bash
./build.sh              # Debug
./build.sh Release      # Release
open "build/DerivedData/Build/Products/Debug/Agent!.app"
```

> ⚠️ Option-B-Builds sind ad-hoc signiert. Die Launch-Agent-/Daemon-Helper registrieren sich nicht (SMAppService braucht eine Team ID), aber LLM-Schleife, alle Tools, Accessibility, AppleScript, Shell und MCP funktionieren trotzdem.

> 💡 **Günstiges Setup:** **GLM-5.1** über **Z.ai** (schnellste Anmeldung, Standardmodell) kostet nur Cents pro Million Tokens. Lokal? Nur **GLM-4.7-Turbo** (32B) passt auf Consumer-Hardware (64–128 GB Apple Silicon über Ollama).

### Fehlerbehebung (Aus dem Quellcode bauen)

- **`xcode-select` zeigt auf die Command Line Tools** → `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- **Seltsames `BUILD FAILED` nach dem Pull** → veraltete DerivedData: `./build.sh clean && ./build.sh`
- **Helper registrieren sich nie** → bei Option B erwartet; für die Helper Option A verwenden
- **Fehler bei Deployment Target / SDK** → Agent! zielt auf macOS 26; macOS und Xcode aktualisieren
- **Konfigurationsargument ist case-sensitiv** → `./build.sh` (Debug) oder `./build.sh Release`

## Was kann es?

> *„Baue das Xcode-Projekt und behebe alle Fehler"* · *„Spiel meine Workout-Playlist in Musik"* · *„Mach ein Foto mit Photo Booth"* · *„Schick Mama eine iMessage, dass ich um 6 zu Hause bin"* · *„Öffne Safari und such nach Flügen nach Tokio"* · *„Teile diese Klasse in kleinere Dateien auf"* · *„Welche Kalendertermine habe ich heute?"*

Tipp einfach, was du willst. Agent! findet heraus wie und setzt es um.

---

## Hauptfunktionen

- **🧠 Selbstprüfende Aufgabenschleife** — denkt, führt aus, beobachtet Ergebnisse, korrigiert sich selbst. Eine Aufgabe kann sich nicht als erledigt erklären, bis die `goal_state`-Kriterien mit Beweisen markiert sind; ein optionaler Kritiker prüft zuerst den Diff.
- **🛠 Agentisches Coding** — liest Codebasen, bearbeitet mit String-Replace-Diffs, baut Xcode-Projekte nativ (klickbare Fehler), verwaltet Git, indiziert Repos in eine portable JSONL-Repo-Map. Jede Änderung wird gesichert — Ein-Klick-Rollback oder `rewind_task` für die ganze Aufgabe.
- **🖥 Desktop-Automatisierung** — steuert jede Mac-App über die Accessibility-API ([AXorcist](https://github.com/steipete/AXorcist)), elementbasiert mit unscharfem Auto-Retry. Dazu NSAppleScript, JXA und 51 ScriptingBridge-App-Bridges, alle in-process mit TCC.
- **📜 AgentScript** — Swift-Dylibs, zur Laufzeit kompiliert und per `dlopen` in-process mit vollem TCC geladen. Gelöschte Skripte landen im `.Trash` und sind wiederherstellbar.
- **🛡 Privilegierte Ausführung** — Shell als du über einen Launch Agent oder als root über einen Launch Daemon, den du genau einmal genehmigst (SMAppService + XPC). Siehe [docs/SECURITY.md](docs/SECURITY.md), warum SMAppService die Signaturidentität bereits durchsetzt.
- **🎙 Sprache** — sag **„Agent!"** gefolgt von deiner Aufgabe; geräteinterner `SFSpeechRecognizer`, startet automatisch nach ~2,5 s Stille, läuft in Schleife.
- **📱 iMessage-Fernsteuerung** — schreib `Agent! next song` von deinem iPhone; nur genehmigte Absender. Braucht Vollzugriff auf die Festplatte für `chat.db`.
- **🌐 Web** — eingebaute Safari-Automatisierung (JavaScript + AppleScript); optional Selenium und [Playwright MCP](https://github.com/microsoft/playwright-mcp) für mehrere Browser.
- **🤝 Sub-Agenten** — bis zu 3 parallel (6 nur lesend) isolierte Agenten mit Mailbox-Messaging und Modell-Override pro Agent.
- **🧩 MCP** — beliebige MCP-Server unter Einstellungen → MCP-Server hinzufügen; Tools erscheinen als `mcp_<server>_<tool>`. Xcode MCP: `{"mcpServers":{"xcode":{"command":"xcrun","args":["mcpbridge"],"transport":"stdio"}}}`.
- **🗂 Tabs, Verlauf, Gedächtnis, Pläne, Skills** — jeder Tab hat eigenen Projektordner und eigenes Log; persistentes Nutzergedächtnis; Multi-Plan-Checklisten in jedem Prompt.
- **🔄 Fallback-Kette** — automatischer Wechsel zum nächsten konfigurierten Anbieter bei 429/Timeout/Netzwerkfehler.

## 🤖 18 KI-Anbieter

| Anbieter | Kosten | Am besten für |
|---|---|---|
| **Claude** | Kostenpflichtig | Lange autonome Aufgaben, Extended Thinking, Prompt-Caching |
| **OpenAI** | Kostenpflichtig | Allzweck, Tool-Calling, Vision, `reasoning_effort` |
| **Google Gemini** | Kostenpflichtig (Free Tier) | Langer Kontext, Vision |
| **Grok** (xAI) | Kostenpflichtig | Echtzeit-Informationen |
| **Mistral** / **Codestral** / **Mistral Vibe** | Kostenpflichtig | Open-Weight-Cloud, Code, Agent-Produkt |
| **DeepSeek** | Günstig | Budget-Coding, Cache-Hit-Reporting |
| **Hugging Face** | Variabel | Offene Modelle, serverless oder dedizierte Endpunkte |
| **OpenRouter** | Kostenpflichtig | 200+ Modelle, ein Schlüssel; Claude über Anthropic-Protokoll |
| **Z.ai** / **BigModel** | Günstig | GLM-5.1 — empfohlener Einstieg |
| **Qwen** (Alibaba) | Günstig | Qwen 2.5 / 3 über Dashscope |
| **Ollama** (Cloud) | Free Tier | Gehostete offene Modelle |
| **Lokales Ollama** / **vLLM** / **LM Studio** | Kostenlos + Hardware | Komplett offline; echtes Kontextfenster pro Modell wird erkannt |
| **Apple Intelligence** | Kostenlos, auf dem Gerät | Triage, Zusammenfassungen, Token-Kompression (Gehirn-Symbol, nicht die Anbieterauswahl) |

> 💡 Selbst gehostete Anbieter sind nur im Sinne der API-Gebühren kostenlos — ein brauchbares 30B+-Modell braucht einen M2/M3/M4 Ultra Mac Studio (64–128 GB). Ohne diese Hardware sind die günstigen Cloud-Wege oben deutlich billiger.

## Tools

Die kanonischen Namen stammen aus `AgentTools.Name.*` (Quelle: das [AgentTools](https://github.com/AgentiLoop/AgentTools)-Paket). Pro Anbieter lassen sich einzelne Tools ausblenden.

| Gruppe | Tools |
|---|---|
| **Core** | `done` · `list_tools` · `search` · `web_search` · `fetch` · `chat` · `memory` · `plan` · `goal_state` · `restore_tool_result` · `directory` · `skill` · `ask_user` · `index` |
| **Code / Build** | `file` (read/write/edit/diff_apply/undo/list/search/mkdir/…) · `git` · `xcode` (build/run/analyze/snippet/code_review/add_file/bump_version/…) · `agent_script` |
| **Shell** | `user_shell` (Launch Agent) · `root_shell` (Launch Daemon) · `shell` (In-Process-Fallback) · `batch` · `multi` |
| **macOS-Automatisierung** | `accessibility` (25 elementbasierte Aktionen) · `applescript` (mit `lookup_sdef`) · `javascript` (JXA) |
| **Web** | `safari` · `selenium` · `mcp_playwright_browser_*` (optional) |
| **Sub-Agenten** | `spawn_agent` · `tell_agent` |

Vollständige Referenz pro Aktion: [docs/TECHNICAL.md](docs/TECHNICAL.md).

## AgentScript — Swift-Skripte mit vollem TCC

AgentScripts sind einfache Swift-Dateien in `~/Documents/AgentScript/agents/Sources/Scripts/`. Agent! kompiliert jede davon per SwiftPM zu einer `.dylib` (`Package.swift` listet jedes Skript plus die 51 ScriptingBridge-App-Bridges) und lädt sie per `dlopen` mit Agent!s eigenen TCC-Freigaben — Bedienungshilfen, Automation, Kalender, Kontakte, Mail, Fotos usw. Das LLM verwaltet sie über `agent_script` (`create` / `edit` / `run` / `delete` / `restore` / `pull`); ~35 Beispiele liegen im Ordner (`Hello`, `TodayEvents`, `NowPlaying`, `CheckMail`, `CreateDmg`, `ArchiveXcode`, …).

**Einstiegspunkt** — kein Top-Level-Code, kein `exit()`; `stdout` geht zurück ans LLM, der Rückgabewert ist der Exit-Status:

```swift
import Foundation
import CalendarBridge   // jedes `import XBridge` wird automatisch verdrahtet — keine Package.swift-Änderung nötig

@_cdecl("script_main")
public func scriptMain() -> Int32 {
    print("Hello from AgentScript! 👋")
    return 0
}
```

**Umgebungsvariablen — wie sie GESETZT werden.** Das LLM fasst die Umgebung nie selbst an. Es ruft das Tool auf, und Agent!s `ScriptService` exportiert die Variablen in den Prozess des Skripts (`env["AGENT_PROJECT_FOLDER"] = cwd`, `env["AGENT_SCRIPT_ARGS"] = arguments` in `ScriptService+Execution.swift`; `setenv(...)` für die In-Process-Variante). Dieselben zwei Variablen werden in jeden `user_shell`- / `root_shell`- / `shell`-Befehl exportiert.

```text
LLM-Tool-Aufruf                                        Was Agent! ins Skript exportiert
─────────────────────────────────────────────────────  ─────────────────────────────────────────────
agent_script(action:"run", name:"TodayEvents")         AGENT_PROJECT_FOLDER=/Users/du/Documents/GitHub/Agent
                                                       (AGENT_SCRIPT_ARGS ist NICHT gesetzt)

agent_script(action:"run", name:"TodayEvents",         AGENT_PROJECT_FOLDER=/Users/du/Documents/GitHub/Agent
             arguments:"days=3,location=false,json=true")   AGENT_SCRIPT_ARGS="days=3,location=false,json=true"
```

| Variable | Wann gesetzt | Bedeutung |
|---|---|---|
| `AGENT_PROJECT_FOLDER` | Immer | Der Projektordner des aktiven Tabs (oder `$HOME`, falls keiner). Auch das cwd des Runners wird darauf gesetzt. |
| `AGENT_SCRIPT_ARGS` | Nur wenn das LLM `arguments:"…"` übergibt | Genau der String, den das LLM übergeben hat. Die Beispiele nutzen die Konvention `key=value,key=value`. |

**Umgebungsvariablen — wie sie EINGELESEN werden.** Im Skript kommen beide aus `ProcessInfo.processInfo.environment`. Das ist exakt das Parsing-Muster aus `Hello.swift` / `TodayEvents.swift`:

```swift
import Foundation

@_cdecl("script_main")
public func scriptMain() -> Int32 {
    let env = ProcessInfo.processInfo.environment

    // 1. Projektordner — immer vorhanden; zur Sicherheit auf cwd zurückfallen
    let folder = env["AGENT_PROJECT_FOLDER"] ?? FileManager.default.currentDirectoryPath

    // 2. Argumente — fehlen, sofern das LLM nicht `arguments:"…"` übergeben hat
    let argsString = env["AGENT_SCRIPT_ARGS"] ?? ""

    // 3. Standardwerte, dann "key=value,key=value" parsen
    var daysAhead    = 0
    var showLocation = true
    var outputJSON   = false

    for pair in argsString.split(separator: ",") {
        let parts = pair.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { continue }
        switch parts[0] {
        case "days":     daysAhead    = Int(parts[1]) ?? 0
        case "location": showLocation = parts[1].lowercased() == "true"
        case "json":     outputJSON   = parts[1].lowercased() == "true"
        default: break
        }
    }

    print("Projektordner: \(folder)")
    print("days=\(daysAhead) location=\(showLocation) json=\(outputJSON)")
    return 0
}
```

Beide Variablen sind unabhängig — den Projektordner nie aus `AGENT_SCRIPT_ARGS` herauslesen. Bash-Äquivalent in `user_shell`: `ls "$AGENT_PROJECT_FOLDER/Sources"` (cwd ist bereits dort, kein `cd` nötig).

**Echte `AGENT_SCRIPT_ARGS`-Konventionen aus den mitgelieferten Skripten** (`~/Documents/AgentScript/agents/Sources/Scripts/`):

| Skript | `arguments:`, die das LLM übergibt | Stil |
|---|---|---|
| `TodayEvents` | `days=3,location=false,json=true` | `key=value,…` |
| `CheckMail` | `unreadOnly=true,inboxCount=true,json=true` | `key=value,…` |
| `ListReminders` | `completed=false,limit=5` | `key=value,…` |
| `QuitApps` | `excluded=Xcode,Agent,Terminal` | `key=value` mit Liste |
| `NowPlaying` | `json=true,artwork=true` | `key=value,…` |
| `ArchiveXcode` | `/path/to/Project.xcodeproj MyScheme 469UCUB275` | positionsbasiert, leerzeichengetrennt (Scheme/Team-ID werden automatisch erkannt, wenn weggelassen) |
| `CreateDmg` | `--app /path/to/App.app --output /path/out.dmg --name "My App" --compress` | Flag-Stil, leerzeichengetrennt, Anführungszeichen werden beachtet |

**JSON-Eingabe / -Ausgabe — ein SEPARATER Mechanismus, unabhängig von den Umgebungsvariablen.** Umgebungsvariablen werden von Agent! in den Prozess exportiert; JSON-Dateien sind einfache Dateien auf der Festplatte, die das *Skript selbst* mit `FileManager` / `JSONSerialization` liest und schreibt. Agent! erzeugt, übergibt oder parst sie nicht. Zwei echte Muster aus den mitgelieferten Skripten:

*1. Nur JSON-Eingabe (`SendMessage`)* — gar keine Env-Argumente; das Skript verlangt `SendMessage_input.json` und gibt `1` zurück, wenn sie fehlt:

```json
// ~/Documents/AgentScript/json/SendMessage_input.json   (vom LLM per file(action:"write") vor dem Lauf geschrieben)
{ "recipient": "Mama", "message": "Um 6 zu Hause", "imagePath": "~/Pictures/Photos Library.photoslibrary/originals/A/IMG_0001.jpeg" }

// ~/Documents/AgentScript/json/SendMessage_output.json  (vom Skript geschrieben)
{ "success": true, "timestamp": "2026-09-03T21:14:02Z", "recipient": "Mama", "message": "Um 6 zu Hause" }
// bei Fehler: { "success": false, "timestamp": "…", "error": "Missing required field: recipient" }
```

```swift
// SendMessage.swift — so liest das Skript die Datei
let inputPath  = "\(NSHomeDirectory())/Documents/AgentScript/json/SendMessage_input.json"
guard let inputData = FileManager.default.contents(atPath: inputPath) else {
    writeOutput(outputPath, success: false, error: "Input file not found: \(inputPath)"); return 1
}
guard let json = try? JSONSerialization.jsonObject(with: inputData) as? [String: Any],
      let recipientHandle = json["recipient"] as? String else { /* … */ return 1 }
let message   = json["message"]   as? String
let imagePath = json["imagePath"] as? String
```

*2. Env-Argumente für Optionen, JSON für strukturierte Ausgabe (`TodayEvents`, `NowPlaying`, `CheckMail`, `ListReminders`)* — Optionen kommen aus `AGENT_SCRIPT_ARGS` (oder der optionalen `<Name>_input.json`); bei `json=true` schreibt das Skript `<Name>_output.json` zusätzlich zur lesbaren stdout-Ausgabe, die ans LLM zurückgeht:

```json
// agent_script(action:"run", name:"TodayEvents", arguments:"days=3,json=true")
// → ~/Documents/AgentScript/json/TodayEvents_output.json
{ "success": true, "timestamp": "…", "count": 2,
  "events": [ { "summary": "Standup", "calendar": "Work", "startTime": "…", "endTime": "…", "allDay": false, "location": "…" }, … ] }

// agent_script(action:"run", name:"NowPlaying", arguments:"json=true,artwork=true")
// → ~/Documents/AgentScript/json/NowPlaying_output.json
{ "success": true, "playerState": "playing",
  "track": { "name": "…", "artist": "…", "album": "…", "duration": 240 },
  "artwork": { "saved": true, "path": "~/Documents/AgentScript/images/….png", "width": 500, "height": 500 } }
```

```swift
// TodayEvents.swift — so schreibt das Skript die Datei
func writeTodayEventsOutput(_ path: String, success: Bool, error: String? = nil,
                            events: [[String: Any]]? = nil, count: Int? = nil, outputJSON: Bool) {
    guard outputJSON else { return }
    var result: [String: Any] = ["success": success, "timestamp": ISO8601DateFormatter().string(from: Date())]
    if !success, let error { result["error"] = error }
    if success { if let events { result["events"] = events }; if let count { result["count"] = count } }
    try? FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
    if let out = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted) {
        try? out.write(to: URL(fileURLWithPath: path))
    }
}
```

Gelöschte Skripte landen in `~/Documents/AgentScript/agents/.Trash/` (`agent_script(action:"restore")`); `action:"pull"` holt die Upstream-Version aus dem [AgentScripts](https://github.com/AgentiLoop/AgentScripts)-Repo.

## Datenschutz & Sicherheit

Deine Dateien, Bildschirminhalte und persönlichen Daten verlassen deinen Mac nie — Cloud-Anbieter sehen nur den Prompt-Text; lokale Anbieter halten alles offline. Jede Aktion wird protokolliert.

| Schicht | Was sie tut |
|---|---|
| **Shell Safety Service** | Blockiert `rm -rf /`, `rm -rf ~`, `rm -rf` mit nacktem Glob, `--no-preserve-root` hart — client-seitig **und** daemon-seitig durchgesetzt. Vom LLM nicht umgehbar. |
| **XPC-Client-Vertrauen** | Beide Listener verlangen Code-Signing mit demselben Team, abgeleitet aus der eigenen Signatur der App; Release-Builds lehnen Clients ohne Team ab. |
| **Read-before-edit-Gate** | Änderungen an ungelesenen oder extern geänderten Dateien werden verweigert (SHA-256), mit Auto-Read bei Verweigerung. |
| **Datei-Backups + Rewind** | Jede Änderung gesichert (1 Woche TTL); Rollback-UI, `file(action:"undo")` oder aufgabenbezogenes `rewind_task`. |
| **TCC-In-Process-Routing** | AppleScript-/JXA-/screencapture-/Accessibility-Befehle laufen in-process, wo Agent! die TCC-Freigaben hält, nie über die Daemons. |
| **Tool-Ausführungs-Gating** | Das LLM kann keine Ergebnisse erfinden — jeder Aufruf läuft durch `dispatchTool()` und liefert echte Ausgaben. Behauptungen wie „ich habe geklickt/gesucht…" ohne Tool bekommen eine Korrektur injiziert. |
| **Typisierte Fehler + Guards** | Jedes fehlgeschlagene Tool-Ergebnis trägt einen Wiederherstellungshinweis; Broken-Record- und Stuck-Guards stupsen an und stoppen dann; Abschluss-Gates begrenzen Verweigerungen auf 3 pro Aufgabe. |
| **Konsolen-Audit-Trail** | Jeder Tool-Aufruf und jeder Helper-Befehl wird protokolliert. |

## Tastaturkürzel & Slash-Befehle

| Kürzel | Aktion |
|---|---|
| `Return` | Aufgabe starten · `⌘ .` / `Esc` abbrechen |
| `⌘ T` / `⌘ W` / `⌘ 1–9` / `⌘ ⇧ ←→` | Tab neu / schließen / wechseln / vor-zurück |
| `⌘ B` / `⌘ D` | LLM-Output-Overlay / Chevrons umschalten |
| `⌘ F` / `⌘ L` / `⌘ V` | Log durchsuchen / Log leeren / Bild einfügen |
| `↑` / `↓` | Prompt-Verlauf |
| `⌘ ⇧ M` / `⌘ ⇧ P` | Messages-Monitor / Einstellungen |
| `⌘ ⇧ K` `L` `H` `J` `U` | Alles / LLM-Panel / Prompt-Verlauf / Aufgabenverlauf / Token-Zähler leeren |

Slash-Befehle laufen lokal: `/clear [log|all|llm|history|tasks|tokens]`, `/memory [show|clear|edit|<text>]`.

## FAQ

**Muss ich programmieren können?** Nein — einfaches Deutsch (oder deine Muttersprache).
**Was kostet es?** Die App ist kostenlos (MIT). Du bezahlst deinen Anbieter; GLM-5.1 über Z.ai/BigModel oder DeepSeek sind für ernsthafte Arbeit am günstigsten. Lokale Modelle sind kostenlos, wenn du die Hardware besitzt.
**Welchen Mac brauche ich?** Apple Silicon, macOS 26.4.1+. Jeder moderne Mac für Cloud-Anbieter; 64 GB+ für lokale 30B-Modelle.
**Was unterscheidet das von Siri?** Siri antwortet. Agent! *handelt* — Apps, Dateien, Code, System.

Mehr: [docs/FAQ.md](docs/FAQ.md) · [Technische Architektur](docs/TECHNICAL.md) · [Vergleiche](docs/COMPARISON.md) (vs. Claude Code, Cursor, Cline, OpenClaw) · [Sicherheitsmodell](docs/SECURITY.md)

## Entstehungsgeschichte

Agent! ist das Ergebnis von drei Jahren Entwicklung agentischer KI-Apps — ANIE, Game Changer, BattleScript, XCF MCP Server and Client, D1F und rund acht originale Swift-Pakete. Das fehlende Puzzlestück war eine intelligente autonome Schleife; sobald sie erreicht war, floss das Beste dieser Projekte in Agent! zusammen. Es hat Videospiele geschrieben ([Boss-Man](https://github.com/AgentiLoop/bossman)), Apps erstellt, Gedichte per AppleScript in Pages verfasst, Disk-Images erzeugt und an GitHub-Releases angehängt. Wo Claude Code auf ~65 NPM-Pakete von Drittanbietern setzt, ist Agent! zu 100 % nativ, braucht sehr wenig RAM und bringt Xcode-Automatisierung, Swift-Syntax-6.2-Analyse, Accessibility, AppleScript, AgentScript/ScriptingBridge, Safari-Automatisierung und MCP-Unterstützung direkt mit.

## Mitwirken

Siehe [CONTRIBUTING.md](./CONTRIBUTING.md) — in ~5 Minuten mit `./build.sh` aus dem Quellcode bauen, kein Developer-Konto nötig. Pull Requests durchlaufen den CI-Build-&-Test-Workflow. Schau dir die [good first issues](https://github.com/AgentiLoop/Agent/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) an.

## Lizenz

MIT — kostenlos und Open Source.

---

> ⚠️ **Rechtlicher Hinweis & Zuschreibung**
>
> ### Markenhinweis
>
> „AgentiLoop Agent! for Mac" ist ein unabhängiges Softwareprojekt und **nicht** mit Apple Inc. verbunden, von Apple genehmigt, gesponsert oder anderweitig assoziiert. „Apple", „Mac", „Mac mini", „MacBook", „macOS" und verwandte Marken sind Marken von Apple Inc., eingetragen in den USA und anderen Ländern. Alle anderen hier erwähnten Marken, Dienstleistungsmarken und Handelsnamen sind Eigentum ihrer jeweiligen Inhaber und werden nur zu Identifikationszwecken verwendet.
>
> „🦾 Agent!" und das 🦾-Agent!-Logo sind Marken von AgentiLoop Agent. Die Nutzung dieser Marken erfordert vorherige schriftliche Genehmigung. Die untenstehende MIT-Lizenz gewährt Rechte nur am Quellcode — sie gewährt **keine** Markenrechte.
>
> ### Quellcode-Lizenz (MIT)
>
> Der Quellcode von „AgentiLoop Agent! for Mac" ist Open Source und unter der **MIT-Lizenz** lizenziert. Es steht dir frei, Kopien des Quellcodes zu nutzen, zu kopieren, zu modifizieren, zusammenzuführen, zu veröffentlichen, zu verteilen, unterzulizenzieren und/oder zu verkaufen, vorbehaltlich der Bedingungen in der [LICENSE](./LICENSE)-Datei (Beibehaltung des Copyright-Hinweises und des MIT-Genehmigungshinweises in allen Kopien oder wesentlichen Teilen der Software).
>
> ### Kompilierte Binärdateien & Releases
>
> Kompilierte Binärdateien, Installationsprogramme, code-signierte Builds und Release-Artefakte, die über die GitHub Releases dieses Projekts, [AgentiLoop.ai](https://AgentiLoop.ai), oder jeden anderen offiziellen Kanal verteilt werden, sind das urheberrechtlich geschützte Werk von AgentiLoop Agent und **nicht** von der MIT-Lizenz abgedeckt, die den Quellcode regelt. Alle Rechte an den offiziellen Binärdateien — einschließlich des Namens „🦾 Agent!", des Logos, der Code-Signing-Identität und der Developer ID — sind vorbehalten.
>
> Copyright © 2000, 2023–2026 AgentiLoop Agent, Alle Rechte vorbehalten.
>
> Du bist herzlich eingeladen, deine eigenen Binärdateien aus dem Quellcode unter der MIT-Lizenz zu bauen, solange du nicht den Namen „🦾 Agent!", das Logo oder das Branding zur Identifikation deines Produkts verwendest.
>
> ### Gewährleistungsausschluss
>
> Diese Software wird **„WIE BESEHEN"** bereitgestellt, ohne Gewährleistung jeglicher Art, weder ausdrücklich noch stillschweigend, einschließlich, aber nicht beschränkt auf die Gewährleistungen der Marktgängigkeit, der Eignung für einen bestimmten Zweck und der Nichtverletzung von Rechten Dritter. In keinem Fall haften der Autor oder der Urheberrechtsinhaber für Ansprüche, Schäden oder sonstige Haftung, sei es aus einer vertraglichen Handlung, unerlaubter Handlung oder anderweitig, die sich aus der Software oder der Nutzung oder anderen Vorgängen mit der Software ergeben.
>
> ---
>
> Danke für dein Interesse an 🦾 Agent! — einer Anwendung, entwickelt für Mac-mini-, MacBook- und Mac-Studio-Computer, die macOS 26.4 oder neuer auf originaler Mac-Hardware und -Software ausführen.
>
> - Website: https://AgentiLoop.ai
> - Github : https://github.com/AgentiLoop/agent
