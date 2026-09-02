# 🦾 AgentiLoop Agent! diseñado para macOS 26.4.1 o posterior

## **IA Agéntica para tu Mac de Escritorio**

[![Latest Release](https://img.shields.io/github/v/release/AgentiLoop/Agent?label=Download&color=blue&style=for-the-badge)](https://github.com/AgentiLoop/Agent/releases/latest)
[![GitHub Stars](https://img.shields.io/github/stars/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Stars&color=gold)](https://github.com/AgentiLoop/Agent/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Forks&color=white)](https://github.com/AgentiLoop/Agent/fork)
[![macOS 26.4+](https://img.shields.io/badge/macOS-26.4.1-green?style=for-the-badge)](https://github.com/apple)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange?style=for-the-badge)](https://www.swift.org)
<a href="https://www.paypal.com/ncp/payment/9C6RY2UAE5M3S"><img src="https://img.shields.io/badge/Donation-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Tip Jar" /></a>

## Ajedrez dentro de Agent
<img width="1176" height="724" alt="Screenshot 2026-08-23 at 7 34 10 PM" src="https://github.com/user-attachments/assets/d3b2f1e5-1dab-44f7-95f6-008424ee794c" />

## Historia y la tecnología detrás de Agent!
Agent! no surgió de la noche a la mañana. Es el resultado de tres años construyendo apps de IA agéntica, apoyándose en aproximadamente una docena de proyectos desarrollados en el camino. Algunos de ellos se publicaron bajo ANIE, Game Changer, BattleScript, XCF MCP Server and Client, D1F, y unos ocho paquetes originales de Swift. La pieza que faltaba era lograr un bucle temporal autónomo e inteligente. Una vez logrado eso, incorporé lo mejor de los últimos tres años. El resultado es Agent! para macOS 26.4.1 o posterior.

El objetivo original era construir un "asesino de Cursor". Lo que surgió es algo más interesante: una IA agéntica con piernas de verdad. Agent! solo está limitado por tu imaginación. Puede escribir código, incluidos videojuegos como Boss-Man, https://github.com/AgentiLoop/bossman, crear apps, escribir poesía vía AppleScript dentro de Pages, generar imágenes de disco y adjuntarlas a releases de GitHub. Puede automatizar la mayoría de las tareas en tu Mac. Pídele lo que quieras en inglés sencillo o en tu idioma nativo y, tras una configuración inicial y las aprobaciones del usuario, hará todo lo posible para cumplir tu deseo. Agent! es incansable y busca complacer.

Toda la propiedad intelectual de Agent! es original y de código abierto. Cada dependencia de paquete Swift y la app en sí fueron escritas originalmente por la misma persona. Este es un ecosistema genuinamente diferente. La mayoría de las apps de IA agéntica, como Claude Code, dependen de 65 paquetes NPM de terceros. Agent! es 100% nativo, requiere muy poca RAM y pesa 35.5 sin comprimir. Ese tamaño incluye automatización de Xcode, un paquete Swift Syntax 6.2 para diagnosticar apps nativas, Accessibility, AppleScript, AgentScript/ScriptingBridge, automatización de Safari, soporte de servidor MCP y más. Todo listo desde el primer momento.

## Novedades 🚀

**v1.0.92 (186) — El lanzamiento de autonomía autoverificable** · [Notas completas de la versión →](https://github.com/AgentiLoop/Agent/releases/tag/v1.0.92.186)

Agent! ahora demuestra su trabajo. Una tarea no puede declararse terminada hasta que sus criterios de éxito se verifiquen con evidencia (`goal_state`), un crítico opcional revisa el diff antes de completarla, y cada archivo tocado puede revertirse de un solo golpe (`rewind_task`). Pensamiento extendido para Claude, `reasoning_effort` para proveedores compatibles con OpenAI, y un contexto estable para el caché de prompts que se compacta a la ventana real de cada modelo — de forma recuperable, con todos los resultados de herramientas volcados a disco. Los errores de herramientas tipados llevan pistas de recuperación, los subagentes ejecutan sus propios modelos (hasta 6 investigadores de solo lectura), los hooks de eventos están completamente conectados, y 57 pruebas exitosas lo mantienen honesto.

**Una app. Cualquier IA. Control total sobre tu Mac.**

Agent! conecta **18 proveedores de LLM** — Claude, GPT, Gemini, Grok, Mistral, DeepSeek, Qwen, Z.ai, BigModel, Hugging Face, **OpenRouter**, Ollama (en la nube y local), vLLM, LM Studio, Codestral, Mistral Vibe, y **Apple Intelligence** en el dispositivo — en una app nativa de macOS que no solo habla de hacer cosas. Las hace.

Míralo leer tu código, arreglar el error, compilar el proyecto de Xcode y confirmar el cambio mientras te preparas un café. Dile que abra Safari y te envíe un mensaje con el precio de los vuelos a Tokio. Di *"¡Agent!"* desde el otro lado de la habitación y haz que ejecute tu suite de pruebas por voz. Envía un mensaje a tu Mac desde iMessage y obtén una respuesta pulida antes de llegar a tu auto.

Edita archivos con diffs quirúrgicos de reemplazo de cadenas — cada cambio se puede deshacer con un clic desde una reversión al estilo Time Machine. Controla cualquier app de Mac mediante la API de Accessibility — sin necesidad de AppleScript. Recuerda tus preferencias entre sesiones. Genera subagentes paralelos para trabajo que se ramifica. Indexa bases de código completas en un mapa de repositorio JSONL portátil que cualquier LLM puede consumir. Ejecuta comandos de shell como tú, o como root mediante un Launch Daemon que apruebas una sola vez.

Usa tu propia clave de API. Ejecútalo totalmente en local con Ollama, vLLM o LM Studio. O úsalo gratis, para siempre, con Apple Intelligence. Sin suscripción. Sin telemetría. Sin dependencia de proveedor. Tus claves, tu máquina, tus datos.

Descárgalo. Di lo que necesitas. Míralo suceder.

## Inicio Rápido (Descarga)

1. **Descarga** [Agent!](https://github.com/AgentiLoop/Agent/releases/latest) y arrástralo a Aplicaciones
2. **Abre Agent!** -- configura todo automáticamente
3. **Elige tu IA** -- Ajustes → elige un proveedor → introduce la clave de API

## Inicio Rápido (Compilar desde el código fuente)

1. **Clona el repositorio:**
   ```bash
   git clone https://github.com/AgentiLoop/agent.git
   cd Agent
   ```

#### Opción A: Compilar con Xcode (cuenta de Apple Developer)
2. **Abre `Agent.xcodeproj` en Xcode.**
3. **Compila y ejecuta el target `Agent`.**
4. **Aprueba la herramienta auxiliar:** Cuando se te solicite, autoriza al daemon privilegiado para permitir la ejecución de comandos a nivel root.

#### Opción B: Compilar sin una cuenta de Apple Developer
2. **Ejecuta el script de compilación** (solo requiere Xcode Command Line Tools):
   ```bash
   ./build.sh              # Compilación Debug
   ./build.sh Release      # Compilación Release
   ```
3. La app se genera en `build/DerivedData/Build/Products/Debug/Agent!.app`
4. **Ejecútala:** `open "build/DerivedData/Build/Products/Debug/Agent!.app"`

> ⚠️ Sin una cuenta de desarrollador la app queda firmada ad-hoc. Los ayudantes de Launch Agent/Daemon no se registrarán (SMAppService necesita un Team ID), pero el bucle del LLM, todas las herramientas, accessibility, AppleScript, shell y MCP funcionan igualmente.

#### Luego:
5. **Configura tu proveedor de IA:** Ve a Ajustes e introduce tu clave de API o selecciona un proveedor local como Ollama.

> 💡 **Configuración económica de GLM:** **GLM-5.1** funciona en los cuatro proveedores económicos — **Ollama**, **Hugging Face**, **Z.ai**, **BigModel** — por centavos por millón de tokens. ¿Nuevo aquí? Empieza con **Z.ai** (registro más rápido, GLM-5.1 es el predeterminado, nada que aprovisionar). ¿Ejecutando en local? Solo **GLM-4.7-Turbo** (32B) cabe en hardware de consumo (Mac M2/M3/M4, 64-128GB, vía Ollama) — GLM-5 y GLM-5.1 son demasiado grandes (~1.6TB), úsalos a través de los proveedores en la nube mencionados arriba.


## ¿Qué puede hacer?

> *"Reproduce mi playlist Workout en Music"*
> *"Compila el proyecto de Xcode y arregla cualquier error"*
> *"Toma una foto con Photo Booth"*
> *"Envía un iMessage a Mamá diciendo que llegaré a las 6"*
> *"Abre Safari y busca vuelos a Tokio"*
> *"Refactoriza esta clase en archivos más pequeños"*
> *"¿Qué eventos tengo hoy en el calendario?"*

Solo escribe lo que quieres. Agent! descubre cómo y lo hace realidad.

---

## Características Clave

### 🧠 Framework de IA Agéntica
Bucle de tareas autónomo integrado que razona, ejecuta y se autocorrige. Agent! no solo ejecuta código; observa los resultados, depura errores e itera hasta que la tarea esté completa. El estado de meta con criterios de éxito verificados con evidencia significa que una tarea no puede declararse terminada hasta que lo demuestre.

### 🛠 Programación Agéntica
Entorno de programación completo integrado. Lee bases de código, edita archivos con precisión, ejecuta comandos de shell, compila proyectos de Xcode, gestiona git, y activa automáticamente el modo de codificación para enfocar la IA en herramientas de desarrollo. Reemplaza a Claude Code, Cursor y Cline -- sin terminal, sin plugins de IDE, sin cuota mensual. Incluye **copias de seguridad al estilo Time Machine** para cada cambio de archivo, permitiéndote revertir cualquier edición al instante.

### 🔍 Descubrimiento Dinámico de Herramientas
Detecta y usa automáticamente las herramientas disponibles (Xcode, Playwright, Shell, etc.) según tu instrucción. No requiere configuración manual para las herramientas principales.

### 🛡 Ejecución Privilegiada
Ejecuta de forma segura comandos a nivel root mediante un Launch Daemon dedicado de macOS. El usuario aprueba el daemon una vez, y luego el agente puede ejecutar comandos de forma autónoma vía XPC.

#### Por qué no hay un `setCodeSigningRequirement` manual en el listener XPC

Los usuarios a veces preguntan por qué el listener XPC de `AgentHelper` acepta conexiones sin una comprobación manual de `connection.setCodeSigningRequirement(...)`. La respuesta corta: **SMAppService ya impone la identidad de firma una capa por debajo de tu código**, así que la comprobación sería redundante.

Esa recomendación es un resabio de la era pre-SMAppService, **SMJobBless**, donde launchd no validaba la identidad por ti y el servidor XPC tenía que establecer su propia cadena de requisito designado. SMAppService cambió ese contrato:

- El plist embebido en el paquete de la app más el registro con verificación de firma **es** el requisito de firma de código.
- Los nombres de servicio Mach (`Agent.app.redacted.helper`, `Agent.app.redacted.user`) están asociados al paquete firmado que los registró — ningún otro paquete puede reclamarlos.
- Cualquier discrepancia de firma (manipulación, refirmado, Team ID diferente, sustitución de paquete) **rompe el canal XPC en la capa de launchd** — `listener(_:shouldAcceptNewConnection:)` nunca llega a invocarse.

**Prueba empírica:** El propio Agent! intentó refirmar sus propios daemons durante un experimento y perdió inmediatamente la capacidad de conectarse. `NSXPCConnection` a ambos servicios Mach falló en la capa de launchd antes de que un solo byte llegara al delegado del listener — exactamente el comportamiento que una llamada manual a `setCodeSigningRequirement` impondría, salvo que SMAppService lo hace en la ruta de búsqueda XPC del kernel, donde no se puede eludir desde el espacio de usuario.

| Aplicación | Mecanismo | ¿Se puede eludir desde el espacio de usuario? |
|---|---|---|
| El ayudante debe estar en el paquete de app firmado | Gatekeeper + registro de SMAppService | No |
| El ayudante debe coincidir con el Team ID de la app (469UCUB275) | Firma de código + SMAppService | No |
| Nombre de servicio Mach vinculado al paquete firmado | espacio de nombres launchd / XPC | No |
| El hash del binario auxiliar coincide con la identidad registrada | SMAppService + búsqueda XPC del kernel | No (refirmar rompe el canal) |
| El usuario aprobó el ayudante | Ajustes del Sistema → Elementos de Inicio y Extensiones | No (se requiere gesto del usuario) |

Añadir `setCodeSigningRequirement` explícitamente sería una defensa adicional razonable (útil solo si la app se portara alguna vez fuera de SMAppService, o si SIP estuviera desactivado), pero **no es una brecha** en la arquitectura actual. Consulta [docs/SECURITY.md](docs/SECURITY.md) para la explicación completa del ancla de confianza.

### 🖥 Automatización de Escritorio (AXorcist)
Controla cualquier app de Mac mediante la API de Accessibility. Haz clic en botones, escribe en campos, navega menús, desplázate, arrastra -- todo de forma programática. Impulsado por [AXorcist](https://github.com/steipete/AXorcist) para una búsqueda de elementos fiable y con coincidencia difusa.

### 🤖 18 Proveedores de IA

El selector de proveedores (Ajustes de LLM, botón de la barra de herramientas #7) muestra 17 proveedores; Apple Intelligence se accede mediante el ícono de cerebro separado (#8). Fuente de verdad: `AgentTools.APIProvider`.

| Proveedor | Clave de API | Mejor para |
|---|---|---|
| **Claude** (Anthropic) | De pago | Tareas autónomas largas, razonamiento complejo, caché de prompts |
| **OpenAI** | De pago | Uso general, llamadas a herramientas, visión |
| **Google Gemini** | De pago (nivel gratuito) | Contexto largo, visión, rapidez |
| **Grok** (xAI) | De pago | Información en tiempo real |
| **Mistral** | De pago | Nube de peso abierto, llamadas a herramientas rápidas |
| **Codestral** (Mistral) | De pago | Mistral especializado en código |
| **Mistral Vibe** | De pago | Producto de chat/agente de Mistral |
| **DeepSeek** | Económico | Nube económica, programación sólida, reporte de aciertos de caché de prompts |
| **Hugging Face** | Variable | Modelos de código abierto alojados sin servidor o en endpoints dedicados |
| **OpenRouter** | De pago | Más de 200 modelos con una sola clave de API — Claude, GPT, Gemini, Llama, Mistral y más. El alternador de protocolo inteligente enruta los modelos Claude vía el protocolo de Anthropic, y el resto vía OpenAI |
| **Z.ai** | Económico | GLM-5.1 vía API — punto de partida recomendado |
| **BigModel** (Zhipu) | Económico | Familia GLM vía la API de Zhipu |
| **Qwen** (Alibaba) | Económico | Qwen 2.5 / 3 vía Dashscope |
| **Ollama** (nube) | Nivel gratuito | Ejecuta modelos abiertos vía el endpoint alojado de Ollama |
| **Ollama Local** | Gratis + hardware | Daemon de Ollama autoalojado — totalmente offline, sin cuenta |
| **vLLM** | Gratis + hardware | Servidor vLLM autoalojado con caché de prefijos |
| **LM Studio** | Gratis + hardware | Autoalojado, la GUI más sencilla para modelos locales |
| **Apple Intelligence** | Gratis, en el dispositivo | Selección, resumen, compresión de tokens (vía ícono de cerebro, no el selector de proveedores) |

> 💡 **Los proveedores "gratuitos" autoalojados (Ollama Local, vLLM, LM Studio) solo son gratuitos en el sentido de tarifas de API.** Ejecutar un modelo de 30B+ con velocidad utilizable requiere un Mac Studio M2/M3/M4 Ultra (64-128GB de memoria unificada) o una máquina Linux con 24GB+ de VRAM. Si aún no tienes ese hardware, las rutas en la nube mencionadas arriba (Ollama Cloud, Hugging Face, Z.ai, BigModel, DeepSeek) son drásticamente más económicas que comprarlo.

## Botones de la Barra de Herramientas

El encabezado de Agent! contiene **15 botones** para acceso rápido a ajustes, monitores y herramientas. Cada botón abre un popover al hacer clic. Fuente de verdad: `Agent/Views/HeaderSectionView.swift`.

| # | Ícono | Nombre | Qué hace |
|---|------|------|--------------|
| 1 | ⚙️ | **Servicios** | Activa/desactiva el Launch Agent / Launch Daemon, gestiona la carpeta del proyecto, escanea la salida de comandos |
| 2 | 💬 | **Monitor de Mensajes** | Activa/desactiva el monitoreo de iMessage — verde cuando está activo. Abre la lista de destinatarios y la interfaz de aprobación |
| 3 | ✋ | **Accessibility** | Abre la hoja de ajustes de Accessibility (estado del permiso, diagnósticos de axorcist) |
| 4 | 🖥️ | **Servidores MCP** | Añade/elimina/configura servidores MCP (Model Context Protocol) — extiende Agent! con herramientas `mcp_*` |
| 5 | </> | **Preferencias de Codificación** | Activa/desactiva auto-verificación, pruebas visuales, auto-PR, auto-scaffold. Verde cuando alguna está activada |
| 6 | 🔧 | **Herramientas** | Alternadores de herramientas por proveedor. Activa/desactiva herramientas integradas e individuales de MCP |
| 7 | 🧠 | **Ajustes de LLM** | Elige proveedor de IA, modelo, clave de API, URL base. Pulsa cuando hay una tarea en ejecución |
| 8 | 🧬 | **Apple Intelligence** | Configura FoundationModels (Apple AI en el dispositivo). Relleno cuando está disponible |
| 9 | 🎛️ | **Opciones del Agente** | Temperatura, iteraciones máximas, auto-captura de pantalla por visión, fomento del modo de planificación, etc. |
| 10 | 🔄 | **Cadena de Respaldo** | Configura el orden de respaldo de proveedores — Agent! reintenta con el siguiente proveedor cuando uno falla |
| 11 | 🔲 | **HUD** | Activa/desactiva la superposición de líneas de escaneo estilo CRT verde en la vista de salida del LLM |
| 12 | 📊 | **Uso de LLM** | Seguimiento de uso de tokens y costo por modelo. Verde cuando hay uso registrado |
| 13 | ↩️ | **Reversión** | Explorador de copias de seguridad de archivos estilo Time Machine. Restaura cualquier versión anterior de cualquier archivo que Agent! haya editado |
| 14 | 🕐 | **Historial** | Instrucciones, errores y resúmenes de tareas pasadas para la pestaña activa. Vuelve a ejecutar una instrucción anterior con un clic |
| 15 | 🗑️ | **Borrar Registro** | Elimina el registro de actividad de la pestaña activa (o todo el historial de tareas cuando no hay pestaña seleccionada). Pide confirmación primero |

---

### 🎙 Control por Voz — Palabra clave "Agent!"
**Dictado anclado a palabra clave vía `SFSpeechRecognizer`.** Haz clic en el micrófono de la barra de entrada para iniciar la sesión de palabra clave, luego di **"¡Agent!"** seguido de tu tarea. La transcripción es en el dispositivo, se ejecuta en tiempo real, y escucha "agent" como palabra completa (no como subcadena de "intelligent" o "management"). Todo lo que digas después de la palabra clave se convierte en la tarea — tras ~2.5 segundos de silencio, se ejecuta automáticamente. La sesión se repite automáticamente: cuando una tarea termina, vuelve a escuchar. Haz clic en el micrófono para detenerla.

### 📱 Control Remoto vía iMessage
Envía un mensaje a tu Mac desde tu iPhone:
```
Agent! ¿Qué canción está sonando?
Agent! Revisa mi correo
Agent! Siguiente canción
```
Tu Mac ejecuta la tarea y te responde con el resultado por mensaje. Solo los contactos aprobados pueden enviar comandos.

### 🌐 Automatización Web
Controla Safari sin usar las manos -- busca en Google, hace clic en enlaces, rellena formularios, lee páginas, extrae información.

### 📋 Planificación Inteligente
Para tareas complejas, Agent! crea un plan paso a paso, trabaja en cada paso y los va marcando en tiempo real.

### 🗂 Pestañas
Trabaja en varias tareas simultáneamente. Cada pestaña tiene su propia carpeta de proyecto e historial de conversación.

### 📸 Captura de Pantalla y Visión
Toma capturas de pantalla o pega imágenes. Los modelos de IA con capacidad de visión analizan lo que ven -- describen contenido, leen texto, detectan problemas de interfaz.

### 🌐 Automatización Web de Safari (Integrada)

Agent! incluye automatización web de Safari integrada vía JavaScript y AppleScript. Busca en Google, haz clic en enlaces, rellena formularios, lee el contenido de la página y ejecuta JavaScript -- todo sin usar las manos.

**Para activarla:** Abre Safari → Ajustes → Avanzado → marca "Mostrar funciones para desarrolladores web". Luego ve al menú Desarrollo → marca "Permitir JavaScript desde Eventos de Apple".

### 🎭 Automatización Web con Playwright (Opcional)

Automatización completa multi-navegador vía [Microsoft Playwright MCP](https://github.com/microsoft/playwright-mcp). Haz clic, escribe, captura pantalla y navega cualquier sitio web en Chrome, Firefox o WebKit -- todo controlado por la IA.

**Configuración (única vez):**

```bash
# 1. Instala Node.js (si aún no está instalado)
brew install node

# 2. Instala el servidor Playwright MCP globalmente
npm install -g @playwright/mcp@latest

# 3. Instala los binarios del navegador (elige uno o todos)
npx playwright install chromium          # Chrome (~165MB)
npx playwright install firefox           # Firefox (~97MB)
npx playwright install webkit            # Safari/WebKit (~75MB)
npx playwright install                   # Todos los navegadores
```

**Configura en Agent!:**

Ve a Ajustes → Servidores MCP → Añadir Servidor, pega este JSON:

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

> **Nota:** Si no se encuentra `npx`, usa la ruta completa: ejecuta `which npx` en Terminal y reemplaza `"npx"` con el resultado (p. ej. `"/opt/homebrew/bin/npx"`).

Actívalo y las herramientas de Playwright aparecerán automáticamente. La IA ahora puede controlar navegadores directamente.

### Herramientas — lo que `list_tools` realmente devuelve

Estos son los nombres canónicos de herramientas definidos en `AgentTools.Name.*` y expuestos a cada proveedor de LLM vía `AgentTools.tools(for:)`. Fuente de verdad: `~/Documents/GitHub/AgentTools/Sources/AgentTools/AgentTools.swift`. Los alternadores de preferencias de usuario de la app pueden ocultar herramientas individuales por proveedor, pero la lista de abajo es el conjunto completo que el LLM llega a ver.

#### Núcleo / descubrimiento

| Herramienta | Acciones / argumentos | Qué hace |
|---|---|---|
| **done** | `summary` | Señala que la tarea está completa. Requerida al final de cada tarea |
| **list_tools** | — | Devuelve la lista de herramientas activa para el proveedor actual (integradas + MCP) |
| **search** | `query` | Búsqueda web vía Exa, Tavily o DuckDuckGo (la que tenga clave configurada) |
| **chat** | `write` / `transform` / `fix` / `about` | Escribe prosa, transforma/corrige texto, describe las capacidades de Agent |
| **memory** | `read` / `write` / `append` / `clear` | Preferencias persistentes del usuario. "recuerda X" → `append` |
| **plan** | `create` / `update` / `read` / `list` / `delete` | CRUD multi-plan con seguimiento de estado por paso |
| **goal_state** | `set` / `get` / `mark` / `clear` | Meta persistente + criterios de éxito; marcar como terminado requiere evidencia |
| **restore_tool_result** | `tool_use_id` | Recupera el texto completo de un resultado de herramienta truncado por compactación |
| **directory** | `get` / `set` / `home` / `documents` / `library` / `none` / `cd` | Carpeta del proyecto para la pestaña actual |
| **fetch** | `url` | Obtiene URL, elimina el HTML, tope de 8K caracteres |
| **skill** | `list` / `invoke` / `save` / `delete` | Plantillas de prompt reutilizables |
| **ask_user** | `question` | Diálogo con el usuario a mitad de tarea (espera hasta 5 min) |

#### Código / archivos / compilación

| Herramienta | Acciones / argumentos | Qué hace |
|---|---|---|
| **file** | `read` / `write` / `edit` / `create` / `apply` / `undo` / `diff_apply` / `list` / `search` / `read_dir` / `mkdir` / `cd` / `if_to_switch` / `extract_function` | Todas las operaciones de archivo. `edit` = reemplazo de una sola cadena. `diff_apply` = preferido para ediciones de código de varias líneas |
| **git** | `status` / `diff` / `log` / `commit` / `diff_patch` / `branch` / `worktree` | Operaciones de git — usar en lugar de git por shell |
| **xcode** | `build` / `run` / `list_projects` / `select_project` / `add_file` / `remove_file` / `grant_permission` / `analyze` / `snippet` / `code_review` / `get_version` / `bump_version` / `bump_build` | Integración nativa de Xcode. Los errores en el registro de actividad son clicables |
| **agent_script** | `list` / `read` / `create` / `update` / `edit` / `run` / `delete` / `combine` / `restore` / `pull` / `list_backups` | Scripts dylib de Swift en `~/Documents/AgentScript/agents/` con TCC completo |

#### Shell / niveles de privilegio

| Herramienta | Argumentos | Qué hace |
|---|---|---|
| **user_shell** | `command` | Shell como usuario actual vía Launch Agent. Herramienta de shell principal |
| **root_shell** | `command` | Shell como ROOT vía Launch Daemon. Solo tareas administrativas — sin sudo |
| **shell** | `command` | Shell interno de respaldo (cuando el Launch Agent está desactivado) |
| **batch** | `commands` | Varios comandos de shell en una sola llamada (separados por saltos de línea) |
| **multi** | `description`, `tasks` | Varias llamadas a herramientas en un solo lote |

#### Automatización de macOS

| Herramienta | Acciones / argumentos | Qué hace |
|---|---|---|
| **accessibility** | `open_app` / `find_element` / `click_element` / `type_into_element` / `scroll_to_element` / `list_windows` / `inspect_element` / `get_properties` / `perform_action` / `set_properties` / `get_focused_element` / `get_children` / `read_focused` / `wait_for_element` / `wait_adaptive` / `highlight_element` / `manage_app` / `show_menu` / `click_menu_item` / `set_window_frame` / `get_window_frame` / `screenshot` / `check_permission` / `request_permission` / `get_audit_log` | Automatización basada en elementos con AXorcist. Cada acción toma `role`+`title`+`appBundleId` — sin coordenadas |
| **applescript** | `execute` / `lookup_sdef` / `list` / `run` / `save` / `delete` | NSAppleScript en el mismo proceso con TCC |
| **javascript** | `execute` / `list` / `run` / `save` / `delete` | JXA (JavaScript for Automation) |

#### Automatización web

| Herramienta | Acciones / argumentos | Qué hace |
|---|---|---|
| **safari** | `open` / `find` / `click` / `type` / `execute_js` / `get_url` / `get_title` / `read_content` / `google_search` / `scroll_to` / `select` / `submit` / `navigate` / `list_tabs` / `switch_tab` / `list_windows` / `scan` / `search` | Automatización de Safari vía JavaScript + AppleScript |
| **selenium** | `start` / `stop` / `navigate` / `find` / `click` / `type` / `execute` / `screenshot` / `wait` | Sesión de Selenium WebDriver — usa `safari` para el uso normal de Safari |
| **mcp_playwright_browser_\*** | (ver Playwright MCP) | Opcional. Automatización multi-navegador vía Playwright MCP |

#### Subagentes

| Herramienta | Argumentos | Qué hace |
|---|---|---|
| **spawn_agent** | `name`, `prompt`, `tools`, `model`, `max_iterations` | Genera un subagente aislado. 3 concurrentes (hasta 6 de solo lectura). Anulación de modelo opcional + resultados basados en archivos |
| **tell_agent** | `to`, `message` | Envía un mensaje al buzón de un subagente en ejecución |

> 💡 **Nota:** La app en el dispositivo filtra esta lista por proveedor — activa/desactiva herramientas individuales en el popover **Herramientas** (botón #6 en la barra de herramientas arriba). Apple Intelligence tiene su propio conjunto mínimo predeterminado debido a su ventana de contexto pequeña. Las herramientas MCP se añaden en tiempo de ejecución como `mcp_<servidor>_<herramienta>` y se listan bajo "--- MCP Tools ---" por `list_tools`.

## Privacidad y Seguridad

- **Tus datos permanecen en tu Mac.** Los archivos, el contenido de pantalla y los datos personales nunca se suben.
- **La IA en la nube solo ve el texto de tu prompt.** Usa IA local para permanecer 100% offline.
- **Tú tienes el control.** Agent! muestra todo lo que hace y registra cada acción.
- **Construido sobre el modelo de seguridad de Apple.** Los permisos de macOS protegen tu sistema.

### Capas de Defensa

| Capa | Qué hace |
|---|---|
| **Servicio de Seguridad de Shell** | Bloquea de forma estricta comandos catastróficos (`rm -rf /`, `rm -rf ~`, `dd` hacia `/dev/disk`, fork bombs, `--no-preserve-root`) antes de que se construya siquiera el Process. No puede ser eludido por el LLM. |
| **Enrutamiento TCC en el Mismo Proceso** | Un detector de 17 palabras clave enruta comandos de AppleScript, osascript, JXA, screencapture, accessibility, Shortcuts y ScriptingBridge para que se ejecuten en el mismo proceso donde Agent! posee los permisos TCC — nunca a través del Launch Agent/Daemon (identificadores de paquete distintos = sin TCC). |
| **Copia de Seguridad de Archivo en Cada Edición** | `FileBackupService` toma automáticamente una instantánea de cada archivo antes de `write_file`, `edit_file` y `diff_apply`. Recuperable vía `file(action:"restore")` o la interfaz de Reversión. TTL de 1 semana. |
| **Papelera de Agent Script** | `delete_agent` copia el script a `~/Documents/AgentScript/agents/.Trash/` antes de eliminarlo. Recuperable vía `agent_script(action:"restore")`. |
| **Normalización del Directorio de Trabajo** | Cada ruta de ejecución de shell (`executeTCC`, `UserService`, `HelperService`) normaliza el directorio de trabajo — si accidentalmente se pasa una ruta de archivo como cwd, la recorta al directorio padre en lugar de fallar con "Not a directory". |
| **Drenaje de Tarea Antes de Iniciar** | Iniciar una nueva tarea espera a que termine completamente la tarea anterior antes de comenzar — evita que bucles de reintento huérfanos mezclen la salida del registro entre proveedores. |
| **Cadena de Respaldo** | Cuando el LLM principal falla (429, tiempo de espera, red), Agent! cambia automáticamente al siguiente proveedor en la cadena configurada por el usuario tras 2 fallos. |
| **Errores Accionables** | Cada error de herramienta incluye una pista de `Recovery:` que le indica al LLM exactamente qué intentar a continuación — sin mensajes de error sin salida que desperdicien turnos. |
| **Invalidación de Caché de Lectura** | La caché de lectura de archivos se invalida tanto en ediciones exitosas como en ediciones fallidas, así el LLM siempre obtiene contenido actualizado en la siguiente lectura. |
| **Búsqueda por Nombre Base** | Cuando `read_file` o `edit_file` recibe una ruta incorrecta, Agent! busca en directorios cercanos archivos con el mismo nombre y devuelve las rutas correctas en línea — el LLM se autocorrige en un turno. |
| **Control de Ejecución de Herramientas** | El LLM no puede fabricar resultados de herramientas. Todas las llamadas a herramientas pasan por el `dispatchTool()` de la app → ejecución real (XPC, shell, en el mismo proceso) → salida real devuelta como `tool_result`. El LLM solo ve y resume salidas que realmente ocurrieron. Si una herramienta falla, se devuelve el error real — el LLM no puede afirmar éxito sin un evento de ejecución que lo respalde. |
| **action_not_performed** | Defensa de dos capas contra afirmaciones de acciones falsas: **(1) Prompt** — el prompt del sistema instruye al LLM a decir "acción no realizada" si no se llamó a ninguna herramienta. **(2) App** — si el LLM devuelve texto afirmando "busqué/abrí/hice clic" pero no hizo ninguna llamada a herramientas ese turno, se inyecta una corrección que lo obliga a usar la herramienta real. |

---

## Atajos de Teclado

Fuente de verdad: el `.onSubmit` del TextField en `Agent/Views/InputSectionView.swift` para `Return`, y el bloque en línea `NSEvent.addLocalMonitorForEvents` en `Agent/Views/ContentView.swift` para todo lo demás.

| Atajo | Acción |
|---|---|
| `Return` | Ejecuta la tarea actual (envío del TextField — no requiere modificador) |
| `⌘ .` / `Escape` | Cancela la tarea en ejecución |
| `⌘ B` | Activa/desactiva la superposición de Salida del LLM (mostrar/ocultar) |
| `⌘ D` | Activa/desactiva ambos chevrones del LLM en la pestaña actual (expandir/contraer) |
| `⌘ T` | Nueva pestaña |
| `⌘ W` | Cierra la pestaña actual (o sale si no hay pestañas) |
| `⌘ 1`–`⌘ 9` | Cambia de pestaña. `⌘1` es la pestaña principal; `⌘2`–`⌘9` son pestañas de script |
| `⌘ Shift ←` / `⌘ Shift →` | Pestaña anterior / siguiente |
| `⌘ F` | Activa/desactiva la barra de búsqueda del registro de actividad |
| `⌘ L` | Borra el registro de la pestaña activa |
| `⌘ V` | Pega imagen desde el portapapeles |
| `↑` / `↓` | Historial de instrucciones (en el campo de entrada) |
| `⌘ Shift M` | Activa/desactiva el Monitor de Mensajes |
| `⌘ Shift P` | Abre Ajustes (aquí está el editor del prompt del sistema) |
| `⌘ Shift K` | Borrar todo (reinicio completo) |
| `⌘ Shift L` | Borra solo el panel de salida del LLM |
| `⌘ Shift H` | Borra el historial de instrucciones |
| `⌘ Shift J` | Borra el historial de tareas |
| `⌘ Shift U` | Borra los contadores de tokens |

## Comandos con Barra

Escribe estos en el campo de entrada y pulsa Return — se ejecutan localmente sin ir a ningún LLM. Fuente de verdad: `AgentViewModel+RunStop.swift`.

| Comando | Acción |
|---|---|
| `/clear` o `/clear log` | Borra el registro de actividad de la pestaña actual |
| `/clear all` | Borra todo (registro, salida del LLM, historial de prompts, historial de tareas, tokens) |
| `/clear llm` | Borra solo el panel de salida del LLM |
| `/clear history` | Borra el historial de instrucciones |
| `/clear tasks` | Borra el historial de tareas |
| `/clear tokens` | Reinicia los contadores de tokens (tarea + sesión) |
| `/memory` o `/memory show` | Imprime el contenido actual del archivo de memoria en el registro de actividad |
| `/memory clear` | Borra la memoria |
| `/memory edit` | Abre `~/Documents/AgentScript/memory.md` en el editor predeterminado del sistema |
| `/memory <texto>` | Añade `<texto>` a la memoria (todo lo que sigue a `/memory` se convierte en la nueva línea) |

---

## Preguntas Frecuentes

**¿Necesito saber programar?** No. Solo escribe lo que quieres en inglés sencillo.

**¿Es seguro?** Sí. Automatización estándar de macOS, registro de actividad completo, tú apruebas los permisos.

**¿Cuánto cuesta?** La app Agent! en sí es gratuita (Licencia MIT). Los proveedores de IA en la nube cobran por el uso de la API — las opciones más económicas para trabajo serio son GLM-5/5.1 vía Z.ai, BigModel o Hugging Face (centavos por millón de tokens), o DeepSeek para programación económica. Los modelos locales autoalojados (Ollama, vLLM, LM Studio) no tienen tarifas de API pero solo tienen sentido si ya cuentas con el hardware para ejecutarlos — consulta la nota de hardware abajo.

**¿Qué Mac necesito?** macOS 26.4.1. Se requiere Apple Silicon. Para proveedores en la nube, cualquier Mac moderno funciona bien. Para modelos locales autoalojados (Ollama, vLLM, LM Studio): un modelo de 7B cabe en 16GB de memoria unificada, un modelo de 13B en 24GB, un modelo de 30B necesita 64GB+ (territorio de Mac Studio M2/M3/M4 Ultra). Apple Intelligence (el mediador en el dispositivo para selección / compresión de tokens) necesita un Mac Apple Silicon con Apple Intelligence activado en Ajustes del Sistema.

**¿En qué se diferencia de Siri?** Siri responde preguntas. Agent! *realiza acciones* -- controla apps, gestiona archivos, compila código, automatiza flujos de trabajo.

---

## Documentación

- [Arquitectura Técnica](docs/TECHNICAL.md) -- Herramientas, scripting, detalles para desarrolladores
- [Comparaciones](docs/COMPARISON.md) -- vs Claude Code, Cursor, Cline, OpenClaw
- [Modelo de Seguridad](docs/SECURITY.md) -- Arquitectura XPC, separación de privilegios
- [Preguntas Frecuentes](docs/FAQ.md) -- Preguntas comunes

---

## Herramientas Integradas de Xcode

Agent! incluye integración nativa con Xcode que funciona sin ninguna configuración de servidor MCP. Estas herramientas integradas suelen ser más rápidas y fiables que la alternativa de MCP, ya que se ejecutan directamente dentro de la app.

| Herramienta | Qué hace |
|---|---|
| **xcode build** | Compila el proyecto de Xcode actual, captura errores y advertencias. Los errores en el registro de actividad son **clicables** y se abren directamente en Xcode. |
| **xcode run** | Compila y ejecuta la app |
| **xcode list_projects** | Descubre espacios de trabajo y proyectos de Xcode abiertos |
| **xcode select_project** | Cambia el proyecto activo |
| **xcode grant_permission** | Concede acceso de archivos a la carpeta del proyecto de Xcode |
| **xcode get_version** | Lee la versión de marketing actual y el número de compilación del proyecto de Xcode |
| **xcode bump_version** | Incrementa la versión de marketing (mayor, menor o parche), actualiza el número de compilación, compila para verificar, y confirma automáticamente |
| **xcode bump_build** | Incrementa solo el número de compilación |

Solo di *"sube la versión"* y Agent! lee la versión actual, pregunta mayor/menor/parche, actualiza Info.plist y los ajustes del proyecto, compila para verificar, y confirma el cambio. Sin edición manual de plist, sin números de compilación olvidados.

La IA usa estas herramientas automáticamente cuando le pides compilar, arreglar errores o trabajar con proyectos de Xcode. No requiere configuración -- solo ten tu proyecto abierto en Xcode.

> 🚀 **Soporte para iOS/iPadOS:** ¡Próximamente! El soporte nativo para compilar, ejecutar y probar apps de iOS y iPadOS directamente desde Agent! está en desarrollo.

> **Consejo:** Para la mayoría de los flujos de trabajo de codificación, las herramientas integradas son todo lo que necesitas. El servidor MCP de Xcode de abajo añade extras como renderizado de SwiftUI Preview y búsqueda de documentación.


---

<img width="1349" height="1438" alt="Screenshot 2026-04-02 at 12 00 03 PM" src="https://github.com/user-attachments/assets/b0d9346e-f807-4089-bab3-29c7058868d8" />

## Dos formas de hablar con Agent! — voz e iMessage

Ambas funciones usan la misma palabra clave: **"¡Agent!"** (sin distinción entre mayúsculas y minúsculas — `Agent!`, `agent!`, `AGENT!`, incluso solo `Agent ` o `agent ` funcionan).

### 🎤 Voz (palabra clave de dictado)

Haz clic en el micrófono de la barra de entrada e inicia la sesión de palabra clave, luego habla. Agent! transcribe en tiempo real usando `SFSpeechRecognizer` y escucha la palabra "agent" como palabra completa (no como subcadena de "intelligent" o "management"). Todo lo que digas después de "agent" se convierte en la tarea. Tras ~2.5 segundos de silencio, la tarea se ejecuta automáticamente.

Ejemplos:
- *"Agent, ¿qué canción está sonando?"*
- *"Agent toma una captura de pantalla de Safari"*
- *"Agent compila el proyecto de Xcode"*

La sesión de palabra clave se repite automáticamente — después de que una tarea termina, vuelve a escuchar. Haz clic en el micrófono de nuevo para detenerla.

### 📱 iMessage (control remoto)

Envía un mensaje a tu Mac desde tu iPhone. Agent! consulta `~/Library/Messages/chat.db` cada 5 segundos en busca de mensajes nuevos y reacciona a cualquiera que comience con **`Agent!`** (sin distinción entre mayúsculas y minúsculas, el signo de exclamación es opcional).

Ejemplos:
```
Agent! ¿Qué canción está sonando?
agent! revisa mi correo
AGENT! siguiente canción
Agent  abre Safari
```

Agent! envía un acuse de recibo inmediato de "Trabajando en ello...", ejecuta la tarea en una pestaña dedicada de Messages usando la configuración de LLM de tu pestaña principal, y luego te envía el resultado por mensaje.

**Configuración (única vez):**

1. **Concede Acceso Total al Disco** — Ajustes del Sistema → Privacidad y Seguridad → Acceso Total al Disco → activa Agent! (requerido para leer `chat.db` directamente vía SQLite)
2. **Abre el Monitor de Mensajes** — botón #2 de la barra de herramientas (ícono de burbuja de chat, se pone verde cuando está activo)
3. **Aprueba un remitente** — una vez que llega un mensaje de un contacto nuevo, ese contacto aparece en la lista de destinatarios. Actívalo para aprobarlo.

Solo los remitentes aprobados pueden ejecutar tareas. Los mensajes no aprobados se registran pero se ignoran. Tu respuesta se envía de vuelta vía AppleScript al mismo identificador que envió el comando, con un límite de 4000 caracteres.

Las respuestas salientes tienen cualquier "Agent!" inicial eliminado para que el Mac receptor no active su propio bucle de comandos.

---

Agent! admite servidores [MCP](https://modelcontextprotocol.io) para capacidades extendidas. Configúralos en Ajustes → Servidores MCP.

### Servidor MCP de Xcode

Conecta Agent! directamente a Xcode para operaciones conscientes del proyecto:

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

**El MCP de Xcode ofrece:**
- Operaciones de archivo conscientes del proyecto (leer/escribir/editar/eliminar)
- Integración de compilación y pruebas
- Renderizado de SwiftUI Preview
- Ejecución de fragmentos de código
- Búsqueda en la Documentación para Desarrolladores de Apple
- Seguimiento de problemas en tiempo real


---

## Licencia

MIT - libre y de código abierto.

---

<div align="center">

### **Agent! para macOS 26.4.1 - IA Agéntica para tu Mac de Escritorio**
> Nota: Claude se refiere al modelo de IA de Anthropic integrado en Agent! para la funcionalidad de LLM. No es un colaborador humano de Agent!
</div>

---

## Agent! vs Claude Code — Comparación Arquitectónica

Agent! es una aplicación macOS 100% original en Swift puro. No es un port, fork ni derivado de ningún otro proyecto.

| | Claude Code | Agent! |
|---|---|---|
| **Lenguaje** | TypeScript/JavaScript | Swift 6.2 puro |
| **Framework de UI** | Ink (React de terminal) | SwiftUI (nativo de macOS) |
| **Plataforma** | CLI — Linux, macOS, Windows | Solo macOS 26.4.1 nativo |
| **Runtime** | Node.js/Bun | Binario compilado nativo |
| **Arquitectura** | REPL de terminal con streaming | App de escritorio con daemons XPC |
| **Accessibility** | Ninguna (CLI) | AX completo de macOS vía AXorcist (25 acciones de nivel superior, 30+ subtipos de AX vía `perform_action`) |
| **AppleScript** | Ninguno | NSAppleScript + JXA completo en el mismo proceso con TCC |
| **Integración con Xcode** | Vía Bash (`xcodebuild`) | Nativa (build/run/analyze/snippet/add_file/bump_version/code_review — 13 acciones) |
| **Apple Intelligence** | Ninguna | FoundationModels en el dispositivo — maneja la clasificación de saludos/charla trivial, resúmenes de tareas, explicaciones de errores, y compresión de tokens de Nivel 1. La automatización de UI la maneja el LLM principal vía la herramienta `accessibility`, no Apple AI |
| **ScriptingBridge** | Ninguno | SDEF completo + 51 puentes de eventos (Finder, Mail, Music, Safari, Calendar, etc.) |
| **Visión** | Entrada de imagen vía API | Entrada de imagen vía API |
| **Auto-capturas de pantalla** | Ninguna (sin UI) | Auto-verificación opcional tras acciones de UI (desactivada por defecto — ver `visionAutoScreenshotEnabled`) |
| **iMessage** | Ninguno | Agente remoto vía Messages (se requiere Acceso Total al Disco para `chat.db`) |
| **Voz** | Ninguna | Dictado anclado a palabra clave vía SFSpeechRecognizer |
| **Efecto CRT** | Ninguno | Superposición opcional de líneas de escaneo en SwiftUI Canvas (alternar vía botón del HUD) |
| **Modelo de Privilegios** | Sandbox de usuario | Launch Agent XPC (usuario) + Launch Daemon (root) |
| **Subagentes** | Herramienta Task (documentada públicamente; detalles de implementación no revelados por Anthropic) | Hasta 3 concurrentes (6 de solo lectura) agentes aislados con mensajería de buzón y anulación de modelo por agente |
| **MCP** | stdio/SSE de Node.js | Paquete Swift AgentMCP |
| **Scripts** | Ninguno | Compilación de dylib de Swift en tiempo de ejecución, cargado con dlopen en el mismo proceso con TCC completo |
| **Caché de prompts** | `cache_control` efímero de Anthropic | `cache_control` efímero de Anthropic + seguimiento automático de aciertos de caché de prefijo para OpenAI/Z.ai/Grok/Mistral/Gemini/Qwen/DeepSeek; `keep_alive: 30m` de Ollama |
| **Compactación de contexto** | Claude en la nube (tokens de pago; la conversación se reenvía a Anthropic) | Escalonada: Nivel 1 = resumen en el dispositivo con Apple Intelligence (gratis, privado, sin tokens de API). Nivel 2 = poda agresiva si Apple AI no está disponible. El umbral se escala a la ventana de contexto del modelo (~55%, 2K–400K), los resúmenes se memorizan, disyuntor de 3 fallos, resultados completos de herramientas volcados a disco antes de truncar |

## Agent! vs Cursor — Comparación Rápida

Cursor es un excelente editor de código con IA. Agent! juega un juego diferente: es un agente para toda tu **Mac**, no solo tu base de código.

| | Cursor | Agent! |
|---|---|---|
| **Qué es** | Editor de código con IA (fork de VS Code, Electron) | App de agente nativa en SwiftUI para macOS |
| **Alcance** | Tu base de código | Toda tu Mac — código, apps, archivos, sistema |
| **Precios** | Suscripción | Gratis y de código abierto (MIT) — usa tu propia clave de API o ejecútalo en local |
| **Modelos locales** | Priorizado en la nube | Ollama, vLLM, LM Studio, Apple Intelligence en el dispositivo |
| **Automatización de apps de Mac** | Ninguna | API de Accessibility, AppleScript/JXA, ScriptingBridge (51 puentes de apps) |
| **Tareas administrativas a nivel root** | Ninguna | Launch Daemon privilegiado vía XPC (aprobado una vez) |
| **Control por voz / iMessage** | Ninguno | Dictado por palabra clave + agente remoto vía Messages |
| **Integración con Xcode** | `xcodebuild` por terminal | Herramientas nativas de build/run/analyze/code-review |
| **Telemetría** | Requiere cuenta en la nube | Ninguna — tus claves, tu máquina, tus datos |

Si vives dentro de un solo repositorio todo el día, Cursor es excelente. Si quieres un agente que también compile tu proyecto de Xcode, controle Safari, te envíe resultados por mensaje, e instale software como root -- eso es Agent!.

## Contribuir

¿Quieres colaborar en Agent!? Consulta [CONTRIBUTING.md](./CONTRIBUTING.md) — puedes compilar desde el código fuente en unos 5 minutos con solo las Xcode Command Line Tools (`./build.sh`), sin necesidad de cuenta de Apple Developer. Revisa los [good first issues](https://github.com/AgentiLoop/Agent/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) para tareas iniciales acotadas.

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
> Atentamente,
> **AgentiLoop — Agent!**
> 🦾 Agent! para macOS 26.4.1
> https://AgentiLoop.ai
> https://github.com/AgentiLoop/agent
