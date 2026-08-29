# 🦾 Agent! para macOS 26.4.1 o posterior

## **IA Agéntica para tu Mac**

[![Última Versión](https://img.shields.io/github/v/release/macOS26/Agent?label=Descargar&color=blue&style=for-the-badge)](https://github.com/macOS26/Agent/releases/latest)
[![Estrellas en GitHub](https://img.shields.io/github/stars/macOS26/Agent?style=for-the-badge&logo=github&label=Estrellas&color=gold)](https://github.com/macOS26/Agent/stargazers)
[![Forks en GitHub](https://img.shields.io/github/forks/macOS26/Agent?style=for-the-badge&logo=github&label=Forks&color=white)](https://github.com/macOS26/Agent/fork)
[![macOS 26.4+](https://img.shields.io/badge/macOS-26.4.1-green?style=for-the-badge)](https://github.com/apple)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange?style=for-the-badge)](https://www.swift.org)
<a href="https://www.paypal.com/ncp/payment/9C6RY2UAE5M3S"><img src="https://img.shields.io/badge/Donación-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Jar de Propinas" /></a>

## Traducciones del README

- [English](README.md)
- [Español](README.es.md)
- [Français](README.fr.md)
- [Deutsch](README.de.md)
- [Português (Brasil)](README.pt-BR.md)
- [العربية](README.ar.md)
- [中文 (简体)](README.zh-CN.md)
- [日本語](README.ja.md)

## Ajedrez dentro de Agent
<img width="1176" height="724" alt="Screenshot 2026-08-23 at 7 34 10 PM" src="https://github.com/user-attachments/assets/d3b2f1e5-1dab-44f7-95f6-008424ee794c" />

## Historia y Tecnología detrás de Agent!

Agent! no se creó de la noche a la mañana. Es el resultado de tres años construyendo aplicaciones de IA agéntica, basadas en aproximadamente una docena de proyectos desarrollados en el camino. Algunos fueron publicados bajo ANIE, Game Changer, BattleScript, XCF MCP Server and Client, D1F y alrededor de ocho paquetes Swift originales. La pieza que faltaba era lograr un bucle de tiempo autónomo inteligente. Una vez logrado, incorporé lo mejor de lo mejor de los tres años anteriores. El resultado es Agent! para macOS 26.4.1 o posterior.

El objetivo original era crear un "asesino de Cursor". Lo que surgió es algo más interesante: una IA agéntica con verdaderas capacidades. Agent! solo está limitado por tu imaginación. Puede escribir código incluyendo videojuegos como Boss-Man (https://github.com/macos26/bossman), crear aplicaciones, escribir poesía a través de AppleScript dentro de Pages, generar imágenes de disco y adjuntarlas a lanzamientos de GitHub. Puede automatizar la mayoría de las tareas en tu Mac. Dile qué quieres en inglés simple o en tu idioma nativo y, después de una configuración inicial y aprobaciones del usuario, hará todo lo posible para cumplir tu deseo. Agent! es implacable y apunta a complacer.

Toda la propiedad intelectual de Agent! es original y de código abierto. Cada dependencia de paquete Swift y la aplicación misma fueron originalmente creadas por la misma persona. Este es un ecosistema genuinamente diferente. La mayoría de aplicaciones de IA agéntica como Claude Code dependen de 65 paquetes NPM de terceros. Agent! es 100% nativa, requiere muy poca RAM y pesa 35.5 MB sin comprimir. Este tamaño incluye automatización de Xcode, un paquete Swift Syntax 6.2 para solucionar problemas de aplicaciones nativas, Accesibilidad, AppleScript, AgentScript/ScriptingBridge, automatización de Safari, soporte de servidores MCP y más. Listo para usar.

## Novedades 🚀

**v1.0.92 (186) — La Versión de Autonomía Auto-Verificable** · [Notas de lanzamiento completas →](https://github.com/macOS26/Agent/releases/tag/v1.0.92.186)

Ahora Agent! prueba su trabajo. Una tarea no puede declararse completa hasta que sus criterios de éxito se verifiquen con evidencia (`goal_state`), un crítico opcional revisa el diff antes de la finalización, y cada archivo tocado puede ser revertido en un instante (`rewind_task`). Pensamiento extendido para Claude, `reasoning_effort` para proveedores compatibles con OpenAI, y un contexto estable en caché de indicador que se compacta a la ventana real de cada modelo — recuperablemente, con resultados de herramientas completas vertidos al disco. Los errores de herramienta escrita llevan consejos de recuperación, los subagenates ejecutan sus propios modelos (hasta 6 investigadores de solo lectura), los ganchos de eventos están completamente conectados y 57 pruebas aprobadas lo mantienen honesto.

**Una aplicación. Cualquier IA. Control total de tu Mac.**

Agent! conecta **18 proveedores de LLM** — Claude, GPT, Gemini, Grok, Mistral, DeepSeek, Qwen, Z.ai, BigModel, Hugging Face, **OpenRouter**, Ollama (nube y local), vLLM, LM Studio, Codestral, Mistral Vibe e **Inteligencia Artificial de Apple** — en una aplicación macOS nativa que no solo habla sobre hacer cosas. Las hace.

Míralo leer tu base de código, arreglar el error, compilar el proyecto de Xcode y confirmar el diff mientras tomas café. Dile que abra Safari y te envíe un mensaje de texto con el precio de los vuelos a Tokio. Di *"Agent!"* desde al otro lado de la habitación y que ejecute tu suite de pruebas por voz. Envía un mensaje de texto a tu Mac desde iMessage y obtén una respuesta pulida antes de llegar a tu automóvil.

Edita archivos con diffs de reemplazo de cadena quirúrgica — cada cambio reversible con un clic desde una reversión de estilo Máquina de Tiempo. Controla cualquier aplicación Mac a través de la API de Accesibilidad — no se requiere AppleScript. Recuerda tus preferencias en todas las sesiones. Genera subagenates paralelos para trabajo que se ramifica. Indexa bases de código completas en un repositorio JSONL portátil que cualquier LLM puede consumir. Ejecuta comandos de shell como tú, o como root a través de un Launch Daemon que apruebas exactamente una vez.

Trae tu propia clave API. Ejecútalo completamente local en Ollama, vLLM o LM Studio. O ejecútalo gratis, por siempre, en Inteligencia Artificial de Apple. Sin suscripción. Sin telemetría. Sin bloqueo de proveedor. Tus claves, tu máquina, tus datos.

Descárgalo. Di lo que necesitas. Mira cómo sucede.

## Inicio Rápido (Descargar)

1. **Descarga** [Agent!](https://github.com/macOS26/Agent/releases/latest) y arrastra a Aplicaciones
2. **Abre Agent!** — configura todo automáticamente
3. **Elige tu IA** — Configuración → elige un proveedor → ingresa tu clave API

## Inicio Rápido (Compilar desde Código Fuente)

1. **Clona el repositorio:**
   ```bash
   git clone https://github.com/macos26/agent.git
   cd Agent
   ```

#### Opción A: Compilar con Xcode (cuenta de desarrollador de Apple)
2. **Abre `Agent.xcodeproj` en Xcode.**
3. **Compila y ejecuta el destino `Agent`.**
4. **Aprueba la Herramienta Auxiliar:** Cuando se solicite, autoriza el daemon privilegiado para permitir la ejecución de comandos a nivel raíz.

#### Opción B: Compilar sin una cuenta de desarrollador de Apple
2. **Ejecuta el script de compilación** (requiere solo las Herramientas de Línea de Comandos de Xcode):
   ```bash
   ./build.sh              # Compilación de depuración
   ./build.sh Release      # Compilación de lanzamiento
   ```
3. La aplicación se coloca en `build/DerivedData/Build/Products/Debug/Agent!.app`
4. **Ejecútalo:** `open "build/DerivedData/Build/Products/Debug/Agent!.app"`

> ⚠️ Sin una cuenta de desarrollador, la aplicación está firmada de forma ad-hoc. Los auxiliares del Agente de Lanzamiento/Daemon no se registrarán (SMAppService necesita un ID de equipo), pero el bucle de LLM, todas las herramientas, accesibilidad, AppleScript, shell y MCP funcionan.

#### Luego:
5. **Configura tu Proveedor de IA:** Ve a Configuración e ingresa tu clave API o selecciona un proveedor local como Ollama.

> 💡 **Configuración GLM económica:** **GLM-5.1** se ejecuta en los cuatro proveedores económicos — **Ollama**, **Hugging Face**, **Z.ai**, **BigModel** — a centavos por millón de tokens. ¿Nuevo aquí? Comienza con **Z.ai** (registro más rápido, GLM-5.1 es el predeterminado, nada que aprovisionar). ¿Ejecutando localmente? Solo **GLM-4.7-Turbo** (32B) cabe en hardware de consumidor (M2/M3/M4 Mac, 64-128GB, vía Ollama) — GLM-5 y GLM-5.1 son demasiado grandes (~1.6TB), úsalos a través de los proveedores de nube anteriores.

## ¿Qué Puede Hacer?

> *"Reproduce mi lista de reproducción Workout en Música"*
> *"Compila el proyecto de Xcode y corrige cualquier error"*
> *"Toma una foto con Photo Booth"*
> *"Envía un iMessage a Mamá diciendo que llegaré a las 6"*
> *"Abre Safari y busca vuelos a Tokio"*
> *"Refactoriza esta clase en archivos más pequeños"*
> *"¿Qué eventos de calendario tengo hoy?"*

Solo escribe lo que quieres. Agent! descubre cómo hacerlo y lo hace.

---

## Características Clave

### 🧠 Marco de IA Agéntica
Bucle de tarea autónomo integrado que razona, ejecuta y se autocorrige. Agent! no solo ejecuta código; observa los resultados, depura errores e itera hasta que la tarea se complete. El estado de objetivo con criterios de éxito verificados por evidencia significa que una tarea no puede declararse completa hasta que lo demuestre.

### 🛠 Codificación Agéntica
Entorno de codificación completo integrado. Lee bases de código, edita archivos con precisión, ejecuta comandos de shell, compila proyectos de Xcode, gestiona git y habilita automáticamente el modo de codificación para enfocarse en herramientas de desarrollo. Reemplaza Claude Code, Cursor y Cline — sin terminal, sin complementos de IDE, sin tarifa mensual. Características **copias de seguridad de estilo Máquina de Tiempo** para cada cambio de archivo, permitiéndote revertir cualquier edición al instante.

### 🔍 Descubrimiento Dinámico de Herramientas
Detecta y utiliza automáticamente herramientas disponibles (Xcode, Playwright, Shell, etc.) basadas en tu indicación. No se requiere configuración manual para herramientas básicas.

### 🛡 Ejecución Privilegiada
Ejecuta comandos a nivel raíz de forma segura a través de un macOS Launch Daemon dedicado. El usuario aprueba el daemon una vez, luego el agente puede ejecutar comandos de forma autónoma a través de XPC.

#### Por qué no hay `setCodeSigningRequirement` manual en el oyente XPC

Los usuarios a veces preguntan por qué el oyente XPC de `AgentHelper` acepta conexiones sin una comprobación manual de `connection.setCodeSigningRequirement(...)`. La respuesta corta: **SMAppService ya aplica la identidad de firma un nivel debajo de tu código**, por lo que la comprobación sería redundante.

Esa recomendación es un legado de la era pre-SMAppService **SMJobBless**, donde launchd no validaba la identidad para ti y el servidor XPC tenía que establecer una cadena de requisito designado por sí mismo. SMAppService cambió ese contrato:

- El plist incrustado en el paquete de aplicaciones más el registro con puerta de firma **es** el requisito de firma de código.
- Los nombres de servicio Mach (`Agent.app.toddbruss.helper`, `Agent.app.toddbruss.user`) están nominados al paquete firmado que los registró — ningún otro paquete puede reclamarlos.
- Cualquier falta de coincidencia de firma (manipulación, re-firma, ID de equipo diferente, intercambio de paquete) **rompe el canal XPC en la capa launchd** — `listener(_:shouldAcceptNewConnection:)` nunca se invoca.

**Prueba empírica:** El propio Agent! intentó re-firmar sus propios daemons durante un experimento e inmediatamente perdió la capacidad de conectarse. `NSXPCConnection` a ambos servicios Mach falló en la capa launchd antes de que un solo byte llegara al delegado del oyente — exactamente el comportamiento que haría una llamada manual a `setCodeSigningRequirement`, excepto que SMAppService lo está haciendo en la ruta de búsqueda XPC del kernel donde no puede ser eludida desde el espacio de usuario.

| Cumplimiento | Mecanismo | ¿Eludible desde el espacio de usuario? |
|---|---|---|
| El auxiliar debe estar en el paquete de aplicación firmado | Gatekeeper + registro SMAppService | No |
| El auxiliar debe coincidir con el ID de equipo de la aplicación (469UCUB275) | Firma de código + SMAppService | No |
| El nombre del servicio Mach se vincula al paquete firmado | launchd / espacio de nombres XPC | No |
| El hash binario del auxiliar coincide con la identidad registrada | SMAppService + búsqueda XPC del kernel | No (re-firmar rompe el canal) |
| El usuario aprobó el auxiliar | Configuración del Sistema → Elementos de Inicio y Extensiones | No (se requiere gesto del usuario) |

Agregar `setCodeSigningRequirement` explícitamente sería una defensa razonable en profundidad (útil solo si la aplicación fuera portada fuera de SMAppService, o si SIP fuera deshabilitado), pero **no es una brecha** en la arquitectura actual. Consulta [docs/SECURITY.md](docs/SECURITY.md) para el escrito completo del anclaje de confianza.

### 🖥 Automatización de Escritorio (AXorcist)
Controla cualquier aplicación Mac a través de la API de Accesibilidad. Haz clic en botones, escribe en campos, navega por menús, desplázate, arrastra — todo programáticamente. Impulsado por [AXorcist](https://github.com/steipete/AXorcist) para búsqueda de elementos confiable y difusa.

### 🤖 18 Proveedores de IA

El selector de proveedores (Configuración de LLM, botón de barra de herramientas #7) muestra 17 proveedores; la Inteligencia Artificial de Apple se alcanza a través del icono de cerebro separado (#8). Fuente de la verdad: `AgentTools.APIProvider`.

| Proveedor | Clave API | Mejor para |
|---|---|---|
| **Claude** (Anthropic) | Pagado | Tareas autónomas largas, razonamiento complejo, almacenamiento en caché de indicadores |
| **OpenAI** | Pagado | Propósito general, llamada de herramientas, visión |
| **Google Gemini** | Pagado (nivel gratuito) | Contexto largo, visión, rápido |
| **Grok** (xAI) | Pagado | Información en tiempo real |
| **Mistral** | Pagado | Nube de peso abierto, llamada de herramientas rápida |
| **Codestral** (Mistral) | Pagado | Mistral especializado en código |
| **Mistral Vibe** | Pagado | Producto de chat/agente de Mistral |
| **DeepSeek** | Económico | Nube presupuestaria, codificación fuerte, informe de tasa de acierto de caché de indicador |
| **Hugging Face** | Varía | Modelos de código abierto alojados sin servidor o en puntos finales dedicados |
| **OpenRouter** | Pagado | 200+ modelos a través de una sola clave API — Claude, GPT, Gemini, Llama, Mistral y más. El conmutador de protocolo inteligente encamina los modelos de Claude a través del protocolo de Anthropic, todo lo demás a través de OpenAI |
| **Z.ai** | Económico | GLM-5.1 a través de API — punto de partida recomendado |
| **BigModel** (Zhipu) | Económico | Familia GLM a través de API de Zhipu |
| **Qwen** (Alibaba) | Económico | Qwen 2.5 / 3 a través de Dashscope |
| **Ollama** (nube) | Nivel gratuito | Ejecuta modelos abiertos a través del punto final alojado de Ollama |
| **Ollama Local** | Gratuito + hardware | Daemon Ollama autohosped — completamente sin conexión, sin cuenta |
| **vLLM** | Gratuito + hardware | Servidor vLLM autohosped con almacenamiento en caché de prefijos |
| **LM Studio** | Gratuito + hardware | Autohosped, GUI más fácil para modelos locales |
| **Inteligencia Artificial de Apple** | Gratuito, en el dispositivo | Clasificación, resumen, compresión de tokens (a través del icono del cerebro, no el selector de proveedor) |

> 💡 **Los proveedores "gratuitos" autohosped (Ollama Local, vLLM, LM Studio) solo son gratuitos en el sentido de tarifa de API.** Ejecutar un modelo de 30B+ con velocidad utilizable necesita una Mac Studio Ultra M2/M3/M4 (memoria unificada de 64-128GB) o una caja Linux con VRAM de 24GB+. Si no posees ese hardware, los caminos de nube anteriores (Ollama Cloud, Hugging Face, Z.ai, BigModel, DeepSeek) son dramáticamente más económicos que comprarlo.

## Botones de la Barra de Herramientas

El encabezado de Agent! contiene **15 botones** para acceso rápido a configuración, monitores y herramientas. Cada botón abre un popover cuando se hace clic. Fuente de la verdad: `Agent/Views/HeaderSectionView.swift`.

| # | Icono | Nombre | Lo que hace |
|---|------|--------|---------------|
| 1 | ⚙️ | **Servicios** | Alterna el Agente de Lanzamiento / Daemon de Lanzamiento, gestiona la carpeta del proyecto, escanea la salida del comando |
| 2 | 💬 | **Monitor de Mensajes** | Alterna el monitoreo de iMessage activado/desactivado — verde cuando está activo. Abre la lista de destinatarios y la UI de aprobación |
| 3 | ✋ | **Accesibilidad** | Abre la hoja de configuración de Accesibilidad (estado de permiso, diagnósticos de axorcist) |
| 4 | 🖥️ | **Servidores MCP** | Agregar/eliminar/configurar servidores MCP (Protocolo de Contexto Modelo) — extiende Agent! con herramientas `mcp_*` |
| 5 | </> | **Preferencias de Codificación** | Alterna verificación automática, pruebas visuales, relaciones públicas automáticas, andamios automáticos. Verde cuando cualquiera está activado |
| 6 | 🔧 | **Herramientas** | Alternancias de herramientas por proveedor. Habilita/deshabilita herramientas integradas individuales y MCP |
| 7 | 🧠 | **Configuración de LLM** | Elige proveedor de IA, modelo, clave API, URL base. Pulsa cuando se ejecuta una tarea |
| 8 | 🧬 | **Inteligencia Artificial de Apple** | Configura FoundationModels (IA de Apple en el dispositivo). Lleno cuando está disponible |
| 9 | 🎛️ | **Opciones de Agente** | Temperatura, iteraciones máximas, captura automática de pantalla de visión, estímulo en modo de plan, etc. |
| 10 | 🔄 | **Cadena de Alternancia** | Configura el orden de alternancia del proveedor — Agent! reintentar con el siguiente proveedor cuando uno falla |
| 11 | 🔲 | **HUD** | Alterna la superposición de línea de exploración verde-CRT en la vista de salida de LLM |
| 12 | 📊 | **Uso de LLM** | Seguimiento de uso y costo de tokens por modelo. Verde cuando hay uso registrado |
| 13 | ↩️ | **Reversión** | Navegador de copia de seguridad de archivos de estilo Máquina de Tiempo. Restaura cualquier versión anterior de cualquier archivo que Agent! editó |
| 14 | 🕐 | **Historial** | Indicaciones anteriores, errores y resúmenes de tareas para la pestaña activa. Vuelve a ejecutar una indicación anterior con un clic |
| 15 | 🗑️ | **Borrar Registro** | Elimina el registro de actividad de la pestaña activa (o todo el historial de tareas cuando no se selecciona ninguna pestaña). Confirma primero |

---

### 🎙 Control de Voz — Palabra Clave "Agent!"
**Dictado anclado por palabra clave a través de `SFSpeechRecognizer`.** Haz clic en el micrófono en la barra de entrada para iniciar la sesión de palabra clave, luego di **"Agent!"** seguido de tu tarea. La transcripción es en el dispositivo, se ejecuta en tiempo real y escucha `agent` como una palabra completa (no como una subcadena de "inteligencia" o "gestión"). Lo que digas después de la palabra de despertar se convierte en la tarea — después de ~2.5 segundos de silencio, se ejecuta automáticamente. La sesión se repite automáticamente: cuando una tarea se completa, comienza a escuchar nuevamente. Haz clic en el micrófono para detener.

### 📱 Control Remoto a través de iMessage
Envía un mensaje de texto a tu Mac desde tu iPhone:
```
Agent! ¿Qué canción se está reproduciendo?
Agent! Revisa mi correo
Agent! Siguiente Canción
```
Tu Mac ejecuta la tarea y te devuelve el resultado por mensaje de texto. Solo los contactos aprobados pueden enviar comandos.

### 🌐 Automatización Web
Controla Safari sin intervención — busca Google, haz clic en enlaces, completa formularios, lee páginas, extrae información.

### 📋 Planificación Inteligente
Para tareas complejas, Agent! crea un plan paso a paso, trabaja en cada paso y marca el estado en tiempo real.

### 🗂 Pestañas
Trabaja en múltiples tareas simultáneamente. Cada pestaña tiene su propia carpeta de proyecto e historial de conversación.

### 📸 Captura de Pantalla y Visión
Toma capturas de pantalla o pega imágenes. Los modelos de IA capaces de visión analizan lo que ven — describe contenido, lee texto, detecta problemas de interfaz de usuario.

### 🌐 Automatización Web de Safari (Integrada)

Agent! incluye automatización web de Safari integrada a través de JavaScript y AppleScript. Busca Google, haz clic en enlaces, completa formularios, lee contenido de página y ejecuta JavaScript — todo sin intervención.

**Para habilitar:** Abre Safari → Configuración → Avanzado → marca "Mostrar características para desarrolladores web". Luego ve al menú de Desarrollador → marca "Permitir JavaScript desde Apple Events".

### 🎭 Automatización Web de Playwright (Opcional)

Automatización completa del navegador cruzado a través del [MCP de Playwright de Microsoft](https://github.com/microsoft/playwright-mcp). Haz clic, escribe, captura pantalla y navega por cualquier sitio web en Chrome, Firefox o WebKit — todo controlado por la IA.

**Configuración (una sola vez):**

```bash
# 1. Instala Node.js (si no está ya instalado)
brew install node

# 2. Instala el servidor MCP de Playwright globalmente
npm install -g @playwright/mcp@latest

# 3. Instala los binarios del navegador (elige uno o todos)
npx playwright install chromium          # Chrome (~165MB)
npx playwright install firefox           # Firefox (~97MB)
npx playwright install webkit            # Safari/WebKit (~75MB)
npx playwright install                   # Todos los navegadores
```

**Configura en Agent!:**

Ve a Configuración → Servidores MCP → Agregar Servidor, pega este JSON:

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

> **Nota:** Si `npx` no se encuentra, usa la ruta completa: ejecuta `which npx` en Terminal y reemplaza `"npx"` con el resultado (p. ej. `"/opt/homebrew/bin/npx"`).

Alterna ACTIVADO y las herramientas de Playwright aparecen automáticamente. La IA ahora puede controlar navegadores directamente.

### Herramientas — qué `list_tools` realmente devuelve

Estos son los nombres de herramientas canónicos definidos en `AgentTools.Name.*` y expuestos a cada proveedor de LLM a través de `AgentTools.tools(for:)`. Fuente de la verdad: `~/Documents/GitHub/AgentTools/Sources/AgentTools/AgentTools.swift`. Los alternancias de preferencia del usuario de la aplicación Agent pueden ocultar herramientas individuales por proveedor, pero la lista a continuación es el conjunto completo que el LLM jamás ve.

#### Núcleo / descubrimiento

| Herramienta | Acciones / argumentos | Lo que hace |
|---|---|---|
| **done** | `summary` | Señal tarea completada. Requerido al final de cada tarea |
| **list_tools** | — | Devuelve la lista de herramientas en vivo para el proveedor actual (integrada + MCP) |
| **search** | `query` | Búsqueda web a través de Exa, Tavily o DuckDuckGo (cualquiera que sea la clave configurada) |
| **chat** | `write` / `transform` / `fix` / `about` | Escribe prosa, transforma/arregla texto, describe capacidades de Agent |
| **memory** | `read` / `write` / `append` / `clear` | Preferencias de usuario persistentes. "recuerda X" → `append` |
| **plan** | `create` / `update` / `read` / `list` / `delete` | CRUD de planes múltiples con seguimiento de estado por paso |
| **goal_state** | `set` / `get` / `mark` / `clear` | Objetivo persistente + criterios de éxito; marcar como hecho requiere evidencia |
| **restore_tool_result** | `tool_use_id` | Recuperar el texto completo de un resultado de herramienta truncado por compactación |
| **directory** | `get` / `set` / `home` / `documents` / `library` / `none` / `cd` | Carpeta de proyecto de la pestaña actual |
| **fetch** | `url` | Obtener URL, eliminar HTML, límite de 8K caracteres |
| **skill** | `list` / `invoke` / `save` / `delete` | Plantillas de indicación reutilizables |
| **ask_user** | `question` | Diálogo de usuario a mitad de tarea (espera hasta 5 min) |

#### Código / archivos / compilación

| Herramienta | Acciones / argumentos | Lo que hace |
|---|---|---|
| **file** | `read` / `write` / `edit` / `create` / `apply` / `undo` / `diff_apply` / `list` / `search` / `read_dir` / `mkdir` / `cd` / `if_to_switch` / `extract_function` | Todas las operaciones de archivo. `edit` = reemplazo de cadena única. `diff_apply` = preferido para ediciones de código de varias líneas |
| **git** | `status` / `diff` / `log` / `commit` / `diff_patch` / `branch` / `worktree` | Operaciones de Git — usa esto en lugar de git de shell |
| **xcode** | `build` / `run` / `list_projects` / `select_project` / `add_file` / `remove_file` / `grant_permission` / `analyze` / `snippet` / `code_review` / `get_version` / `bump_version` / `bump_build` | Integración nativa de Xcode. Los errores en el registro de actividad se pueden hacer clic |
| **agent_script** | `list` / `read` / `create` / `update` / `edit` / `run` / `delete` / `combine` / `restore` / `pull` / `list_backups` | Scripts dinámicos Swift en `~/Documents/AgentScript/agents/` con TCC completo |

#### Shell / niveles de privilegio

| Herramienta | Argumentos | Lo que hace |
|---|---|---|
| **user_shell** | `command` | Shell como usuario actual a través de Launch Agent. Herramienta de shell principal |
| **root_shell** | `command` | Shell como ROOT a través de Launch Daemon. Solo tareas de administración — sin sudo |
| **shell** | `command` | Shell en proceso de alternancia (cuando Launch Agent está apagado) |
| **batch** | `commands` | Múltiples comandos de shell en una llamada (separados por saltos de línea) |
| **multi** | `description`, `tasks` | Múltiples llamadas de herramienta en un lote |

#### Automatización de macOS

| Herramienta | Acciones / argumentos | Lo que hace |
|---|---|---|
| **accessibility** | `open_app` / `find_element` / `click_element` / `type_into_element` / `scroll_to_element` / `list_windows` / `inspect_element` / `get_properties` / `perform_action` / `set_properties` / `get_focused_element` / `get_children` / `read_focused` / `wait_for_element` / `wait_adaptive` / `highlight_element` / `manage_app` / `show_menu` / `click_menu_item` / `set_window_frame` / `get_window_frame` / `screenshot` / `check_permission` / `request_permission` / `get_audit_log` | Automatización basada en elementos de AXorcist. Cada acción toma `role`+`title`+`appBundleId` — sin coordenadas |
| **applescript** | `execute` / `lookup_sdef` / `list` / `run` / `save` / `delete` | NSAppleScript en proceso con TCC |
| **javascript** | `execute` / `list` / `run` / `save` / `delete` | JXA (JavaScript para Automatización) |

#### Automatización web

| Herramienta | Acciones / argumentos | Lo que hace |
|---|---|---|
| **safari** | `open` / `find` / `click` / `type` / `execute_js` / `get_url` / `get_title` / `read_content` / `google_search` / `scroll_to` / `select` / `submit` / `navigate` / `list_tabs` / `switch_tab` / `list_windows` / `scan` / `search` | Automatización de Safari a través de JavaScript + AppleScript |
| **selenium** | `start` / `stop` / `navigate` / `find` / `click` / `type` / `execute` / `screenshot` / `wait` | Sesión de Selenium WebDriver — usa `safari` para Safari normal |
| **mcp_playwright_browser_\*** | (consulta MCP de Playwright) | Opcional. Automatización de navegador cruzado a través de MCP de Playwright |

#### Subagenates

| Herramienta | Argumentos | Lo que hace |
|---|---|---|
| **spawn_agent** | `name`, `prompt`, `tools`, `model`, `max_iterations` | Spawn subagenate aislado. 3 concurrentes (hasta 6 solo lectura). Anulación de modelo opcional + resultados basados en archivo |
| **tell_agent** | `to`, `message` | Envía un mensaje al buzón de un subagenate en ejecución |

> 💡 **Nota:** La aplicación en el dispositivo filtra esta lista por proveedor — alterna herramientas individuales en el popover **Herramientas** (botón #6 en la barra de herramientas anterior). La Inteligencia Artificial de Apple tiene su propio conjunto predeterminado mínimo debido a su pequeña ventana de contexto. Las herramientas de MCP se añaden en tiempo de ejecución como `mcp_<server>_<tool>` y se enumeran en "--- Herramientas MCP ---" por `list_tools`.

## Privacidad y Seguridad

- **Tus datos permanecen en tu Mac.** Los archivos, contenidos de pantalla y datos personales nunca se cargan.
- **La IA en la nube solo ve tu texto de indicación.** Usa IA local para permanecer 100% sin conexión.
- **Tú tienes el control.** Agent! muestra todo lo que hace y registra cada acción.
- **Construido en el modelo de seguridad de Apple.** Los permisos de macOS protegen tu sistema.

### Capas de Defensa

| Capa | Lo que hace |
|---|---|
| **Servicio de Seguridad de Shell** | Bloquea duramente comandos catastróficos (`rm -rf /`, `rm -rf ~`, `dd` a `/dev/disk`, fork bombs, `--no-preserve-root`) antes de que el Proceso sea construido. No puede ser eludido por el LLM. |
| **Enrutamiento TCC en Proceso** | Detector de 17 palabras clave encamina AppleScript, osascript, JXA, screencapture, accesibilidad, Atajos y comandos de ScriptingBridge para ejecutarse en proceso donde Agent! tiene subvenciones de TCC — nunca a través de Launch Agent/Daemon (IDs de paquete separados = sin TCC). |
| **Copia de Seguridad de Archivo en Cada Edición** | `FileBackupService` captura automáticamente cada archivo antes de `write_file`, `edit_file` y `diff_apply`. Recuperable a través de `file(action:"restore")` o la UI de Reversión. TTL de 1 semana. |
| **.Trash de Script de Agente** | `delete_agent` copia el script a `~/Documents/AgentScript/agents/.Trash/` antes de la eliminación. Recuperable a través de `agent_script(action:"restore")`. |
| **Normalización del Directorio de Trabajo** | Cada ruta de ejecución de shell (`executeTCC`, `UserService`, `HelperService`) normaliza el directorio de trabajo — si una ruta de archivo se pasa accidentalmente como cwd, la elimina al directorio principal en lugar de fallar con "No es un directorio". |
| **Drenaje de Tarea Antes de Iniciar** | Iniciar una nueva tarea espera la terminación completa de la tarea anterior — previene bucles de reintento huérfanos de mezclar salida de registro entre proveedores. |
| **Cadena de Alternancia** | Cuando el LLM principal falla (429, tiempo de espera, red), Agent! cambia automáticamente al siguiente proveedor en la cadena configurada por el usuario después de 2 fallos. |
| **Errores Accionables** | Cada error de herramienta incluye una sugerencia de `Recovery:` que le dice al LLM exactamente qué intentar a continuación — sin mensajes de error sin salida que desperdician turnos. |
| **Invalidación de Caché de Lectura** | El caché de lectura de archivo se invalida tanto en ediciones exitosas como fallidas, por lo que el LLM siempre obtiene contenido fresco en la próxima lectura. |
| **Búsqueda de Nombre Base** | Cuando `read_file` o `edit_file` obtiene una ruta incorrecta, Agent! busca en directorios cercanos archivos con el mismo nombre y devuelve las rutas correctas en línea — el LLM se autocorrige en un turno. |
| **Puerta de Ejecución de Herramienta** | El LLM no puede fabricar resultados de herramientas. Todas las llamadas de herramienta fluyen a través de la `dispatchTool()` de la aplicación → ejecución real (XPC, shell, en proceso) → salida real devuelta como `tool_result`. El LLM solo ve y resume salidas que realmente sucedieron. Si una herramienta falla, el error real se devuelve — el LLM no puede afirmar éxito sin un evento de ejecución coincidente. |
| **action_not_performed** | Defensa de dos capas contra reclamaciones de falsa acción: **(1) Indicación** — la indicación del sistema instruye al LLM para decir "acción no realizada" si no se realizó ninguna llamada de herramienta. **(2) Aplicación** — si el LLM devuelve texto alegando "busqué/abrí/hice clic" pero hizo cero llamadas de herramienta ese turno, se inyecta una corrección obligándolo a usar la herramienta real. |

---

## Atajos de Teclado

Fuente de la verdad: el TextField `.onSubmit` en `Agent/Views/InputSectionView.swift` para `Return`, y el bloque `NSEvent.addLocalMonitorForEvents` en línea en `Agent/Views/ContentView.swift` para todo lo demás.

| Atajo | Acción |
|---|---|
| `Return` | Ejecuta tarea actual (envío de TextField — sin modificador requerido) |
| `⌘ .` / `Escape` | Cancelar tarea en ejecución |
| `⌘ B` | Alternar superposición de salida de LLM (mostrar/ocultar) |
| `⌘ D` | Alternar ambos chevrones de LLM en la pestaña actual (expandir/contraer) |
| `⌘ T` | Nueva pestaña |
| `⌘ W` | Cerrar pestaña actual (o salir si no hay pestañas) |
| `⌘ 1`–`⌘ 9` | Cambiar pestaña. `⌘1` es la pestaña principal; `⌘2`–`⌘9` son pestañas de script |
| `⌘ Shift ←` / `⌘ Shift →` | Pestaña anterior / siguiente |
| `⌘ F` | Alternar barra de búsqueda de registro de actividad |
| `⌘ L` | Borrar registro de la pestaña activa |
| `⌘ V` | Pegar imagen del portapapeles |
| `↑` / `↓` | Historial de indicaciones (en el campo de entrada) |
| `⌘ Shift M` | Alternar Monitor de Mensajes activado/desactivado |
| `⌘ Shift P` | Abrir Configuración (el editor de indicación del sistema vive aquí) |
| `⌘ Shift K` | Borrar todo (reinicio completo) |
| `⌘ Shift L` | Borrar solo panel de salida de LLM |
| `⌘ Shift H` | Borrar historial de indicaciones |
| `⌘ Shift J` | Borrar historial de tareas |
| `⌘ Shift U` | Borrar contadores de tokens |

## Comandos de Barra

Escribe estos en el campo de entrada y presiona Return — se ejecutan localmente sin ir a ningún LLM. Fuente de la verdad: `AgentViewModel+RunStop.swift`.

| Comando | Acción |
|---|---|
| `/clear` o `/clear log` | Borrar el registro de actividad de la pestaña actual |
| `/clear all` | Borrar todo (registro, salida de LLM, historial de indicaciones, historial de tareas, tokens) |
| `/clear llm` | Borrar solo el panel de salida de LLM |
| `/clear history` | Borrar historial de indicaciones |
| `/clear tasks` | Borrar historial de tareas |
| `/clear tokens` | Restablecer contadores de tokens (tarea + sesión) |
| `/memory` o `/memory show` | Imprimir el contenido del archivo de memoria actual en el registro de actividad |
| `/memory clear` | Borrar memoria |
| `/memory edit` | Abre `~/Documents/AgentScript/memory.md` en el editor predeterminado del sistema |
| `/memory <text>` | Añade `<text>` a la memoria (cualquier cosa después de `/memory` se convierte en la nueva línea) |

---

## Preguntas Frecuentes

**¿Necesito saber cómo codificar?** No. Solo escribe lo que quieres en inglés simple.

**¿Es seguro?** Sí. Automatización estándar de macOS, registro completo de actividad, apruebas permisos.

**¿Cuánto cuesta?** La aplicación Agent! en sí es gratuita (Licencia MIT). Los proveedores de IA en la nube cobran por el uso de API — las opciones más económicas para trabajo serio son GLM-5/5.1 a través de Z.ai, BigModel o Hugging Face (centavos por millón de tokens), o DeepSeek para codificación presupuestaria. Los modelos locales autohosped (Ollama, vLLM, LM Studio) no tienen tarifas de API pero solo tienen sentido si ya posees el hardware para ejecutarlos — consulta la nota de hardware a continuación.

**¿Qué Mac necesito?** macOS 26.4.1. Se requiere Apple Silicon. Para proveedores de nube, cualquier Mac moderno funciona bien. Para modelos locales autohosped (Ollama, vLLM, LM Studio): un modelo de 7B cabe en 16GB de memoria unificada, un modelo de 13B en 24GB, un modelo de 30B necesita 64GB+ (territorio de Mac Studio Ultra M2/M3/M4). La Inteligencia Artificial de Apple (el mediador en el dispositivo para clasificación / compresión de tokens) necesita una Mac con Apple Silicon con Inteligencia Artificial de Apple habilitada en Configuración del Sistema.

**¿Cómo es diferente de Siri?** Siri responde preguntas. Agent! *realiza acciones* — controla aplicaciones, gestiona archivos, compila código, automatiza flujos de trabajo.

---

## Documentación

- [Arquitectura Técnica](docs/TECHNICAL.md) — Herramientas, secuencias de comandos, detalles de desarrollador
- [Comparaciones](docs/COMPARISON.md) — vs Claude Code, Cursor, Cline, OpenClaw
- [Modelo de Seguridad](docs/SECURITY.md) — Arquitectura XPC, separación de privilegios
- [Preguntas Frecuentes](docs/FAQ.md) — Preguntas Comunes

---

## Herramientas Xcode Integradas

Agent! incluye integración nativa de Xcode que funciona sin configuración de servidor MCP. Estas herramientas integradas son a menudo más rápidas y confiables que la alternativa de MCP ya que se ejecutan directamente dentro de la aplicación.

| Herramienta | Lo que hace |
|---|---|
| **xcode build** | Compila el proyecto de Xcode actual, captura errores y advertencias. Los errores en el registro de actividad son **hacibles en clic** y se abren directamente en Xcode. |
| **xcode run** | Compila y ejecuta la aplicación |
| **xcode list_projects** | Descubre espacios de trabajo y proyectos abiertos de Xcode |
| **xcode select_project** | Cambiar el proyecto activo |
| **xcode grant_permission** | Otorga acceso de archivo a la carpeta del proyecto Xcode |
| **xcode get_version** | Lee la versión de marketing actual y el número de compilación del proyecto Xcode |
| **xcode bump_version** | Aumenta la versión de marketing (principal, menor o parche), actualiza el número de compilación, compila para verificar y confirma automáticamente |
| **xcode bump_build** | Incrementa solo el número de compilación |

Solo di *"aumentar versión"* y Agent! lee la versión actual, pregunta principal/menor/parche, actualiza Info.plist y configuración de proyecto, compila para verificar y confirma el cambio. Sin edición manual de plist, sin números de compilación perdidos.

La IA usa automáticamente estos cuando pides que compile, arregle errores o trabaje con proyectos de Xcode. No se requiere configuración — solo ten tu proyecto abierto en Xcode.

> 🚀 **Soporte para iOS/iPadOS:** ¡Pronto! El soporte nativo para compilar, ejecutar y probar aplicaciones de iOS e iPadOS directamente desde Agent! está en desarrollo.

> **Consejo:** Para la mayoría de flujos de trabajo de codificación, las herramientas integradas son todo lo que necesitas. El servidor Xcode de MCP a continuación agrega extras como renderizado de Vista Previa de SwiftUI y búsqueda de documentación.

---

<img width="1349" height="1438" alt="Screenshot 2026-04-02 at 12 00 03 PM" src="https://github.com/user-attachments/assets/b0d9346e-f807-4089-bab3-29c7058868d8" />

## Dos formas de hablar con Agent! — voz e iMessage

Ambas características utilizan la misma palabra clave de despertar: **"Agent!"** (sin importar mayúsculas — `Agent!`, `agent!`, `AGENT!`, incluso solo `Agent ` o `agent ` funcionan).

### 🎤 Voz (dictado de palabra clave)

Haz clic en el micrófono en la barra de entrada e inicia la sesión de palabra clave, luego habla. Agent! transcribe en tiempo real usando `SFSpeechRecognizer` y escucha la palabra "agent" como una palabra completa (no como una subcadena de "inteligencia" o "gestión"). Lo que digas después de "agent" se convierte en la tarea. Después de ~2.5 segundos de silencio, la tarea se ejecuta automáticamente.

Ejemplos:
- *"Agent, ¿qué canción se está reproduciendo?"*
- *"Agent toma una captura de pantalla de Safari"*
- *"Agent compila el proyecto de Xcode"*

La sesión de palabra clave se repite automáticamente — después de que una tarea se completa, vuelve a escuchar. Haz clic en el micrófono nuevamente para detener.

### 📱 iMessage (control remoto)

Envía un mensaje de texto a tu Mac desde tu iPhone. Agent! sondea `~/Library/Messages/chat.db` cada 5 segundos para nuevos mensajes y reacciona a cualquier cosa que comience con **`Agent!`** (sin importar mayúsculas, signo de exclamación opcional).

Ejemplos:
```
Agent! ¿Qué canción se está reproduciendo?
agent! revisa mi correo
AGENT! siguiente canción
Agent  abre Safari
```

Agent! envía un reconocimiento inmediato "Trabajando en ello...", ejecuta la tarea en una pestaña de Mensajes dedicada usando la configuración de LLM de tu pestaña principal, y luego te devuelve el resultado por mensaje de texto.

**Configuración (una sola vez):**

1. **Otorga Acceso de Disco Completo** — Configuración del Sistema → Privacidad y Seguridad → Acceso de Disco Completo → habilitar Agent! (requerido para leer `chat.db` directamente a través de SQLite)
2. **Abre el Monitor de Mensajes** — botón de barra de herramientas #2 (icono de burbuja de chat, se vuelve verde cuando está activado)
3. **Aprueba un remitente** — una vez que llega un mensaje de un nuevo contacto, ese contacto aparece en la lista de destinatarios. Alternadlo para aprobar.

Solo los remitentes aprobados pueden ejecutar tareas. Los mensajes no aprobados se registran pero se ignoran. Tu respuesta se devuelve a través de AppleScript al mismo identificador que envió el comando, limitado a 4000 caracteres.

Las respuestas salientes tienen cualquier "Agent!" inicial eliminado para que la Mac receptora no active su propio bucle de comando.

---

Agent! admite servidores [MCP](https://modelcontextprotocol.io) para capacidades extendidas. Configura en Configuración → Servidores MCP.

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

**El MCP de Xcode proporciona:**
- Operaciones de archivo conscientes del proyecto (lectura/escritura/edición/eliminación)
- Integración de compilación y pruebas
- Renderizado de vista previa de SwiftUI
- Ejecución de fragmentos de código
- Búsqueda de documentación de desarrollador de Apple
- Seguimiento de problemas en tiempo real

---

## Licencia

MIT — libre y de código abierto.

---

<div align="center">

### **Agent! para macOS 26.4.1 - IA Agéntica para tu Mac**
> Nota: Claude se refiere al modelo de IA de Anthropic integrado en Agent! para la funcionalidad de LLM. No es un colaborador humano de Agent!
</div>

---

## Agent! vs Claude Code — Comparación Arquitectónica

Agent! es una aplicación Swift macOS 100% original pura. No es un puerto, bifurcación o derivado de ningún otro proyecto.

| | Claude Code | Agent! |
|---|---|---|
| **Lenguaje** | TypeScript/JavaScript | Swift 6.2 Puro |
| **Marco de Interfaz de Usuario** | Ink (React de terminal) | SwiftUI (macOS nativa) |
| **Plataforma** | CLI — Linux, macOS, Windows | Solo macOS 26.4.1 nativo |
| **Tiempo de Ejecución** | Node.js/Bun | Binario compilado nativo |
| **Arquitectura** | REPL de Terminal con transmisión | Aplicación de escritorio con daemons XPC |
| **Accesibilidad** | Ninguna (CLI) | AX completo de macOS a través de AXorcist (25 acciones de nivel superior, 30+ subtipos AX a través de `perform_action`) |
| **AppleScript** | Ninguno | NSAppleScript + JXA en proceso completo con TCC |
| **Integración de Xcode** | A través de Bash (`xcodebuild`) | Nativa (compilación/ejecución/análisis/snippet/agregar_archivo/versión_bump/revisión_código — 13 acciones) |
| **Inteligencia Artificial de Apple** | Ninguna | FoundationModels en el dispositivo — maneja clasificación de saludo/charla pequeña, resúmenes de tareas, explicaciones de errores y compresión de tokens de Nivel 1. La automatización de UI es manejada por el LLM principal a través de la herramienta `accessibility`, no por Apple AI |
| **ScriptingBridge** | Ninguno | SDEF + 51 puentes de eventos completos (Finder, Mail, Música, Safari, Calendario, etc.) |
| **Visión** | Entrada de imagen a través de API | Entrada de imagen a través de API |
| **Auto-capturas** | Ninguna (sin UI) | Verificación automática opcional después de acciones de UI (predeterminado DESACTIVADO — consulta `visionAutoScreenshotEnabled`) |
| **iMessage** | Ninguno | Agente remoto a través de Mensajes (se requiere Acceso de Disco Completo para `chat.db`) |
| **Voz** | Ninguna | Dictado anclado por palabra clave a través de SFSpeechRecognizer |
| **Efecto CRT** | Ninguno | Superposición de línea de exploración de lienzo SwiftUI opcional (alternar a través del botón HUD) |
| **Modelo de Privilegio** | Arenero de usuario | Launch Agent XPC (usuario) + Launch Daemon (root) |
| **Subagenates** | Herramienta de tarea (documentada públicamente; detalles de implementación no establecidos por Anthropic) | Hasta 3 concurrentes (6 solo lectura) subagenates aislados con mensajería de buzón y anulación de modelo por agente |
| **MCP** | stdio/SSE de Node.js | Paquete AgentMCP Swift |
| **Scripts** | Ninguno | Compilación de dylib Swift en tiempo de ejecución, dlopen'd en proceso con TCC completo |
| **Almacenamiento en caché de indicador** | Anthropic `cache_control` efímero | Anthropic `cache_control` efímero + seguimiento automático de tasa de acierto de caché de prefijo para OpenAI/Z.ai/Grok/Mistral/Gemini/Qwen/DeepSeek; Ollama `keep_alive: 30m` |
| **Compactación de Contexto** | Claude en la nube (tokens pagados; conversación reenviada a Anthropic) | Escalonado: Nivel 1 = resumen de Inteligencia Artificial de Apple en el dispositivo (gratuito, privado, sin tokens de API). Nivel 2 = poda agresiva si Apple AI no está disponible. Escala de umbral a la ventana de contexto del modelo (~55%, 2K–400K), resúmenes memoizados, cortacircuito de 3 fallos, resultados de herramientas completas vertidos al disco antes del truncamiento |

## Agent! vs Cursor — Comparación Rápida

Cursor es un excelente editor de código de IA. Agent! juega un juego diferente: es un agente para tu **Mac completo**, no solo tu base de código.

| | Cursor | Agent! |
|---|---|---|
| **Lo que es** | Editor de código de IA (bifurcación VS Code, Electron) | Aplicación agente macOS SwiftUI nativa |
| **Alcance** | Tu base de código | Tu Mac completo — código, aplicaciones, archivos, sistema |
| **Precios** | Suscripción | Gratuito y de código abierto (MIT) — trae tu propia clave API o ejecuta local |
| **Modelos locales** | Primero en la nube | Ollama, vLLM, LM Studio, Inteligencia Artificial de Apple en el dispositivo |
| **Automatización de aplicaciones Mac** | Ninguna | API de Accesibilidad, AppleScript/JXA, ScriptingBridge (51 puentes de aplicación) |
| **Tareas administrativas a nivel raíz** | Ninguna | Daemon de Lanzamiento Privilegiado a través de XPC (aprobado una vez) |
| **Control por voz / iMessage** | Ninguno | Dictado de palabra clave + agente remoto a través de Mensajes |
| **Integración de Xcode** | Terminal `xcodebuild` | Herramientas nativas de compilación/ejecución/análisis/revisión de código |
| **Telemetría** | Cuenta en la nube requerida | Ninguna — tus claves, tu máquina, tus datos |

Si vives dentro de un repo todo el día, Cursor es genial. Si quieres un agente que también compile tu proyecto de Xcode, controle Safari, te envíe resultados por mensaje de texto e instale software como root — eso es Agent!.

## Contribuyendo

¿Quieres hackear en Agent!? Consulta [CONTRIBUTING.md](./CONTRIBUTING.md) — puedes compilar desde la fuente en aproximadamente 5 minutos con solo las Herramientas de Línea de Comandos de Xcode (`./build.sh`), sin requerir cuenta de desarrollador de Apple. Consulta los [problemas buenos para principiantes](https://github.com/macOS26/Agent/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) para tareas de inicio delimitadas.

---

> ⚠️ **Aviso Legal y Atribución**
>
> ### Aviso de Marca Registrada
>
> "🦾 Agent! para macOS26" es un proyecto de software independiente y **no** está afiliado con, respaldado por, patrocinado por, o de otra manera asociado con Apple Inc. "Apple," "Mac," "Mac mini," "MacBook," "macOS," y marcas relacionadas son marcas registradas de Apple Inc., registradas en los EE.UU. y otros países. Todas las otras marcas comerciales, marcas de servicio y nombres comerciales referenciados aquí son propiedad de sus respectivos dueños y se utilizan solo para fines de identificación.
>
> "🦾 Agent!" y el logotipo de 🦾 Agent! son marcas registradas de Todd Bruss. El uso de estas marcas requiere permiso previo por escrito. La licencia MIT a continuación otorga derechos al código fuente solamente — **no** otorga derechos de marca comercial.
>
> ### Licencia de Código Fuente (MIT)
>
> El código fuente de "🦾 Agent! para macOS26" es de código abierto y está licenciado bajo la **Licencia MIT**. Eres libre de usar, copiar, modificar, fusionar, publicar, distribuir, sublicenciar y/o vender copias del código fuente, sujeto a las condiciones en el archivo [LICENSE](./LICENSE) (retener noticia de derechos de autor y la noticia de permiso MIT en todas las copias o porciones sustanciales del software).
>
> ### Binarios Compilados y Lanzamientos
>
> Los binarios compilados, instaladores, compilaciones de código firmado y artefactos de lanzamiento distribuidos a través de la sección de Lanzamientos de GitHub de este proyecto, [agent.macOS26.app](https://agent.macOS26.app), o cualquier otro canal oficial son obras protegidas por derechos de autor de Todd Bruss y **no** están cubiertas por la licencia MIT que rige el código fuente. Todos los derechos a los binarios oficiales — incluidos el nombre "🦾 Agent!", logotipo, identidad de firma de código y ID de Desarrollador — están reservados.
>
> Derechos de autor © 2000, 2023–2026 Todd Bruss, Todos los Derechos Reservados.
>
> Eres bienvenido a construir tus propios binarios desde la fuente bajo la licencia MIT, siempre que no uses el nombre "🦾 Agent!", logotipo o marca de Agent! para identificar tu producto.
>
> ### Exención de Garantía
>
> Este software se proporciona **"TAL CUAL,"** sin garantía de ningún tipo, expresada o implícita, incluyendo pero no limitado a las garantías de comerciabilidad, idoneidad para un propósito particular e incumplimiento de patentes. En ningún caso el autor o el titular de los derechos serán responsables por ninguna reclamación, daños u otra responsabilidad, ya sea en una acción de contrato, agravio o de otra manera, que surja de, surja de, o se relacione con el software o el uso o otros tratos con el software.
>
> ---
>
> Gracias por tu interés en 🦾 Agent! — una aplicación creada para Mac mini, MacBook y computadoras de escritorio Mac que ejecutan macOS 26.4 o posterior en hardware y software Mac auténtico.
>
> Cordialmente,
> **Todd Bruss**
> Ingeniero Desplegado hacia Adelante, 🦾 Agent! para macOS 26.4.1
> https://agent.macOS26.app
> https://github.com/macos26/agent

- Tus archivos y datos permanecen en tu equipo.
- Solo se envían los textos de tus prompts a los proveedores de IA en la nube.
- Puedes ver exactamente qué hizo Agent! en el registro de actividades.
- El sistema usa permisos de macOS y validaciones de seguridad antes de ejecutar tareas sensibles.

## Preguntas frecuentes

### ¿Necesito saber programar?
No. Puedes describir lo que quieres en inglés o en tu idioma natural.

### ¿Es seguro?
Sí. Agent! ofrece registro de actividades, permisos de macOS, validación de acciones críticas y control de tareas privilegiadas.

### ¿Cuánto cuesta?
La app es gratuita y de código abierto. Los modelos de IA en la nube tienen costos según el proveedor, pero también puedes usar modelos locales.

### ¿Qué Mac necesito?
macOS 26.4.1 o posterior y hardware Apple Silicon. Para modelos locales, la cantidad de memoria y rendimiento dependerá del tamaño del modelo.

## Documentación

- [Technical Architecture](docs/TECHNICAL.md)
- [Comparisons](docs/COMPARISON.md)
- [Security Model](docs/SECURITY.md)
- [FAQ](docs/FAQ.md)

## Licencia

MIT - código abierto y gratuito.

---

“Agent!” es una herramienta para automatizar tu escritorio Mac de forma inteligente y segura. Puedes usarla para codificar, automatizar, navegar, trabajar con archivos y controlar acciones del sistema con IA.
