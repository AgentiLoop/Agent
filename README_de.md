# 🦾 Agent! für macOS 26.4.1 oder neuer

## **Agentische KI für deinen Mac-Desktop**

[![Latest Release](https://img.shields.io/github/v/release/macOS26/Agent?label=Download&color=blue&style=for-the-badge)](https://github.com/macOS26/Agent/releases/latest)
[![GitHub Stars](https://img.shields.io/github/stars/macOS26/Agent?style=for-the-badge&logo=github&label=Stars&color=gold)](https://github.com/macOS26/Agent/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/macOS26/Agent?style=for-the-badge&logo=github&label=Forks&color=white)](https://github.com/macOS26/Agent/fork)
[![macOS 26.4+](https://img.shields.io/badge/macOS-26.4.1-green?style=for-the-badge)](https://github.com/apple)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange?style=for-the-badge)](https://www.swift.org)
<a href="https://www.paypal.com/ncp/payment/9C6RY2UAE5M3S"><img src="https://img.shields.io/badge/Donation-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Tip Jar" /></a>

## Schach in Agent
<img width="1176" height="724" alt="Screenshot 2026-08-23 at 7 34 10 PM" src="https://github.com/user-attachments/assets/d3b2f1e5-1dab-44f7-95f6-008424ee794c" />

## Entstehungsgeschichte und die Technik hinter Agent!
Agent! ist nicht über Nacht entstanden. Es ist das Ergebnis von drei Jahren Entwicklung agentischer KI-Apps, aufbauend auf rund einem Dutzend Projekten, die auf dem Weg entstanden sind. Einige davon wurden unter den Namen ANIE, Game Changer, BattleScript, XCF MCP Server and Client, D1F und etwa acht originalen Swift-Paketen veröffentlicht. Das fehlende Puzzlestück war das Erreichen einer intelligenten, autonomen Zeitschleife. Sobald das erreicht war, brachte ich das Beste der letzten drei Jahre zusammen. Das Ergebnis ist Agent! für macOS 26.4.1 oder neuer.

Das ursprüngliche Ziel war es, einen „Cursor-Killer" zu bauen. Herausgekommen ist etwas Interessanteres: eine agentische KI mit echten Beinen. Agent! wird nur durch deine Vorstellungskraft begrenzt. Er kann Code schreiben, einschließlich Videospielen wie Boss-Man, https://github.com/macos26/bossman, Apps erstellen, Gedichte über AppleScript in Pages verfassen, Disk-Images erzeugen und sie an GitHub-Releases anhängen. Er kann die meisten Aufgaben auf deinem Mac automatisieren. Frag ihn in einfachem Englisch oder deiner Muttersprache nach dem, was du willst, und nach einer anfänglichen Konfiguration und Nutzerfreigaben wird er alles tun, um deinen Wunsch zu erfüllen. Agent! ist unermüdlich und will gefallen.

Das gesamte geistige Eigentum von Agent! ist original und Open Source. Jede Swift-Paketabhängigkeit und die App selbst wurden ursprünglich von derselben Person geschrieben. Das ist ein wirklich anderes Ökosystem. Die meisten agentischen KI-Apps wie Claude Code verlassen sich auf 65 NPM-Pakete von Drittanbietern. Agent! ist zu 100 % nativ, benötigt sehr wenig RAM und wiegt unkomprimiert 35,5. Dieser Fußabdruck umfasst Xcode-Automatisierung, ein Swift-Syntax-6.2-Paket zur Fehlerbehebung nativer Apps, Accessibility, AppleScript, AgentScript/ScriptingBridge, Safari-Automatisierung, MCP-Server-Unterstützung und mehr. Alles direkt einsatzbereit.

## Neuigkeiten 🚀

**v1.0.92 (186) — Das Release der selbstverifizierenden Autonomie** · [Vollständige Release-Notizen →](https://github.com/macOS26/Agent/releases/tag/v1.0.92.186)

Agent! beweist jetzt seine Arbeit. Eine Aufgabe kann sich erst dann als erledigt erklären, wenn ihre Erfolgskriterien mit Nachweisen verifiziert wurden (`goal_state`), ein optionaler Kritiker den Diff vor Abschluss prüft und jede berührte Datei mit einem einzigen Klick zurückgerollt werden kann (`rewind_task`). Erweitertes Denken für Claude, `reasoning_effort` für OpenAI-kompatible Anbieter, und ein prompt-cache-stabiler Kontext, der sich auf das reale Fenster jedes Modells komprimiert — wiederherstellbar, mit allen Tool-Ergebnissen auf die Festplatte ausgelagert. Typisierte Tool-Fehler enthalten Wiederherstellungshinweise, Sub-Agenten laufen mit eigenen Modellen (bis zu 6 schreibgeschützte Rechercheure), Event-Hooks sind vollständig verdrahtet, und 57 erfolgreiche Tests halten alles ehrlich.

**Eine App. Jede KI. Volle Kontrolle über deinen Mac.**

Agent! verbindet **18 LLM-Anbieter** — Claude, GPT, Gemini, Grok, Mistral, DeepSeek, Qwen, Z.ai, BigModel, Hugging Face, **OpenRouter**, Ollama (Cloud und lokal), vLLM, LM Studio, Codestral, Mistral Vibe und die geräteinterne **Apple Intelligence** — zu einer nativen macOS-App, die nicht nur über das Erledigen von Dingen spricht. Sie erledigt sie.

Sieh zu, wie er deine Codebasis liest, den Fehler behebt, das Xcode-Projekt baut und den Diff committet, während du dir einen Kaffee machst. Sag ihm, er soll Safari öffnen und dir den Preis für Flüge nach Tokio per Nachricht schicken. Sag *„Agent!"* quer durch den Raum und lass ihn per Sprache deine Testsuite ausführen. Schreib deinem Mac per iMessage und erhalte eine ausgefeilte Antwort, bevor du dein Auto erreichst.

Er bearbeitet Dateien mit chirurgisch präzisen String-Replace-Diffs — jede Änderung mit einem Klick rückgängig zu machen dank eines Time-Machine-artigen Rollbacks. Er steuert jede Mac-App über die Accessibility-API — kein AppleScript erforderlich. Er merkt sich deine Präferenzen über Sitzungen hinweg. Er erzeugt parallele Sub-Agenten für Arbeit, die sich auffächert. Er indiziert ganze Codebasen in eine portable JSONL-Repo-Map, die jedes LLM verwenden kann. Er führt Shell-Befehle als du aus, oder als Root über einen Launch Daemon, den du genau einmal genehmigst.

Bring deinen eigenen API-Key mit. Führe es vollständig lokal auf Ollama, vLLM oder LM Studio aus. Oder nutze es kostenlos, für immer, mit Apple Intelligence. Kein Abo. Keine Telemetrie. Keine Anbieterbindung. Deine Keys, deine Maschine, deine Daten.

Lade es herunter. Sag, was du brauchst. Sieh zu, wie es passiert.

## Schnellstart (Download)

1. **Lade** [Agent!](https://github.com/macOS26/Agent/releases/latest) herunter und ziehe es in den Programme-Ordner
2. **Öffne Agent!** -- alles wird automatisch eingerichtet
3. **Wähle deine KI** -- Einstellungen → Anbieter wählen → API-Key eingeben

## Schnellstart (Aus dem Quellcode bauen)

1. **Klone das Repository:**
   ```bash
   git clone https://github.com/macos26/agent.git
   cd Agent
   ```

#### Option A: Mit Xcode bauen (Apple-Developer-Konto)
2. **Öffne `Agent.xcodeproj` in Xcode.**
3. **Baue und starte das `Agent`-Target.**
4. **Genehmige das Hilfsprogramm:** Wenn du dazu aufgefordert wirst, autorisiere den privilegierten Daemon, um die Ausführung von Befehlen auf Root-Ebene zu ermöglichen.

#### Option B: Bauen ohne Apple-Developer-Konto
2. **Führe das Build-Skript aus** (benötigt nur die Xcode Command Line Tools):
   ```bash
   ./build.sh              # Debug-Build
   ./build.sh Release      # Release-Build
   ```
3. Die App landet in `build/DerivedData/Build/Products/Debug/Agent!.app`
4. **Starte sie:** `open "build/DerivedData/Build/Products/Debug/Agent!.app"`

> ⚠️ Ohne Developer-Konto ist die App ad-hoc signiert. Die Launch-Agent-/Daemon-Helfer registrieren sich nicht (SMAppService benötigt eine Team-ID), aber die LLM-Schleife, alle Tools, Accessibility, AppleScript, Shell und MCP funktionieren allesamt.

#### Danach:
5. **Konfiguriere deinen KI-Anbieter:** Gehe zu Einstellungen und gib deinen API-Key ein oder wähle einen lokalen Anbieter wie Ollama.

> 💡 **Günstige GLM-Einrichtung:** **GLM-5.1** läuft auf allen vier günstigen Anbietern — **Ollama**, **Hugging Face**, **Z.ai**, **BigModel** — für Cent-Beträge pro Million Tokens. Neu hier? Starte mit **Z.ai** (schnellste Anmeldung, GLM-5.1 ist Standard, nichts zu bereitstellen). Läufst du lokal? Nur **GLM-4.7-Turbo** (32B) passt auf Consumer-Hardware (M2/M3/M4-Mac, 64-128GB, über Ollama) — GLM-5 und GLM-5.1 sind zu groß (~1,6TB), nutze sie über die oben genannten Cloud-Anbieter.


## Was kann er tun?

> *„Spiel meine Workout-Playlist in Music"*
> *„Baue das Xcode-Projekt und behebe alle Fehler"*
> *„Mach ein Foto mit Photo Booth"*
> *„Sende Mama eine iMessage, dass ich um 18 Uhr zu Hause bin"*
> *„Öffne Safari und suche nach Flügen nach Tokio"*
> *„Refaktoriere diese Klasse in kleinere Dateien"*
> *„Welche Kalendertermine habe ich heute?"*

Tippe einfach, was du willst. Agent! findet heraus, wie, und erledigt es.

---

## Hauptfunktionen

### 🧠 Agentisches KI-Framework
Eingebaute autonome Aufgabenschleife, die schlussfolgert, ausführt und sich selbst korrigiert. Agent! führt nicht nur Code aus; er beobachtet die Ergebnisse, debuggt Fehler und iteriert, bis die Aufgabe abgeschlossen ist. Der Zielzustand mit nachweisverifizierten Erfolgskriterien bedeutet, dass sich eine Aufgabe erst dann als erledigt erklären kann, wenn sie es beweist.

### 🛠 Agentisches Coding
Vollständige, eingebaute Coding-Umgebung. Liest Codebasen, bearbeitet Dateien präzise, führt Shell-Befehle aus, baut Xcode-Projekte, verwaltet git und aktiviert automatisch den Coding-Modus, um die KI auf Entwicklungstools zu fokussieren. Ersetzt Claude Code, Cursor und Cline -- kein Terminal, keine IDE-Plugins, keine monatliche Gebühr. Bietet **Time-Machine-artige Backups** für jede Dateiänderung, mit denen du jede Bearbeitung sofort rückgängig machen kannst.

### 🔍 Dynamische Tool-Erkennung
Erkennt und nutzt automatisch verfügbare Tools (Xcode, Playwright, Shell usw.) basierend auf deiner Anweisung. Keine manuelle Konfiguration für Kern-Tools erforderlich.

### 🛡 Privilegierte Ausführung
Führt Root-Level-Befehle sicher über einen dedizierten macOS Launch Daemon aus. Der Nutzer genehmigt den Daemon einmal, danach kann der Agent Befehle autonom über XPC ausführen.

#### Warum es kein manuelles `setCodeSigningRequirement` am XPC-Listener gibt

Nutzer fragen manchmal, warum der XPC-Listener von `AgentHelper` Verbindungen ohne eine manuelle Prüfung von `connection.setCodeSigningRequirement(...)` akzeptiert. Die kurze Antwort: **SMAppService erzwingt die Signaturidentität bereits eine Ebene unterhalb deines Codes**, sodass die Prüfung redundant wäre.

Diese Empfehlung ist ein Relikt aus der Vor-SMAppService-Ära, **SMJobBless**, in der launchd die Identität nicht für dich validierte und der XPC-Server selbst eine designierte Anforderungszeichenkette setzen musste. SMAppService hat diesen Vertrag geändert:

- Das im App-Bundle eingebettete plist zusammen mit der signaturgesicherten Registrierung **ist** die Code-Signing-Anforderung.
- Die Mach-Servicenamen (`Agent.app.redacted.helper`, `Agent.app.redacted.user`) sind an das signierte Bundle gebunden, das sie registriert hat — kein anderes Bundle kann sie beanspruchen.
- Jede Signaturabweichung (Manipulation, Neusignierung, andere Team-ID, Bundle-Austausch) **unterbricht den XPC-Kanal auf launchd-Ebene** — `listener(_:shouldAcceptNewConnection:)` wird gar nicht erst aufgerufen.

**Empirischer Nachweis:** Agent! selbst versuchte in einem Experiment, seine eigenen Daemons neu zu signieren, und verlor sofort die Verbindungsfähigkeit. `NSXPCConnection` zu beiden Mach-Services schlug auf launchd-Ebene fehl, bevor auch nur ein Byte den Listener-Delegate erreichte — genau das Verhalten, das ein manueller `setCodeSigningRequirement`-Aufruf erzwingen würde, außer dass SMAppService dies im XPC-Lookup-Pfad des Kernels tut, wo es aus dem Userland nicht umgangen werden kann.

| Durchsetzung | Mechanismus | Aus dem Userland umgehbar? |
|---|---|---|
| Helper muss im signierten App-Bundle sein | Gatekeeper + SMAppService-Registrierung | Nein |
| Helper muss zur Team-ID der App passen (469UCUB275) | Code-Signierung + SMAppService | Nein |
| Mach-Servicename an signiertes Bundle gebunden | launchd-/XPC-Namespace | Nein |
| Hash der Helper-Binärdatei stimmt mit registrierter Identität überein | SMAppService + XPC-Lookup des Kernels | Nein (Neusignierung unterbricht den Kanal) |
| Nutzer hat den Helper genehmigt | Systemeinstellungen → Anmeldeobjekte & Erweiterungen | Nein (Nutzergeste erforderlich) |

Ein explizites Hinzufügen von `setCodeSigningRequirement` wäre eine sinnvolle zusätzliche Verteidigungsebene (nur nützlich, falls die App jemals von SMAppService weg portiert würde, oder falls SIP deaktiviert wäre), ist aber **keine Lücke** in der aktuellen Architektur. Siehe [docs/SECURITY.md](docs/SECURITY.md) für die vollständige Vertrauensanker-Ausarbeitung.

### 🖥 Desktop-Automatisierung (AXorcist)
Steuere jede Mac-App über die Accessibility-API. Klicke Buttons, tippe in Felder, navigiere Menüs, scrolle, ziehe -- alles programmatisch. Angetrieben von [AXorcist](https://github.com/steipete/AXorcist) für zuverlässiges, unscharf abgleichendes Auffinden von Elementen.

### 🤖 18 KI-Anbieter

Der Anbieter-Picker (LLM-Einstellungen, Symbolleisten-Button #7) zeigt 17 Anbieter; Apple Intelligence wird über das separate Gehirn-Symbol (#8) erreicht. Source of Truth: `AgentTools.APIProvider`.

| Anbieter | API-Key | Am besten für |
|---|---|---|
| **Claude** (Anthropic) | Kostenpflichtig | Lange autonome Aufgaben, komplexes Schlussfolgern, Prompt-Caching |
| **OpenAI** | Kostenpflichtig | Allgemeine Zwecke, Tool-Calling, Vision |
| **Google Gemini** | Kostenpflichtig (kostenlose Stufe) | Langer Kontext, Vision, schnell |
| **Grok** (xAI) | Kostenpflichtig | Echtzeitinformationen |
| **Mistral** | Kostenpflichtig | Cloud mit offenen Gewichten, schnelles Tool-Calling |
| **Codestral** (Mistral) | Kostenpflichtig | Code-spezialisiertes Mistral |
| **Mistral Vibe** | Kostenpflichtig | Mistrals Chat-/Agent-Produkt |
| **DeepSeek** | Günstig | Budget-Cloud, starkes Coding, Prompt-Cache-Hit-Reporting |
| **Hugging Face** | Variabel | Open-Source-Modelle, serverlos oder über dedizierte Endpunkte gehostet |
| **OpenRouter** | Kostenpflichtig | 200+ Modelle über einen API-Key — Claude, GPT, Gemini, Llama, Mistral und mehr. Der intelligente Protokoll-Umschalter leitet Claude-Modelle über das Anthropic-Protokoll, alles andere über OpenAI |
| **Z.ai** | Günstig | GLM-5.1 über API — empfohlener Einstiegspunkt |
| **BigModel** (Zhipu) | Günstig | GLM-Familie über Zhipus API |
| **Qwen** (Alibaba) | Günstig | Qwen 2.5 / 3 über Dashscope |
| **Ollama** (Cloud) | Kostenlose Stufe | Führt offene Modelle über Ollamas gehosteten Endpunkt aus |
| **Lokales Ollama** | Kostenlos + Hardware | Selbst gehosteter Ollama-Daemon — vollständig offline, kein Konto |
| **vLLM** | Kostenlos + Hardware | Selbst gehosteter vLLM-Server mit Prefix-Caching |
| **LM Studio** | Kostenlos + Hardware | Selbst gehostet, einfachste GUI für lokale Modelle |
| **Apple Intelligence** | Kostenlos, geräteintern | Triage, Zusammenfassung, Token-Komprimierung (über Gehirn-Symbol, nicht den Anbieter-Picker) |

> 💡 **Selbst gehostete „kostenlose" Anbieter (Lokales Ollama, vLLM, LM Studio) sind nur im Sinne der API-Gebühren kostenlos.** Ein 30B+-Modell mit nutzbarer Geschwindigkeit zu betreiben, erfordert einen M2/M3/M4-Ultra-Mac-Studio (64-128GB Unified Memory) oder eine Linux-Maschine mit 24GB+ VRAM. Falls du diese Hardware noch nicht besitzt, sind die oben genannten Cloud-Wege (Ollama Cloud, Hugging Face, Z.ai, BigModel, DeepSeek) drastisch günstiger, als sie zu kaufen.

## Symbolleisten-Buttons

Der Agent!-Header enthält **15 Buttons** für schnellen Zugriff auf Einstellungen, Monitore und Tools. Jeder Button öffnet beim Klicken ein Popover. Source of Truth: `Agent/Views/HeaderSectionView.swift`.

| # | Symbol | Name | Was er tut |
|---|------|------|--------------|
| 1 | ⚙️ | **Dienste** | Schaltet den Launch Agent / Launch Daemon um, verwaltet den Projektordner, scannt die Befehlsausgabe |
| 2 | 💬 | **Nachrichten-Monitor** | Schaltet die iMessage-Überwachung ein/aus — grün wenn aktiv. Öffnet die Empfängerliste und die Genehmigungs-UI |
| 3 | ✋ | **Accessibility** | Öffnet das Accessibility-Einstellungsblatt (Berechtigungsstatus, axorcist-Diagnosen) |
| 4 | 🖥️ | **MCP-Server** | Fügt MCP-Server (Model Context Protocol) hinzu/entfernt/konfiguriert sie — erweitert Agent! mit `mcp_*`-Tools |
| 5 | </> | **Coding-Einstellungen** | Schaltet Auto-Verifizierung, visuelle Tests, Auto-PR, Auto-Scaffold um. Grün, wenn eine davon aktiv ist |
| 6 | 🔧 | **Tools** | Anbieterspezifische Tool-Umschalter. Aktiviert/deaktiviert einzelne eingebaute und MCP-Tools |
| 7 | 🧠 | **LLM-Einstellungen** | Wähle KI-Anbieter, Modell, API-Key, Basis-URL. Pulsiert, wenn eine Aufgabe läuft |
| 8 | 🧬 | **Apple Intelligence** | Konfiguriert FoundationModels (geräteinterne Apple-KI). Ausgefüllt, wenn verfügbar |
| 9 | 🎛️ | **Agent-Optionen** | Temperatur, maximale Iterationen, visuelles Auto-Screenshot, Plan-Modus-Förderung usw. |
| 10 | 🔄 | **Fallback-Kette** | Konfiguriert die Anbieter-Fallback-Reihenfolge — Agent! versucht es erneut mit dem nächsten Anbieter, wenn einer fehlschlägt |
| 11 | 🔲 | **HUD** | Schaltet die grüne CRT-Scanline-Überlagerung in der LLM-Ausgabe-Ansicht um |
| 12 | 📊 | **LLM-Nutzung** | Token-Nutzung und Kostenverfolgung pro Modell. Grün, wenn eine Nutzung erfasst ist |
| 13 | ↩️ | **Rollback** | Time-Machine-artiger Datei-Backup-Browser. Stellt jede frühere Version jeder von Agent! bearbeiteten Datei wieder her |
| 14 | 🕐 | **Verlauf** | Vergangene Prompts, Fehler und Aufgabenzusammenfassungen für den aktiven Tab. Führt einen früheren Prompt mit einem Klick erneut aus |
| 15 | 🗑️ | **Log löschen** | Löscht das Aktivitätsprotokoll für den aktiven Tab (oder den gesamten Aufgabenverlauf, wenn kein Tab ausgewählt ist). Fragt zuerst nach Bestätigung |

---

### 🎙 Sprachsteuerung — Weckwort „Agent!"
**Weckwort-verankerte Diktierfunktion über `SFSpeechRecognizer`.** Klicke auf das Mikrofon in der Eingabeleiste, um die Weckwort-Sitzung zu starten, und sag dann **„Agent!"**, gefolgt von deiner Aufgabe. Die Transkription erfolgt geräteintern, in Echtzeit, und hört auf „agent" als vollständiges Wort (nicht als Teilstring von „intelligent" oder „management"). Alles, was du nach dem Weckwort sagst, wird zur Aufgabe — nach ~2,5 Sekunden Stille wird sie automatisch ausgeführt. Die Sitzung läuft automatisch weiter: Wenn eine Aufgabe abgeschlossen ist, hört sie wieder zu. Klicke auf das Mikrofon, um zu stoppen.

### 📱 Fernsteuerung über iMessage
Schreib deinem Mac eine Nachricht von deinem iPhone aus:
```
Agent! Welcher Song läuft gerade?
Agent! Prüfe meine E-Mails
Agent! Nächster Song
```
Dein Mac führt die Aufgabe aus und schickt dir das Ergebnis per Nachricht zurück. Nur genehmigte Kontakte können Befehle senden.

### 🌐 Web-Automatisierung
Steuert Safari freihändig -- sucht bei Google, klickt auf Links, füllt Formulare aus, liest Seiten, extrahiert Informationen.

### 📋 Intelligente Planung
Bei komplexen Aufgaben erstellt Agent! einen Schritt-für-Schritt-Plan, arbeitet jeden Schritt ab und hakt sie in Echtzeit ab.

### 🗂 Tabs
Arbeite gleichzeitig an mehreren Aufgaben. Jeder Tab hat seinen eigenen Projektordner und Gesprächsverlauf.

### 📸 Screenshot & Vision
Mache Screenshots oder füge Bilder ein. Vision-fähige KI-Modelle analysieren, was sie sehen -- beschreiben Inhalte, lesen Text, erkennen UI-Probleme.

### 🌐 Safari-Web-Automatisierung (Eingebaut)

Agent! enthält eingebaute Safari-Web-Automatisierung über JavaScript und AppleScript. Suche bei Google, klicke auf Links, fülle Formulare aus, lies Seiteninhalte und führe JavaScript aus -- alles freihändig.

**Aktivierung:** Öffne Safari → Einstellungen → Erweitert → aktiviere „Funktionen für Webentwickler anzeigen". Gehe dann zum Entwickeln-Menü → aktiviere „JavaScript aus Apple-Events erlauben".

### 🎭 Playwright-Web-Automatisierung (Optional)

Vollständige browserübergreifende Automatisierung über [Microsoft Playwright MCP](https://github.com/microsoft/playwright-mcp). Klicke, tippe, mache Screenshots und navigiere auf jeder Website in Chrome, Firefox oder WebKit -- alles von der KI gesteuert.

**Einrichtung (einmalig):**

```bash
# 1. Installiere Node.js (falls noch nicht installiert)
brew install node

# 2. Installiere den Playwright-MCP-Server global
npm install -g @playwright/mcp@latest

# 3. Installiere Browser-Binärdateien (wähle eine oder alle)
npx playwright install chromium          # Chrome (~165MB)
npx playwright install firefox           # Firefox (~97MB)
npx playwright install webkit            # Safari/WebKit (~75MB)
npx playwright install                   # Alle Browser
```

**In Agent! konfigurieren:**

Gehe zu Einstellungen → MCP-Server → Server hinzufügen, füge dieses JSON ein:

```json
{
    "mcpServers": {
        "playwright": {
            "command": "npx",
            "args": ["@playwright/mcp"],
            "transport": "stdio"
        }
    }
}
```

> **Hinweis:** Falls `npx` nicht gefunden wird, verwende den vollständigen Pfad: Führe `which npx` im Terminal aus und ersetze `"npx"` durch das Ergebnis (z. B. `"/opt/homebrew/bin/npx"`).

Schalte ihn ein, und die Playwright-Tools erscheinen automatisch. Die KI kann jetzt Browser direkt steuern.

### Tools — was `list_tools` tatsächlich zurückgibt

Dies sind die kanonischen Tool-Namen, definiert in `AgentTools.Name.*` und über `AgentTools.tools(for:)` jedem LLM-Anbieter zugänglich gemacht. Source of Truth: `~/Documents/GitHub/AgentTools/Sources/AgentTools/AgentTools.swift`. Die Nutzereinstellungs-Umschalter der App können einzelne Tools pro Anbieter ausblenden, aber die Liste unten ist der vollständige Satz, den das LLM jemals zu sehen bekommt.

#### Kern / Erkennung

| Tool | Aktionen / Argumente | Was es tut |
|---|---|---|
| **done** | `summary` | Signalisiert, dass die Aufgabe abgeschlossen ist. Erforderlich am Ende jeder Aufgabe |
| **list_tools** | — | Gibt die aktive Tool-Liste für den aktuellen Anbieter zurück (eingebaut + MCP) |
| **search** | `query` | Websuche über Exa, Tavily oder DuckDuckGo (je nachdem, welcher Key konfiguriert ist) |
| **chat** | `write` / `transform` / `fix` / `about` | Verfasst Prosa, transformiert/korrigiert Text, beschreibt die Fähigkeiten von Agent |
| **memory** | `read` / `write` / `append` / `clear` | Persistente Nutzereinstellungen. „merk dir X" → `append` |
| **plan** | `create` / `update` / `read` / `list` / `delete` | Multi-Plan-CRUD mit Statusverfolgung pro Schritt |
| **goal_state** | `set` / `get` / `mark` / `clear` | Persistentes Ziel + Erfolgskriterien; als erledigt markieren erfordert Nachweise |
| **restore_tool_result** | `tool_use_id` | Stellt den vollständigen Text eines durch Kompaktierung gekürzten Tool-Ergebnisses wieder her |
| **directory** | `get` / `set` / `home` / `documents` / `library` / `none` / `cd` | Projektordner für den aktuellen Tab |
| **fetch** | `url` | Ruft URL ab, entfernt HTML, Obergrenze 8K Zeichen |
| **skill** | `list` / `invoke` / `save` / `delete` | Wiederverwendbare Prompt-Vorlagen |
| **ask_user** | `question` | Nutzerdialog mitten in der Aufgabe (wartet bis zu 5 Min.) |

#### Code / Dateien / Build

| Tool | Aktionen / Argumente | Was es tut |
|---|---|---|
| **file** | `read` / `write` / `edit` / `create` / `apply` / `undo` / `diff_apply` / `list` / `search` / `read_dir` / `mkdir` / `cd` / `if_to_switch` / `extract_function` | Alle Dateioperationen. `edit` = Ersetzung einer einzelnen Zeichenkette. `diff_apply` = bevorzugt für mehrzeilige Code-Bearbeitungen |
| **git** | `status` / `diff` / `log` / `commit` / `diff_patch` / `branch` / `worktree` | Git-Operationen — statt Shell-Git verwenden |
| **xcode** | `build` / `run` / `list_projects` / `select_project` / `add_file` / `remove_file` / `grant_permission` / `analyze` / `snippet` / `code_review` / `get_version` / `bump_version` / `bump_build` | Native Xcode-Integration. Fehler im Aktivitätsprotokoll sind klickbar |
| **agent_script** | `list` / `read` / `create` / `update` / `edit` / `run` / `delete` / `combine` / `restore` / `pull` / `list_backups` | Swift-dylib-Skripte in `~/Documents/AgentScript/agents/` mit vollständigem TCC |

#### Shell / Privilegienstufen

| Tool | Argumente | Was es tut |
|---|---|---|
| **user_shell** | `command` | Shell als aktueller Nutzer über Launch Agent. Primäres Shell-Tool |
| **root_shell** | `command` | Shell als ROOT über Launch Daemon. Nur Admin-Aufgaben — kein sudo |
| **shell** | `command` | In-Process-Shell-Fallback (wenn Launch Agent deaktiviert ist) |
| **batch** | `commands` | Mehrere Shell-Befehle in einem Aufruf (durch Zeilenumbrüche getrennt) |
| **multi** | `description`, `tasks` | Mehrere Tool-Aufrufe in einem Batch |

#### macOS-Automatisierung

| Tool | Aktionen / Argumente | Was es tut |
|---|---|---|
| **accessibility** | `open_app` / `find_element` / `click_element` / `type_into_element` / `scroll_to_element` / `list_windows` / `inspect_element` / `get_properties` / `perform_action` / `set_properties` / `get_focused_element` / `get_children` / `read_focused` / `wait_for_element` / `wait_adaptive` / `highlight_element` / `manage_app` / `show_menu` / `click_menu_item` / `set_window_frame` / `get_window_frame` / `screenshot` / `check_permission` / `request_permission` / `get_audit_log` | Elementbasierte AXorcist-Automatisierung. Jede Aktion nimmt `role`+`title`+`appBundleId` — keine Koordinaten |
| **applescript** | `execute` / `lookup_sdef` / `list` / `run` / `save` / `delete` | NSAppleScript im selben Prozess mit TCC |
| **javascript** | `execute` / `list` / `run` / `save` / `delete` | JXA (JavaScript for Automation) |

#### Web-Automatisierung

| Tool | Aktionen / Argumente | Was es tut |
|---|---|---|
| **safari** | `open` / `find` / `click` / `type` / `execute_js` / `get_url` / `get_title` / `read_content` / `google_search` / `scroll_to` / `select` / `submit` / `navigate` / `list_tabs` / `switch_tab` / `list_windows` / `scan` / `search` | Safari-Automatisierung über JavaScript + AppleScript |
| **selenium** | `start` / `stop` / `navigate` / `find` / `click` / `type` / `execute` / `screenshot` / `wait` | Selenium-WebDriver-Sitzung — verwende `safari` für normale Safari-Nutzung |
| **mcp_playwright_browser_\*** | (siehe Playwright MCP) | Optional. Browserübergreifende Automatisierung über Playwright MCP |

#### Sub-Agenten

| Tool | Argumente | Was es tut |
|---|---|---|
| **spawn_agent** | `name`, `prompt`, `tools`, `model`, `max_iterations` | Erzeugt einen isolierten Sub-Agenten. 3 gleichzeitig (bis zu 6 schreibgeschützt). Optionale Modell-Überschreibung + dateibasierte Ergebnisse |
| **tell_agent** | `to`, `message` | Sendet eine Nachricht an das Postfach eines laufenden Sub-Agenten |

> 💡 **Hinweis:** Die geräteinterne App filtert diese Liste pro Anbieter — schalte einzelne Tools im **Tools**-Popover um (Button #6 in der Symbolleiste oben). Apple Intelligence hat aufgrund seines kleinen Kontextfensters einen eigenen minimalen Standardsatz. MCP-Tools werden zur Laufzeit als `mcp_<server>_<tool>` angehängt und von `list_tools` unter „--- MCP Tools ---" aufgelistet.

## Datenschutz & Sicherheit

- **Deine Daten bleiben auf deinem Mac.** Dateien, Bildschirminhalte und persönliche Daten werden nie hochgeladen.
- **Cloud-KI sieht nur deinen Prompt-Text.** Nutze lokale KI, um zu 100 % offline zu bleiben.
- **Du hast die Kontrolle.** Agent! zeigt alles an, was er tut, und protokolliert jede Aktion.
- **Aufgebaut auf Apples Sicherheitsmodell.** macOS-Berechtigungen schützen dein System.

### Verteidigungsschichten

| Schicht | Was sie tut |
|---|---|
| **Shell-Sicherheitsdienst** | Blockiert katastrophale Befehle strikt (`rm -rf /`, `rm -rf ~`, `dd` auf `/dev/disk`, Fork-Bombs, `--no-preserve-root`), noch bevor der Process überhaupt erstellt wird. Kann vom LLM nicht umgangen werden. |
| **TCC-In-Process-Routing** | Ein 17-Schlüsselwort-Detektor leitet AppleScript-, osascript-, JXA-, screencapture-, accessibility-, Shortcuts- und ScriptingBridge-Befehle so, dass sie im selben Prozess laufen, in dem Agent! die TCC-Berechtigungen besitzt — niemals über den Launch Agent/Daemon (separate Bundle-IDs = kein TCC). |
| **Datei-Backup bei jeder Bearbeitung** | `FileBackupService` erstellt automatisch einen Schnappschuss jeder Datei vor `write_file`, `edit_file` und `diff_apply`. Wiederherstellbar über `file(action:"restore")` oder die Rollback-UI. TTL von 1 Woche. |
| **Agent-Script-Papierkorb** | `delete_agent` kopiert das Skript vor der Entfernung nach `~/Documents/AgentScript/agents/.Trash/`. Wiederherstellbar über `agent_script(action:"restore")`. |
| **Normalisierung des Arbeitsverzeichnisses** | Jeder Shell-Ausführungspfad (`executeTCC`, `UserService`, `HelperService`) normalisiert das Arbeitsverzeichnis — wird versehentlich ein Dateipfad als cwd übergeben, wird er auf das übergeordnete Verzeichnis gekürzt, statt mit „Not a directory" abzustürzen. |
| **Aufgaben-Drain vor Start** | Der Start einer neuen Aufgabe wartet auf die vollständige Beendigung der vorherigen Aufgabe, bevor er beginnt — verhindert, dass verwaiste Wiederholungsschleifen die Protokollausgabe zwischen Anbietern vermischen. |
| **Fallback-Kette** | Wenn das primäre LLM ausfällt (429, Timeout, Netzwerk), wechselt Agent! nach 2 Fehlschlägen automatisch zum nächsten Anbieter in der vom Nutzer konfigurierten Kette. |
| **Umsetzbare Fehler** | Jeder Tool-Fehler enthält einen `Recovery:`-Hinweis, der dem LLM genau sagt, was als Nächstes zu versuchen ist — keine Sackgassen-Fehlermeldungen, die Runden verschwenden. |
| **Ungültigmachung des Lese-Caches** | Der Datei-Lese-Cache wird sowohl bei erfolgreichen als auch bei fehlgeschlagenen Bearbeitungen ungültig gemacht, sodass das LLM beim nächsten Lesen immer aktuellen Inhalt erhält. |
| **Basisname-Suche** | Wenn `read_file` oder `edit_file` einen falschen Pfad erhält, durchsucht Agent! nahegelegene Verzeichnisse nach Dateien mit demselben Namen und gibt die korrekten Pfade inline zurück — das LLM korrigiert sich in einer Runde selbst. |
| **Tool-Ausführungssperre** | Das LLM kann keine Tool-Ergebnisse erfinden. Alle Tool-Aufrufe laufen durch das `dispatchTool()` der App → tatsächliche Ausführung (XPC, Shell, In-Process) → echte Ausgabe, zurückgegeben als `tool_result`. Das LLM sieht und fasst nur Ausgaben zusammen, die tatsächlich stattgefunden haben. Schlägt ein Tool fehl, wird der echte Fehler zurückgegeben — das LLM kann keinen Erfolg behaupten, ohne dass ein passendes Ausführungsereignis vorliegt. |
| **action_not_performed** | Zweistufige Verteidigung gegen falsche Handlungsbehauptungen: **(1) Prompt** — der System-Prompt weist das LLM an, „Aktion nicht ausgeführt" zu sagen, wenn kein Tool aufgerufen wurde. **(2) App** — wenn das LLM Text zurückgibt, der behauptet „ich habe gesucht/geöffnet/geklickt", aber in dieser Runde keine Tool-Aufrufe getätigt hat, wird eine Korrektur eingefügt, die es zwingt, das echte Tool zu nutzen. |

---

## Tastaturkürzel

Source of Truth: das `.onSubmit` des TextField in `Agent/Views/InputSectionView.swift` für `Return`, und der inline `NSEvent.addLocalMonitorForEvents`-Block in `Agent/Views/ContentView.swift` für alles andere.

| Kürzel | Aktion |
|---|---|
| `Return` | Führt die aktuelle Aufgabe aus (TextField-Submit — kein Modifikator nötig) |
| `⌘ .` / `Escape` | Bricht die laufende Aufgabe ab |
| `⌘ B` | Schaltet die LLM-Ausgabe-Überlagerung um (anzeigen/ausblenden) |
| `⌘ D` | Schaltet beide LLM-Chevrons im aktuellen Tab um (ausklappen/einklappen) |
| `⌘ T` | Neuer Tab |
| `⌘ W` | Schließt den aktuellen Tab (oder beendet, wenn keine Tabs offen sind) |
| `⌘ 1`–`⌘ 9` | Wechselt den Tab. `⌘1` ist der Haupt-Tab; `⌘2`–`⌘9` sind Skript-Tabs |
| `⌘ Shift ←` / `⌘ Shift →` | Vorheriger / nächster Tab |
| `⌘ F` | Schaltet die Suchleiste des Aktivitätsprotokolls um |
| `⌘ L` | Löscht das Protokoll für den aktiven Tab |
| `⌘ V` | Fügt ein Bild aus der Zwischenablage ein |
| `↑` / `↓` | Prompt-Verlauf (im Eingabefeld) |
| `⌘ Shift M` | Schaltet den Nachrichten-Monitor um |
| `⌘ Shift P` | Öffnet die Einstellungen (dort befindet sich der System-Prompt-Editor) |
| `⌘ Shift K` | Alles löschen (vollständiger Reset) |
| `⌘ Shift L` | Löscht nur das LLM-Ausgabe-Panel |
| `⌘ Shift H` | Löscht den Prompt-Verlauf |
| `⌘ Shift J` | Löscht den Aufgabenverlauf |
| `⌘ Shift U` | Löscht die Token-Zähler |

## Slash-Befehle

Tippe diese ins Eingabefeld und drücke Enter — sie werden lokal ausgeführt, ohne an ein LLM zu gehen. Source of Truth: `AgentViewModel+RunStop.swift`.

| Befehl | Aktion |
|---|---|
| `/clear` oder `/clear log` | Löscht das Aktivitätsprotokoll für den aktuellen Tab |
| `/clear all` | Löscht alles (Protokoll, LLM-Ausgabe, Prompt-Verlauf, Aufgabenverlauf, Tokens) |
| `/clear llm` | Löscht nur das LLM-Ausgabe-Panel |
| `/clear history` | Löscht den Prompt-Verlauf |
| `/clear tasks` | Löscht den Aufgabenverlauf |
| `/clear tokens` | Setzt die Token-Zähler zurück (Aufgabe + Sitzung) |
| `/memory` oder `/memory show` | Gibt den aktuellen Inhalt der Memory-Datei im Aktivitätsprotokoll aus |
| `/memory clear` | Löscht das Memory |
| `/memory edit` | Öffnet `~/Documents/AgentScript/memory.md` im System-Standardeditor |
| `/memory <Text>` | Fügt `<Text>` dem Memory hinzu (alles nach `/memory` wird zur neuen Zeile) |

---

## FAQ

**Muss ich programmieren können?** Nein. Tippe einfach in einfachem Englisch, was du willst.

**Ist es sicher?** Ja. Standard-macOS-Automatisierung, vollständige Aktivitätsprotokollierung, du genehmigst die Berechtigungen.

**Was kostet es?** Die Agent!-App selbst ist kostenlos (MIT-Lizenz). Cloud-KI-Anbieter berechnen die API-Nutzung — die günstigsten Optionen für ernsthafte Arbeit sind GLM-5/5.1 über Z.ai, BigModel oder Hugging Face (Cent-Beträge pro Million Tokens), oder DeepSeek für preiswertes Coding. Selbst gehostete lokale Modelle (Ollama, vLLM, LM Studio) haben keine API-Gebühren, sind aber nur sinnvoll, wenn du bereits die Hardware besitzt, um sie zu betreiben — siehe den Hardware-Hinweis unten.

**Welchen Mac brauche ich?** macOS 26.4.1. Apple Silicon erforderlich. Für Cloud-Anbieter funktioniert jeder moderne Mac gut. Für selbst gehostete lokale Modelle (Ollama, vLLM, LM Studio): Ein 7B-Modell passt in 16GB Unified Memory, ein 13B-Modell in 24GB, ein 30B-Modell braucht 64GB+ (M2/M3/M4-Ultra-Mac-Studio-Territorium). Apple Intelligence (der geräteinterne Vermittler für Triage / Token-Komprimierung) benötigt einen Apple-Silicon-Mac mit aktivierter Apple Intelligence in den Systemeinstellungen.

**Wie unterscheidet sich das von Siri?** Siri beantwortet Fragen. Agent! *führt Aktionen aus* -- steuert Apps, verwaltet Dateien, baut Code, automatisiert Arbeitsabläufe.

---

## Dokumentation

- [Technische Architektur](docs/TECHNICAL.md) -- Tools, Scripting, Entwicklerdetails
- [Vergleiche](docs/COMPARISON.md) -- vs. Claude Code, Cursor, Cline, OpenClaw
- [Sicherheitsmodell](docs/SECURITY.md) -- XPC-Architektur, Privilegientrennung
- [FAQ](docs/FAQ.md) -- Häufige Fragen

---

## Eingebaute Xcode-Tools

Agent! umfasst native Xcode-Integration, die ohne jegliche MCP-Server-Einrichtung funktioniert. Diese eingebauten Tools sind oft schneller und zuverlässiger als die MCP-Alternative, da sie direkt in der App laufen.

| Tool | Was es tut |
|---|---|
| **xcode build** | Baut das aktuelle Xcode-Projekt, erfasst Fehler und Warnungen. Fehler im Aktivitätsprotokoll sind **klickbar** und öffnen sich direkt in Xcode. |
| **xcode run** | Baut und startet die App |
| **xcode list_projects** | Findet offene Xcode-Workspaces und -Projekte |
| **xcode select_project** | Wechselt das aktive Projekt |
| **xcode grant_permission** | Gewährt Dateizugriff auf den Xcode-Projektordner |
| **xcode get_version** | Liest die aktuelle Marketing-Version und Build-Nummer aus dem Xcode-Projekt |
| **xcode bump_version** | Erhöht die Marketing-Version (Major, Minor oder Patch), aktualisiert die Build-Nummer, baut zur Verifikation und committet automatisch |
| **xcode bump_build** | Erhöht nur die Build-Nummer |

Sag einfach *„erhöhe die Version"*, und Agent! liest die aktuelle Version, fragt nach Major/Minor/Patch, aktualisiert Info.plist und die Projekteinstellungen, baut zur Verifikation und committet die Änderung. Keine manuelle plist-Bearbeitung, keine verpassten Build-Nummern.

Die KI nutzt diese automatisch, wenn du sie bittest zu bauen, Fehler zu beheben oder mit Xcode-Projekten zu arbeiten. Keine Konfiguration nötig -- öffne einfach dein Projekt in Xcode.

> 🚀 **iOS/iPadOS-Unterstützung:** Demnächst! Native Unterstützung zum Bauen, Ausführen und Testen von iOS- und iPadOS-Apps direkt aus Agent! ist in Entwicklung.

> **Tipp:** Für die meisten Coding-Workflows reichen die eingebauten Tools völlig aus. Der unten stehende MCP-Xcode-Server fügt Extras wie SwiftUI-Preview-Rendering und Dokumentationssuche hinzu.


---

<img width="1349" height="1438" alt="Screenshot 2026-04-02 at 12 00 03 PM" src="https://github.com/user-attachments/assets/b0d9346e-f807-4089-bab3-29c7058868d8" />

## Zwei Wege, mit Agent! zu sprechen — Sprache und iMessage

Beide Funktionen verwenden dasselbe Weckwort: **„Agent!"** (Groß-/Kleinschreibung egal — `Agent!`, `agent!`, `AGENT!`, sogar nur `Agent ` oder `agent ` funktionieren).

### 🎤 Sprache (Diktier-Weckwort)

Klicke auf das Mikrofon in der Eingabeleiste und starte die Weckwort-Sitzung, dann sprich. Agent! transkribiert in Echtzeit mit `SFSpeechRecognizer` und hört auf das Wort „agent" als vollständiges Wort (nicht als Teilstring von „intelligent" oder „management"). Alles, was du nach „agent" sagst, wird zur Aufgabe. Nach ~2,5 Sekunden Stille wird die Aufgabe automatisch ausgeführt.

Beispiele:
- *„Agent, welcher Song läuft gerade?"*
- *„Agent, mach einen Screenshot von Safari"*
- *„Agent, baue das Xcode-Projekt"*

Die Weckwort-Sitzung läuft automatisch weiter — nachdem eine Aufgabe abgeschlossen ist, hört sie wieder zu. Klicke erneut auf das Mikrofon, um zu stoppen.

### 📱 iMessage (Fernsteuerung)

Schreib deinem Mac von deinem iPhone aus eine Nachricht. Agent! fragt alle 5 Sekunden `~/Library/Messages/chat.db` nach neuen Nachrichten ab und reagiert auf alles, was mit **`Agent!`** beginnt (Groß-/Kleinschreibung egal, Ausrufezeichen optional).

Beispiele:
```
Agent! Welcher Song läuft gerade?
agent! prüfe meine E-Mails
AGENT! nächster Song
Agent  öffne Safari
```

Agent! sendet sofort eine „Ich kümmere mich darum..."-Bestätigung, führt die Aufgabe in einem dedizierten Messages-Tab mit der LLM-Konfiguration deines Haupt-Tabs aus und schickt dir dann das Ergebnis per Nachricht zurück.

**Einrichtung (einmalig):**

1. **Gewähre Vollzugriff auf die Festplatte** — Systemeinstellungen → Datenschutz & Sicherheit → Vollzugriff auf die Festplatte → aktiviere Agent! (erforderlich, um `chat.db` direkt über SQLite zu lesen)
2. **Öffne den Nachrichten-Monitor** — Symbolleisten-Button #2 (Sprechblasen-Symbol, wird grün, wenn aktiv)
3. **Genehmige einen Absender** — sobald eine Nachricht von einem neuen Kontakt eintrifft, erscheint dieser Kontakt in der Empfängerliste. Schalte ihn ein, um ihn zu genehmigen.

Nur genehmigte Absender können Aufgaben ausführen. Nicht genehmigte Nachrichten werden protokolliert, aber ignoriert. Deine Antwort wird über AppleScript an dasselbe Handle zurückgesendet, das den Befehl gesendet hat, begrenzt auf 4000 Zeichen.

Bei ausgehenden Antworten wird ein führendes „Agent!" entfernt, damit der empfangende Mac nicht seine eigene Befehlsschleife auslöst.

---

Agent! unterstützt [MCP](https://modelcontextprotocol.io)-Server für erweiterte Fähigkeiten. Konfiguriere sie unter Einstellungen → MCP-Server.

### Xcode-MCP-Server

Verbinde Agent! direkt mit Xcode für projektbewusste Operationen:

```json
{
  "mcpServers" : {
    "xcode" : {
      "command" : "xcrun",
      "args" : [
        "mcpbridge"
      ],
      "transport" : "stdio"
    }
  }
}
```

**Das Xcode-MCP bietet:**
- Projektbewusste Dateioperationen (Lesen/Schreiben/Bearbeiten/Löschen)
- Build- und Test-Integration
- SwiftUI-Preview-Rendering
- Ausführung von Code-Snippets
- Suche in der Apple-Entwicklerdokumentation
- Echtzeit-Problemverfolgung


---

## Lizenz

MIT - frei und Open Source.

---

<div align="center">

### **Agent! für macOS 26.4.1 - Agentische KI für deinen Mac-Desktop**
> Hinweis: Claude bezeichnet das in Agent! integrierte Anthropic-KI-Modell für die LLM-Funktionalität. Es ist kein menschlicher Mitwirkender an Agent!
</div>

---

## Agent! vs. Claude Code — Architektureller Vergleich

Agent! ist eine zu 100 % originale, reine Swift-macOS-Anwendung. Sie ist kein Port, Fork oder Derivat eines anderen Projekts.

| | Claude Code | Agent! |
|---|---|---|
| **Sprache** | TypeScript/JavaScript | Reines Swift 6.2 |
| **UI-Framework** | Ink (Terminal-React) | SwiftUI (nativ macOS) |
| **Plattform** | CLI — Linux, macOS, Windows | Nur natives macOS 26.4.1 |
| **Laufzeitumgebung** | Node.js/Bun | Nativ kompilierte Binärdatei |
| **Architektur** | Terminal-REPL mit Streaming | Desktop-App mit XPC-Daemons |
| **Accessibility** | Keine (CLI) | Vollständiges macOS-AX über AXorcist (25 Top-Level-Aktionen, 30+ AX-Subtypen über `perform_action`) |
| **AppleScript** | Keins | Vollständiges NSAppleScript + JXA im selben Prozess mit TCC |
| **Xcode-Integration** | Über Bash (`xcodebuild`) | Nativ (build/run/analyze/snippet/add_file/bump_version/code_review — 13 Aktionen) |
| **Apple Intelligence** | Keine | Geräteinterne FoundationModels — übernimmt Begrüßung/Small-Talk-Triage, Aufgabenzusammenfassungen, Fehlererklärungen und Tier-1-Token-Komprimierung. UI-Automatisierung wird vom Haupt-LLM über das `accessibility`-Tool gehandhabt, nicht von Apple AI |
| **ScriptingBridge** | Keine | Vollständiges SDEF + 51 Event-Bridges (Finder, Mail, Music, Safari, Calendar usw.) |
| **Vision** | Bildeingabe über API | Bildeingabe über API |
| **Auto-Screenshots** | Keine (kein UI) | Optionale Auto-Verifizierung nach UI-Aktionen (standardmäßig AUS — siehe `visionAutoScreenshotEnabled`) |
| **iMessage** | Keins | Fernagent über Messages (Vollzugriff auf die Festplatte für `chat.db` erforderlich) |
| **Sprache** | Keine | Weckwort-verankertes Diktat über SFSpeechRecognizer |
| **CRT-Effekt** | Keiner | Optionale SwiftUI-Canvas-Scanline-Überlagerung (Umschaltung über HUD-Button) |
| **Privilegienmodell** | Nutzer-Sandbox | XPC Launch Agent (Nutzer) + Launch Daemon (Root) |
| **Sub-Agenten** | Task-Tool (öffentlich dokumentiert; Implementierungsdetails von Anthropic nicht angegeben) | Bis zu 3 gleichzeitige (6 schreibgeschützte) isolierte Agenten mit Postfach-Messaging und Modell-Überschreibung pro Agent |
| **MCP** | Node.js stdio/SSE | Swift-AgentMCP-Paket |
| **Skripte** | Keine | Swift-dylib-Kompilierung zur Laufzeit, per dlopen im selben Prozess mit vollständigem TCC geladen |
| **Prompt-Caching** | Anthropics ephemeres `cache_control` | Anthropics ephemeres `cache_control` + automatische Präfix-Cache-Hit-Verfolgung für OpenAI/Z.ai/Grok/Mistral/Gemini/Qwen/DeepSeek; Ollamas `keep_alive: 30m` |
| **Kontext-Kompaktierung** | Cloud-Claude (kostenpflichtige Tokens; Konversation wird erneut an Anthropic gesendet) | Gestuft: Stufe 1 = geräteinterne Apple-Intelligence-Zusammenfassung (kostenlos, privat, keine API-Tokens). Stufe 2 = aggressives Kürzen, wenn Apple AI nicht verfügbar ist. Schwellenwert skaliert mit dem Kontextfenster des Modells (~55 %, 2K–400K), Zusammenfassungen werden gespeichert, 3-Fehlschlag-Schutzschaltung, vollständige Tool-Ergebnisse werden vor dem Trunkieren auf die Festplatte ausgelagert |

## Agent! vs. Cursor — Kurzvergleich

Cursor ist ein exzellenter KI-Code-Editor. Agent! spielt ein anderes Spiel: Er ist ein Agent für deinen **gesamten Mac**, nicht nur deine Codebasis.

| | Cursor | Agent! |
|---|---|---|
| **Was es ist** | KI-Code-Editor (VS-Code-Fork, Electron) | Native SwiftUI-macOS-Agent-App |
| **Umfang** | Deine Codebasis | Dein gesamter Mac — Code, Apps, Dateien, System |
| **Preisgestaltung** | Abo | Kostenlos und Open Source (MIT) — bring deinen eigenen API-Key mit oder betreibe es lokal |
| **Lokale Modelle** | Cloud-first | Ollama, vLLM, LM Studio, geräteinterne Apple Intelligence |
| **Mac-App-Automatisierung** | Keine | Accessibility-API, AppleScript/JXA, ScriptingBridge (51 App-Bridges) |
| **Root-Level-Admin-Aufgaben** | Keine | Privilegierter Launch Daemon über XPC (einmal genehmigt) |
| **Sprach-/iMessage-Steuerung** | Keine | Weckwort-Diktat + Fernagent über Messages |
| **Xcode-Integration** | Terminal-`xcodebuild` | Native Build-/Run-/Analyze-/Code-Review-Tools |
| **Telemetrie** | Cloud-Konto erforderlich | Keine — deine Keys, deine Maschine, deine Daten |

Wenn du den ganzen Tag in einem Repo lebst, ist Cursor großartig. Wenn du einen Agenten willst, der auch dein Xcode-Projekt baut, Safari steuert, dir Ergebnisse schickt und Software als Root installiert -- das ist Agent!.

## Mitwirken

Lust, an Agent! zu basteln? Siehe [CONTRIBUTING.md](./CONTRIBUTING.md) — du kannst in etwa 5 Minuten aus dem Quellcode bauen, nur mit den Xcode Command Line Tools (`./build.sh`), kein Apple-Developer-Konto erforderlich. Schau dir die [good first issues](https://github.com/macOS26/Agent/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) für abgegrenzte Einstiegsaufgaben an.

---


> ⚠️ **Rechtlicher Hinweis & Zuschreibung**
>
> ### Markenhinweis
>
> „🦾 Agent! for macOS26" ist ein unabhängiges Softwareprojekt und **nicht** mit Apple Inc. verbunden, von Apple genehmigt, gesponsert oder anderweitig assoziiert. „Apple", „Mac", „Mac mini", „MacBook", „macOS" und verwandte Marken sind Marken von Apple Inc., eingetragen in den USA und anderen Ländern. Alle anderen hier erwähnten Marken, Dienstleistungsmarken und Handelsnamen sind Eigentum ihrer jeweiligen Inhaber und werden nur zu Identifikationszwecken verwendet.
>
> „🦾 Agent!" und das 🦾-Agent!-Logo sind Marken von Heisenburg. Die Nutzung dieser Marken erfordert vorherige schriftliche Genehmigung. Die untenstehende MIT-Lizenz gewährt Rechte nur am Quellcode — sie gewährt **keine** Markenrechte.
>
> ### Quellcode-Lizenz (MIT)
>
> Der Quellcode von „🦾 Agent! for macOS26" ist Open Source und unter der **MIT-Lizenz** lizenziert. Es steht dir frei, Kopien des Quellcodes zu nutzen, zu kopieren, zu modifizieren, zusammenzuführen, zu veröffentlichen, zu verteilen, unterzulizenzieren und/oder zu verkaufen, vorbehaltlich der Bedingungen in der [LICENSE](./LICENSE)-Datei (Beibehaltung des Copyright-Hinweises und des MIT-Genehmigungshinweises in allen Kopien oder wesentlichen Teilen der Software).
>
> ### Kompilierte Binärdateien & Releases
>
> Kompilierte Binärdateien, Installationsprogramme, code-signierte Builds und Release-Artefakte, die über die GitHub Releases dieses Projekts, [agent.macOS26.app](https://agent.macOS26.app), oder jeden anderen offiziellen Kanal verteilt werden, sind das urheberrechtlich geschützte Werk von Heisenburg und **nicht** von der MIT-Lizenz abgedeckt, die den Quellcode regelt. Alle Rechte an den offiziellen Binärdateien — einschließlich des Namens „🦾 Agent!", des Logos, der Code-Signing-Identität und der Developer ID — sind vorbehalten.
>
> Copyright © 2000, 2023–2026 Heisenburg, Alle Rechte vorbehalten.
>
> Du bist herzlich eingeladen, deine eigenen Binärdateien aus dem Quellcode unter der MIT-Lizenz zu bauen, solange du nicht den Namen „🦾 Agent!", das Logo oder das Branding zur Identifikation deines Produkts verwendest.
>
> ### Gewährleistungsausschluss
>
> Diese Software wird **„WIE BESEHEN"** bereitgestellt, ohne Gewährleistung jeglicher Art, weder ausdrücklich noch stillschweigend, einschließlich, aber nicht beschränkt auf die Gewährleistungen der Marktgängigkeit, der Eignung für einen bestimmten Zweck und der Nichtverletzung von Rechten Dritter. In keinem Fall haften der Autor oder der Urheberrechtsinhaber für Ansprüche, Schäden oder sonstige Haftung, sei es aus einer vertraglichen Handlung, unerlaubter Handlung oder anderweitig, die sich aus der Software oder der Nutzung oder anderen Vorgängen mit der Software ergeben.
>
> ---
>
> Danke für dein Interesse an 🦾 Agent! — einer Anwendung, entwickelt für Mac-mini-, MacBook- und Mac-Desktop-Computer, die macOS 26.4 oder neuer auf originaler Mac-Hardware und -Software ausführen.
>
> Mit freundlichen Grüßen,
> **Heisenburg**
> Forward Deployed Engineer, 🦾 Agent! für macOS 26.4.1
> https://agent.macOS26.app
> https://github.com/macos26/agent
