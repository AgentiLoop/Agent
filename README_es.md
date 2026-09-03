# 🦾 AgentiLoop Agent!

### **IA agéntica para tu escritorio Mac**

[![Latest Release](https://img.shields.io/github/v/release/AgentiLoop/Agent?label=Download&color=blue&style=for-the-badge)](https://github.com/AgentiLoop/Agent/releases/latest)
[![GitHub Stars](https://img.shields.io/github/stars/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Stars&color=gold)](https://github.com/AgentiLoop/Agent/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Forks&color=white)](https://github.com/AgentiLoop/Agent/fork)
[![macOS 26.4+](https://img.shields.io/badge/macOS-26.4.1-green?style=for-the-badge)](https://github.com/apple)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange?style=for-the-badge)](https://www.swift.org)
<a href="https://www.paypal.com/ncp/payment/9C6RY2UAE5M3S"><img src="https://img.shields.io/badge/Donation-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Tip Jar" /></a>

## Traducciones del README

- [English](README.md)
- [Español](README_es.md)
- [Français](README_fr.md)
- [Deutsch](README_de.md)
- [中文 (简体)](README_zh.md)

## Ajedrez dentro de Agent
<img width="1176" height="724" alt="Screenshot 2026-08-23 at 7 34 10 PM" src="https://github.com/user-attachments/assets/d3b2f1e5-1dab-44f7-95f6-008424ee794c" />

## ¿Qué es Agent!?

**Una app. Cualquier IA. Control total de tu Mac.**

Agent! es una app 100 % nativa en Swift 6.2 / SwiftUI que conecta **18 proveedores de LLM** — Claude, GPT, Gemini, Grok, Mistral, DeepSeek, Qwen, Z.ai, BigModel, Hugging Face, OpenRouter, Ollama (nube y local), vLLM, LM Studio, Codestral, Mistral Vibe y **Apple Intelligence** en el dispositivo — a un bucle de tareas autónomo que realmente *hace cosas*: lee tu código, corrige el bug, compila el proyecto de Xcode, hace commit del diff, controla cualquier app de Mac mediante la API de Accesibilidad, ejecuta comandos de shell como tú o como root, te envía los resultados por iMessage y responde a un *«Agent!»* hablado.

Sin NPM, sin Electron, sin suscripción, sin telemetría. Trae tu propia clave de API, ejecútalo totalmente en local o gratis con Apple Intelligence. Cada paquete Swift del que depende fue escrito por el mismo autor. Consulta la [Historia](#historia) más abajo.

## Novedades 🚀

**v1.1.x — La versión Hardened Harness** · [Releases →](https://github.com/AgentiLoop/Agent/releases/latest)

- **Compactación de contexto, reconstruida.** Umbral = ventana del modelo − salida reservada − margen, guiado por `input_tokens` reales. Un resumen LLM de 9 secciones del lado del proveedor sustituye a los resúmenes de 4K en el dispositivo; el objetivo abierto, la lista del plan y los archivos editados se vuelven a adjuntar tras cada compactación. Los resultados de herramientas demasiado grandes se vuelcan a disco al emitirse y se recuperan con `restore_tool_result`. Los desbordamientos 413 pasan por una compactación forzada con un reintento más corto; los excesos de `max_tokens` se recuperan escalando y luego continuando.
- **Puerta read-before-edit.** `edit_file` / `apply_diff` / `diff_apply` rechazan tocar un archivo que el LLM no haya leído en esta tarea, o que haya cambiado en disco desde la última lectura (SHA-256). El rechazo lee el archivo automáticamente para que la siguiente llamada sea la edición. Los cambios externos en archivos se muestran en cada turno como fragmentos de diff.
- **Ventanas de contexto reales para modelos locales.** LM Studio, Ollama y vLLM informan de su longitud de contexto real por modelo — se acabó la suposición fija de 32K.
- **Turnos más rápidos.** Las herramientas de solo lectura arrancan mientras la respuesta de Claude aún se transmite; concurrencia de shell consciente de la entrada; reintento exponencial con jitter y `Retry-After` en 429/529; errores en mitad del flujo SSE visibles en todos los proveedores.
- **Defensa en profundidad.** `ShellSafetyService` ahora se aplica en el lado del daemon (AgentHelper + AgentUser) además del cliente; las builds de release rechazan clientes XPC sin equipo; ambos listeners XPC exigen firma de código del mismo equipo derivada de la propia firma de la app.
- **Registro de actividad.** Sin truncado a 50K ni recorte a 500K al reiniciar — los registros grandes se renderizan fuera del hilo principal con una superposición «Processing tab data…»; diseño opcional «Activity Log Below HUD».
- **Menú de la app:** Buscar actualizaciones… (releases de GitHub), Sitio web, GitHub. Flujo de CI Build & Test en cada PR; **273 pruebas superadas**.
- Además: `goal_state` con criterios verificados con evidencia, revisión crítica opcional del diff antes de terminar, `rewind_task` por tarea, pensamiento extendido para Claude, paso de `reasoning_effort`, subagentes con modelo propio por agente (3 concurrentes, 6 de solo lectura), errores de herramienta tipados con pistas de recuperación, hooks de eventos.

## Inicio rápido (Descarga)

1. **Descarga** [Agent!](https://github.com/AgentiLoop/Agent/releases/latest) y arrástralo a Aplicaciones
2. **Abre Agent!** — lo configura todo automáticamente
3. **Elige tu IA** — Ajustes → elige un proveedor → introduce la clave de API

## Inicio rápido (Compilar desde el código fuente)

```bash
git clone https://github.com/AgentiLoop/agent.git
cd Agent
```

**Opción A — Xcode (cuenta de Apple Developer):** abre `Agent.xcodeproj`, configura tu Development Team, compila y ejecuta el target `Agent`, aprueba el helper cuando se te pida.

**Opción B — sin cuenta de desarrollador (solo Xcode Command Line Tools):**
```bash
./build.sh              # Debug
./build.sh Release      # Release
open "build/DerivedData/Build/Products/Debug/Agent!.app"
```

> ⚠️ Las builds de la Opción B están firmadas ad-hoc. Los helpers Launch Agent/Daemon no se registrarán (SMAppService necesita un Team ID), pero el bucle LLM, todas las herramientas, Accesibilidad, AppleScript, shell y MCP siguen funcionando.

> 💡 **Configuración barata:** **GLM-5.1** vía **Z.ai** (registro más rápido, modelo por defecto) cuesta céntimos por millón de tokens. ¿En local? Solo **GLM-4.7-Turbo** (32B) cabe en hardware de consumo (Apple Silicon de 64–128 GB vía Ollama).

### Solución de problemas (Compilar desde el código fuente)

- **`xcode-select` apunta a Command Line Tools** → `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- **`BUILD FAILED` extraño tras hacer pull** → DerivedData obsoleto: `./build.sh clean && ./build.sh`
- **Los helpers nunca se registran** → esperado en la Opción B; usa la Opción A para los helpers
- **Errores de deployment target / SDK** → Agent! apunta a macOS 26; actualiza macOS y Xcode
- **El argumento de configuración distingue mayúsculas** → `./build.sh` (Debug) o `./build.sh Release`

## ¿Qué puede hacer?

> *«Compila el proyecto de Xcode y corrige los errores»* · *«Reproduce mi lista Workout en Música»* · *«Haz una foto con Photo Booth»* · *«Envía un iMessage a mamá diciendo que llego a las 6»* · *«Abre Safari y busca vuelos a Tokio»* · *«Refactoriza esta clase en archivos más pequeños»* · *«¿Qué eventos tengo hoy en el calendario?»*

Solo escribe lo que quieres. Agent! averigua cómo y lo hace realidad.

---

## Funciones principales

- **🧠 Bucle de tareas autoverificado** — razona, ejecuta, observa resultados, se corrige. Una tarea no puede declararse terminada hasta que los criterios de `goal_state` se marcan con evidencia; un crítico opcional revisa antes el diff.
- **🛠 Programación agéntica** — lee bases de código, edita con diffs de sustitución de cadenas, compila proyectos de Xcode de forma nativa (errores clicables), gestiona git, indexa repos en un mapa JSONL portable. Cada edición se guarda — rollback con un clic o `rewind_task` de toda la tarea.
- **🖥 Automatización del escritorio** — controla cualquier app de Mac mediante la API de Accesibilidad ([AXorcist](https://github.com/steipete/AXorcist)), basada en elementos con reintento difuso automático. Además NSAppleScript, JXA y 51 puentes ScriptingBridge, todo en proceso con TCC.
- **📜 AgentScript** — dylibs Swift compiladas en tiempo de ejecución y cargadas con `dlopen` en proceso con TCC completo. Los scripts borrados van a `.Trash` y son recuperables.
- **🛡 Ejecución privilegiada** — shell como tú mediante un Launch Agent, o como root mediante un Launch Daemon que apruebas exactamente una vez (SMAppService + XPC). Consulta [docs/SECURITY.md](docs/SECURITY.md) para saber por qué SMAppService ya impone la identidad de firma.
- **🎙 Voz** — di **«Agent!»** seguido de tu tarea; `SFSpeechRecognizer` en el dispositivo, se ejecuta tras ~2,5 s de silencio, en bucle.
- **📱 Control remoto por iMessage** — escribe `Agent! next song` desde tu iPhone; solo remitentes aprobados. Necesita Acceso total al disco para `chat.db`.
- **🌐 Web** — automatización de Safari integrada (JavaScript + AppleScript); Selenium y [Playwright MCP](https://github.com/microsoft/playwright-mcp) opcionales para varios navegadores.
- **🤝 Subagentes** — hasta 3 concurrentes (6 de solo lectura) agentes aislados con mensajería por buzón y modelo propio por agente.
- **🧩 MCP** — añade cualquier servidor MCP en Ajustes → Servidores MCP; las herramientas aparecen como `mcp_<server>_<tool>`. Xcode MCP: `{"mcpServers":{"xcode":{"command":"xcrun","args":["mcpbridge"],"transport":"stdio"}}}`.
- **🗂 Pestañas, historial, memoria, planes, skills** — cada pestaña tiene su propia carpeta de proyecto y registro; memoria de usuario persistente; listas multi-plan en cada prompt.
- **🔄 Cadena de respaldo** — cambio automático al siguiente proveedor configurado ante 429/timeout/fallo de red.

## 🤖 18 proveedores de IA

| Proveedor | Coste | Ideal para |
|---|---|---|
| **Claude** | De pago | Tareas autónomas largas, pensamiento extendido, caché de prompts |
| **OpenAI** | De pago | Uso general, llamadas a herramientas, visión, `reasoning_effort` |
| **Google Gemini** | De pago (nivel gratuito) | Contexto largo, visión |
| **Grok** (xAI) | De pago | Información en tiempo real |
| **Mistral** / **Codestral** / **Mistral Vibe** | De pago | Nube de pesos abiertos, código, producto agente |
| **DeepSeek** | Barato | Programación económica, informe de aciertos de caché |
| **Hugging Face** | Varía | Modelos abiertos, serverless o endpoints dedicados |
| **OpenRouter** | De pago | 200+ modelos, una clave; Claude enrutado por protocolo Anthropic |
| **Z.ai** / **BigModel** | Barato | GLM-5.1 — punto de partida recomendado |
| **Qwen** (Alibaba) | Barato | Qwen 2.5 / 3 vía Dashscope |
| **Ollama** (nube) | Nivel gratuito | Modelos abiertos alojados |
| **Ollama local** / **vLLM** / **LM Studio** | Gratis + hardware | Totalmente offline; ventana de contexto real por modelo detectada |
| **Apple Intelligence** | Gratis, en el dispositivo | Triaje, resúmenes, compresión de tokens (icono del cerebro, no el selector de proveedor) |

> 💡 Los proveedores autoalojados solo son gratis en cuanto a tarifas de API — un modelo de 30B+ usable necesita un Mac Studio M2/M3/M4 Ultra (64–128 GB). Sin ese hardware, las vías de nube baratas de arriba salen muchísimo más económicas.

## Herramientas

Los nombres canónicos vienen de `AgentTools.Name.*` (fuente: el paquete [AgentTools](https://github.com/AgentiLoop/AgentTools)). Los interruptores por proveedor pueden ocultar herramientas individuales.

| Grupo | Herramientas |
|---|---|
| **Core** | `done` · `list_tools` · `search` · `web_search` · `fetch` · `chat` · `memory` · `plan` · `goal_state` · `restore_tool_result` · `directory` · `skill` · `ask_user` · `index` |
| **Código / build** | `file` (read/write/edit/diff_apply/undo/list/search/mkdir/…) · `git` · `xcode` (build/run/analyze/snippet/code_review/add_file/bump_version/…) · `agent_script` |
| **Shell** | `user_shell` (Launch Agent) · `root_shell` (Launch Daemon) · `shell` (respaldo en proceso) · `batch` · `multi` |
| **Automatización macOS** | `accessibility` (25 acciones basadas en elementos) · `applescript` (con `lookup_sdef`) · `javascript` (JXA) |
| **Web** | `safari` · `selenium` · `mcp_playwright_browser_*` (opcional) |
| **Subagentes** | `spawn_agent` · `tell_agent` |

Referencia completa por acción: [docs/TECHNICAL.md](docs/TECHNICAL.md).

## AgentScript — Scripts Swift con TCC completo

Los AgentScripts son archivos Swift normales en `~/Documents/AgentScript/agents/Sources/Scripts/`. Agent! compila cada uno a una `.dylib` con SwiftPM (`Package.swift` lista todos los scripts más los 51 puentes ScriptingBridge) y luego lo carga con `dlopen` con los permisos TCC propios de Agent! — Accesibilidad, Automatización, Calendario, Contactos, Mail, Fotos, etc. El LLM los gestiona con `agent_script` (`create` / `edit` / `run` / `delete` / `restore` / `pull`); la carpeta incluye ~35 ejemplos (`Hello`, `TodayEvents`, `NowPlaying`, `CheckMail`, `CreateDmg`, `ArchiveXcode`, …).

**Punto de entrada** — sin código de nivel superior, sin `exit()`; `stdout` se devuelve al LLM y el valor de retorno es el código de salida:

```swift
import Foundation
import CalendarBridge   // cualquier `import XBridge` se conecta solo — no hay que tocar Package.swift

@_cdecl("script_main")
public func scriptMain() -> Int32 {
    print("Hello from AgentScript! 👋")
    return 0
}
```

**Variables de entorno — cómo se DEFINEN.** El LLM nunca toca el entorno directamente. Llama a la herramienta y el `ScriptService` de Agent! exporta las variables al proceso del script (`env["AGENT_PROJECT_FOLDER"] = cwd`, `env["AGENT_SCRIPT_ARGS"] = arguments` en `ScriptService+Execution.swift`; `setenv(...)` en la variante en proceso). Las mismas dos variables se exportan a cada comando `user_shell` / `root_shell` / `shell`.

```text
Llamada del LLM a la herramienta                       Lo que Agent! exporta al script
─────────────────────────────────────────────────────  ─────────────────────────────────────────────
agent_script(action:"run", name:"TodayEvents")         AGENT_PROJECT_FOLDER=/Users/tu/Documents/GitHub/Agent
                                                       (AGENT_SCRIPT_ARGS NO se define)

agent_script(action:"run", name:"TodayEvents",         AGENT_PROJECT_FOLDER=/Users/tu/Documents/GitHub/Agent
             arguments:"days=3,location=false,json=true")   AGENT_SCRIPT_ARGS="days=3,location=false,json=true"
```

| Variable | Cuándo se define | Significado |
|---|---|---|
| `AGENT_PROJECT_FOLDER` | Siempre | La carpeta de proyecto de la pestaña activa (o `$HOME` si no hay). El cwd del runner también se fija ahí. |
| `AGENT_SCRIPT_ARGS` | Solo cuando el LLM pasa `arguments:"…"` | La cadena que pasó el LLM, tal cual. Los ejemplos usan la convención `key=value,key=value`. |

**Variables de entorno — cómo se LEEN.** Dentro del script, ambas vienen de `ProcessInfo.processInfo.environment`. Este es exactamente el patrón de parseo de `Hello.swift` / `TodayEvents.swift`:

```swift
import Foundation

@_cdecl("script_main")
public func scriptMain() -> Int32 {
    let env = ProcessInfo.processInfo.environment

    // 1. Carpeta de proyecto — siempre presente; por si acaso, recurre al cwd
    let folder = env["AGENT_PROJECT_FOLDER"] ?? FileManager.default.currentDirectoryPath

    // 2. Argumentos — ausentes salvo que el LLM haya pasado `arguments:"…"`
    let argsString = env["AGENT_SCRIPT_ARGS"] ?? ""

    // 3. Valores por defecto y luego parseo de "key=value,key=value"
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

    print("Carpeta de proyecto: \(folder)")
    print("days=\(daysAhead) location=\(showLocation) json=\(outputJSON)")
    return 0
}
```

Las dos variables son independientes — nunca extraigas la carpeta de proyecto de `AGENT_SCRIPT_ARGS`. Equivalente en Bash dentro de `user_shell`: `ls "$AGENT_PROJECT_FOLDER/Sources"` (el cwd ya está ahí, no hace falta `cd`).

**Convenciones reales de `AGENT_SCRIPT_ARGS` en los scripts incluidos** (`~/Documents/AgentScript/agents/Sources/Scripts/`):

| Script | `arguments:` que pasa el LLM | Estilo |
|---|---|---|
| `TodayEvents` | `days=3,location=false,json=true` | `key=value,…` |
| `CheckMail` | `unreadOnly=true,inboxCount=true,json=true` | `key=value,…` |
| `ListReminders` | `completed=false,limit=5` | `key=value,…` |
| `QuitApps` | `excluded=Xcode,Agent,Terminal` | `key=value` con lista |
| `NowPlaying` | `json=true,artwork=true` | `key=value,…` |
| `ArchiveXcode` | `/path/to/Project.xcodeproj MyScheme 469UCUB275` | posicional, separado por espacios (scheme/teamID se autodetectan si se omiten) |
| `CreateDmg` | `--app /path/to/App.app --output /path/out.dmg --name "My App" --compress` | estilo flags, separado por espacios, respeta comillas |

**Entrada / salida JSON — un mecanismo SEPARADO de las variables de entorno.** Las variables de entorno las exporta Agent! al proceso; los archivos JSON son simples archivos en disco que el *propio script* lee y escribe con `FileManager` / `JSONSerialization`. Agent! no los crea, ni los pasa, ni los parsea. Dos patrones reales de los scripts incluidos:

*1. Entrada solo por JSON (`SendMessage`)* — sin argumentos de entorno; el script exige `SendMessage_input.json` y devuelve `1` si falta:

```json
// ~/Documents/AgentScript/json/SendMessage_input.json   (escrito por el LLM con file(action:"write") antes de ejecutar)
{ "recipient": "Mamá", "message": "Llego a las 6", "imagePath": "~/Pictures/Photos Library.photoslibrary/originals/A/IMG_0001.jpeg" }

// ~/Documents/AgentScript/json/SendMessage_output.json  (escrito por el script)
{ "success": true, "timestamp": "2026-09-03T21:14:02Z", "recipient": "Mamá", "message": "Llego a las 6" }
// en caso de fallo: { "success": false, "timestamp": "…", "error": "Missing required field: recipient" }
```

```swift
// SendMessage.swift — así lo lee el script
let inputPath  = "\(NSHomeDirectory())/Documents/AgentScript/json/SendMessage_input.json"
guard let inputData = FileManager.default.contents(atPath: inputPath) else {
    writeOutput(outputPath, success: false, error: "Input file not found: \(inputPath)"); return 1
}
guard let json = try? JSONSerialization.jsonObject(with: inputData) as? [String: Any],
      let recipientHandle = json["recipient"] as? String else { /* … */ return 1 }
let message   = json["message"]   as? String
let imagePath = json["imagePath"] as? String
```

*2. Argumentos de entorno para opciones, JSON para salida estructurada (`TodayEvents`, `NowPlaying`, `CheckMail`, `ListReminders`)* — las opciones vienen de `AGENT_SCRIPT_ARGS` (o del opcional `<Name>_input.json`); con `json=true` el script escribe `<Name>_output.json` además de la salida legible por stdout que vuelve al LLM:

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
// TodayEvents.swift — así lo escribe el script
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

Los scripts borrados van a `~/Documents/AgentScript/agents/.Trash/` (`agent_script(action:"restore")`); `action:"pull"` descarga la versión upstream del repo [AgentScripts](https://github.com/AgentiLoop/AgentScripts).

## Privacidad y seguridad

Tus archivos, el contenido de la pantalla y los datos personales nunca salen de tu Mac — los proveedores en la nube solo ven el texto del prompt; los locales lo mantienen todo offline. Cada acción queda registrada.

| Capa | Qué hace |
|---|---|
| **Shell Safety Service** | Bloquea de raíz `rm -rf /`, `rm -rf ~`, `rm -rf` con glob desnudo, `--no-preserve-root` — aplicado en el cliente **y** en el daemon. El LLM no puede saltárselo. |
| **Confianza de clientes XPC** | Ambos listeners exigen firma de código del mismo equipo derivada de la propia firma de la app; las builds de release rechazan clientes sin equipo. |
| **Puerta read-before-edit** | Se rechazan ediciones de archivos no leídos o modificados externamente (SHA-256), con lectura automática al rechazar. |
| **Copias de seguridad + rewind** | Cada edición se guarda (TTL de 1 semana); UI de Rollback, `file(action:"undo")` o `rewind_task` por tarea. |
| **Enrutado TCC en proceso** | Los comandos AppleScript/JXA/screencapture/accesibilidad se ejecutan en proceso, donde Agent! tiene los permisos TCC, nunca a través de los daemons. |
| **Control de ejecución de herramientas** | El LLM no puede inventar resultados — cada llamada pasa por `dispatchTool()` y devuelve salida real. Las afirmaciones «hice clic/busqué…» sin herramienta reciben una corrección inyectada. |
| **Errores tipados + guardias** | Cada resultado fallido lleva una pista de recuperación; los guardias de disco rayado y de bloqueo avisan y luego paran; las puertas de finalización limitan los rechazos a 3 por tarea. |
| **Rastro de auditoría en consola** | Se registra cada llamada a herramienta y cada comando del helper. |

## Atajos de teclado y comandos slash

| Atajo | Acción |
|---|---|
| `Return` | Ejecutar tarea · `⌘ .` / `Esc` cancelar |
| `⌘ T` / `⌘ W` / `⌘ 1–9` / `⌘ ⇧ ←→` | Nueva / cerrar / cambiar / anterior-siguiente pestaña |
| `⌘ B` / `⌘ D` | Alternar superposición de salida LLM / chevrones |
| `⌘ F` / `⌘ L` / `⌘ V` | Buscar en el registro / limpiar registro / pegar imagen |
| `↑` / `↓` | Historial de prompts |
| `⌘ ⇧ M` / `⌘ ⇧ P` | Monitor de Mensajes / Ajustes |
| `⌘ ⇧ K` `L` `H` `J` `U` | Limpiar todo / panel LLM / historial de prompts / historial de tareas / contadores de tokens |

Los comandos slash se ejecutan en local: `/clear [log|all|llm|history|tasks|tokens]`, `/memory [show|clear|edit|<texto>]`.

## FAQ

**¿Necesito saber programar?** No — español llano (o tu idioma nativo).
**¿Cuánto cuesta?** La app es gratis (MIT). Pagas a tu proveedor; GLM-5.1 vía Z.ai/BigModel o DeepSeek son los más baratos para trabajo serio. Los modelos locales son gratis si tienes el hardware.
**¿Qué Mac necesito?** Apple Silicon, macOS 26.4.1+. Cualquier Mac moderno para proveedores en la nube; 64 GB+ para modelos locales de 30B.
**¿En qué se diferencia de Siri?** Siri responde. Agent! *actúa* — apps, archivos, código, sistema.

Más: [docs/FAQ.md](docs/FAQ.md) · [Arquitectura técnica](docs/TECHNICAL.md) · [Comparativas](docs/COMPARISON.md) (vs Claude Code, Cursor, Cline, OpenClaw) · [Modelo de seguridad](docs/SECURITY.md)

## Historia

Agent! es el resultado de tres años construyendo apps de IA agéntica — ANIE, Game Changer, BattleScript, XCF MCP Server and Client, D1F y unos ocho paquetes Swift originales. La pieza que faltaba era un bucle autónomo inteligente; una vez conseguido, lo mejor de esos proyectos se unió en Agent!. Ha escrito videojuegos ([Boss-Man](https://github.com/AgentiLoop/bossman)), creado apps, escrito poesía en Pages mediante AppleScript, generado imágenes de disco y las ha adjuntado a releases de GitHub. Donde Claude Code depende de ~65 paquetes NPM de terceros, Agent! es 100 % nativo, usa muy poca RAM e incluye de serie automatización de Xcode, análisis con Swift Syntax 6.2, Accesibilidad, AppleScript, AgentScript/ScriptingBridge, automatización de Safari y soporte MCP.

## Contribuir

Consulta [CONTRIBUTING.md](./CONTRIBUTING.md) — compila desde el código fuente en ~5 minutos con `./build.sh`, sin cuenta de desarrollador. Los pull requests ejecutan el flujo de CI Build & Test. Revisa los [good first issues](https://github.com/AgentiLoop/Agent/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22).

## Licencia

MIT — gratis y de código abierto.

---

> ⚠️ **Aviso Legal y Atribución**
>
> ### Aviso de Marca Registrada
>
> "🦾 Agent! for macOS26" es un proyecto de software independiente y **no** está afiliado con, respaldado por, patrocinado por, ni asociado de ninguna otra forma con Apple Inc. "Apple," "Mac," "Mac mini," "MacBook," "macOS," y las marcas relacionadas son marcas registradas de Apple Inc., registradas en EE. UU. y otros países. Todas las demás marcas registradas, marcas de servicio y nombres comerciales mencionados aquí son propiedad de sus respectivos dueños y se usan solo con fines de identificación.
>
> "🦾 Agent!" y el logo de 🦾 Agent! son marcas registradas de AgentiLoop Agent. El uso de estas marcas requiere permiso previo por escrito. La licencia MIT a continuación otorga derechos solo sobre el código fuente — **no** otorga ningún derecho de marca registrada.
>
> ### Licencia del Código Fuente (MIT)
>
> El código fuente de "🦾 Agent! for macOS26" es de código abierto y está licenciado bajo la **Licencia MIT**. Eres libre de usar, copiar, modificar, fusionar, publicar, distribuir, sublicenciar y/o vender copias del código fuente, sujeto a las condiciones del archivo [LICENSE](./LICENSE) (conservar el aviso de copyright y el aviso de permiso MIT en todas las copias o partes sustanciales del software).
>
> ### Binarios Compilados y Releases
>
> Los binarios compilados, instaladores, compilaciones firmadas y artefactos de release distribuidos a través de los GitHub Releases de este proyecto, [AgentiLoop.ai](https://AgentiLoop.ai), o cualquier otro canal oficial, son obra con derechos de autor de AgentiLoop Agent y **no** están cubiertos por la licencia MIT que rige el código fuente. Todos los derechos sobre los binarios oficiales — incluyendo el nombre "🦾 Agent!", el logo, la identidad de firma de código, y el Developer ID — están reservados.
>
> Copyright © 2000, 2023–2026 AgentiLoop Agent, Todos los Derechos Reservados.
>
> Eres bienvenido a compilar tus propios binarios desde el código fuente bajo la licencia MIT, siempre que no uses el nombre "🦾 Agent!", el logo, ni la marca para identificar tu producto.
>
> ### Descargo de Garantía
>
> Este software se proporciona **"TAL CUAL,"** sin garantía de ningún tipo, expresa o implícita, incluyendo pero no limitado a las garantías de comerciabilidad, idoneidad para un propósito particular, y no infracción. En ningún caso el autor o el titular de los derechos de autor serán responsables de ningún reclamo, daño u otra responsabilidad, ya sea en una acción de contrato, agravio, o de otro tipo, que surja de, fuera de, o en conexión con el software o el uso u otros manejos del software.
>
> ---
>
> Gracias por tu interés en 🦾 Agent! — una aplicación creada para computadoras Mac mini, MacBook y Mac Studio que ejecutan macOS 26.4 o posterior en hardware y software Mac genuino.
>
> - Website: https://AgentiLoop.ai
> - Github : https://github.com/AgentiLoop/agent
