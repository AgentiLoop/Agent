# 🦾 AgentiLoop Agent!

### **IA agentique pour votre bureau Mac**

[![Latest Release](https://img.shields.io/github/v/release/AgentiLoop/Agent?label=Download&color=blue&style=for-the-badge)](https://github.com/AgentiLoop/Agent/releases/latest)
[![GitHub Stars](https://img.shields.io/github/stars/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Stars&color=gold)](https://github.com/AgentiLoop/Agent/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Forks&color=white)](https://github.com/AgentiLoop/Agent/fork)
[![macOS 26.4+](https://img.shields.io/badge/macOS-26.4.1-green?style=for-the-badge)](https://github.com/apple)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange?style=for-the-badge)](https://www.swift.org)
<a href="https://www.paypal.com/ncp/payment/9C6RY2UAE5M3S"><img src="https://img.shields.io/badge/Donation-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Tip Jar" /></a>

## Traductions du README

- [English](README.md)
- [Español](README_es.md)
- [Français](README_fr.md)
- [Deutsch](README_de.md)
- [中文 (简体)](README_zh.md)

## Les échecs dans Agent
<img width="1176" height="724" alt="Screenshot 2026-08-23 at 7 34 10 PM" src="https://github.com/user-attachments/assets/d3b2f1e5-1dab-44f7-95f6-008424ee794c" />

## Qu'est-ce qu'Agent! ?

**Une app. N'importe quelle IA. Le contrôle total de votre Mac.**

Agent! est une app 100 % native Swift 6.2 / SwiftUI qui relie **18 fournisseurs de LLM** — Claude, GPT, Gemini, Grok, Mistral, DeepSeek, Qwen, Z.ai, BigModel, Hugging Face, OpenRouter, Ollama (cloud et local), vLLM, LM Studio, Codestral, Mistral Vibe et **Apple Intelligence** sur l'appareil — à une boucle de tâches autonome qui *agit vraiment* : elle lit votre code, corrige le bug, compile le projet Xcode, committe le diff, pilote n'importe quelle app Mac via l'API d'Accessibilité, exécute des commandes shell en votre nom ou en root, vous envoie les résultats par iMessage et répond à un *« Agent! »* prononcé à voix haute.

Pas de NPM, pas d'Electron, pas d'abonnement, pas de télémétrie. Apportez votre propre clé API, tournez entièrement en local, ou gratuitement avec Apple Intelligence. Chaque package Swift dont l'app dépend a été écrit par le même auteur. Voir l'[Histoire](#histoire) ci-dessous.

## Nouveautés 🚀

**v1.1.x — La version Hardened Harness** · [Releases →](https://github.com/AgentiLoop/Agent/releases/latest)

- **Compactage du contexte, reconstruit.** Seuil = fenêtre du modèle − sortie réservée − marge, piloté par les vrais `input_tokens`. Un résumé LLM en 9 sections côté fournisseur remplace les résumés 4K sur l'appareil ; l'objectif ouvert, la checklist du plan et les fichiers modifiés sont rattachés après chaque compactage. Les résultats d'outils trop volumineux sont écrits sur disque dès leur émission et récupérables via `restore_tool_result`. Les dépassements 413 passent par un compactage forcé avec une requête plus courte ; les dépassements de `max_tokens` se rétablissent par escalade, puis continuation.
- **Garde read-before-edit.** `edit_file` / `apply_diff` / `diff_apply` refusent de toucher un fichier que le LLM n'a pas lu dans cette tâche, ou qui a changé sur le disque depuis la dernière lecture (SHA-256). Le refus lit automatiquement le fichier pour que l'appel suivant soit la modification. Les changements externes de fichiers sont affichés à chaque tour sous forme d'extraits de diff.
- **Vraies fenêtres de contexte pour les modèles locaux.** LM Studio, Ollama et vLLM rapportent leur longueur de contexte réelle par modèle — fini l'hypothèse fixe de 32K.
- **Tours plus rapides.** Les outils en lecture seule démarrent pendant que la réponse de Claude est encore en streaming ; concurrence shell tenant compte des entrées ; nouvelle tentative exponentielle avec jitter et `Retry-After` sur 429/529 ; erreurs en cours de flux SSE remontées pour chaque fournisseur.
- **Défense en profondeur.** `ShellSafetyService` est désormais appliqué côté daemon (AgentHelper + AgentUser) en plus du client ; les builds release rejettent les clients XPC sans équipe ; les deux listeners XPC exigent une signature de code de la même équipe, dérivée de la propre signature de l'app.
- **Journal d'activité.** Plus de troncature à 50K ni de coupe à 500K au relancement — les gros journaux sont rendus hors du thread principal avec une superposition « Processing tab data… » ; disposition optionnelle « Activity Log Below HUD ».
- **Menu de l'app :** Rechercher des mises à jour… (releases GitHub), Site web, GitHub. Workflow CI Build & Test sur chaque PR ; **273 tests réussis**.
- Et aussi : `goal_state` avec critères vérifiés par des preuves, revue critique optionnelle du diff avant la fin, `rewind_task` par tâche, réflexion étendue pour Claude, transmission de `reasoning_effort`, sous-agents avec modèle propre par agent (3 simultanés, 6 en lecture seule), erreurs d'outils typées avec indices de récupération, hooks d'événements.

## Démarrage rapide (Téléchargement)

1. **Téléchargez** [Agent!](https://github.com/AgentiLoop/Agent/releases/latest) et glissez-le dans Applications
2. **Ouvrez Agent!** — tout se configure automatiquement
3. **Choisissez votre IA** — Réglages → choisissez un fournisseur → saisissez la clé API

## Démarrage rapide (Compiler depuis les sources)

```bash
git clone https://github.com/AgentiLoop/agent.git
cd Agent
```

**Option A — Xcode (compte Apple Developer) :** ouvrez `Agent.xcodeproj`, définissez votre Development Team, compilez et lancez la cible `Agent`, approuvez le helper quand on vous le demande.

**Option B — sans compte développeur (Xcode Command Line Tools uniquement) :**
```bash
./build.sh              # Debug
./build.sh Release      # Release
open "build/DerivedData/Build/Products/Debug/Agent!.app"
```

> ⚠️ Les builds de l'Option B sont signés ad hoc. Les helpers Launch Agent/Daemon ne s'enregistreront pas (SMAppService exige un Team ID), mais la boucle LLM, tous les outils, l'Accessibilité, AppleScript, le shell et MCP fonctionnent quand même.

> 💡 **Configuration économique :** **GLM-5.1** via **Z.ai** (inscription la plus rapide, modèle par défaut) coûte quelques centimes par million de tokens. En local ? Seul **GLM-4.7-Turbo** (32B) tient sur du matériel grand public (Apple Silicon 64–128 Go via Ollama).

### Dépannage (Compiler depuis les sources)

- **`xcode-select` pointe vers les Command Line Tools** → `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- **`BUILD FAILED` étrange après un pull** → DerivedData obsolète : `./build.sh clean && ./build.sh`
- **Les helpers ne s'enregistrent jamais** → attendu en Option B ; utilisez l'Option A pour les helpers
- **Erreurs de deployment target / SDK** → Agent! cible macOS 26 ; mettez à jour macOS et Xcode
- **L'argument de configuration est sensible à la casse** → `./build.sh` (Debug) ou `./build.sh Release`

## Que peut-il faire ?

> *« Compile le projet Xcode et corrige les erreurs »* · *« Lance ma playlist Workout dans Musique »* · *« Prends une photo avec Photo Booth »* · *« Envoie un iMessage à maman pour dire que je rentre à 18 h »* · *« Ouvre Safari et cherche des vols pour Tokyo »* · *« Refactorise cette classe en fichiers plus petits »* · *« Quels événements ai-je aujourd'hui dans le calendrier ? »*

Tapez simplement ce que vous voulez. Agent! trouve comment et le réalise.

---

## Fonctionnalités clés

- **🧠 Boucle de tâches auto-vérifiée** — raisonne, exécute, observe les résultats, se corrige. Une tâche ne peut pas se déclarer terminée tant que les critères de `goal_state` ne sont pas validés avec des preuves ; un critique optionnel relit d'abord le diff.
- **🛠 Codage agentique** — lit les bases de code, modifie via des diffs de remplacement de chaînes, compile les projets Xcode nativement (erreurs cliquables), gère git, indexe les dépôts en une carte JSONL portable. Chaque modification est sauvegardée — rollback en un clic ou `rewind_task` de toute la tâche.
- **🖥 Automatisation du bureau** — pilote n'importe quelle app Mac via l'API d'Accessibilité ([AXorcist](https://github.com/steipete/AXorcist)), basée sur les éléments avec nouvelle tentative floue automatique. Plus NSAppleScript, JXA et 51 ponts ScriptingBridge, le tout en processus avec TCC.
- **📜 AgentScript** — dylibs Swift compilées à l'exécution et chargées via `dlopen` en processus avec TCC complet. Les scripts supprimés vont dans `.Trash` et sont restaurables.
- **🛡 Exécution privilégiée** — shell en votre nom via un Launch Agent, ou en root via un Launch Daemon que vous approuvez une seule fois (SMAppService + XPC). Voir [docs/SECURITY.md](docs/SECURITY.md) pour comprendre pourquoi SMAppService impose déjà l'identité de signature.
- **🎙 Voix** — dites **« Agent! »** suivi de votre tâche ; `SFSpeechRecognizer` sur l'appareil, lancement automatique après ~2,5 s de silence, en boucle.
- **📱 Télécommande iMessage** — envoyez `Agent! next song` depuis votre iPhone ; expéditeurs approuvés uniquement. Nécessite l'Accès complet au disque pour `chat.db`.
- **🌐 Web** — automatisation Safari intégrée (JavaScript + AppleScript) ; Selenium et [Playwright MCP](https://github.com/microsoft/playwright-mcp) optionnels pour le multi-navigateur.
- **🤝 Sous-agents** — jusqu'à 3 simultanés (6 en lecture seule) agents isolés avec messagerie par boîte aux lettres et modèle propre par agent.
- **🧩 MCP** — ajoutez n'importe quel serveur MCP dans Réglages → Serveurs MCP ; les outils apparaissent comme `mcp_<server>_<tool>`. Xcode MCP : `{"mcpServers":{"xcode":{"command":"xcrun","args":["mcpbridge"],"transport":"stdio"}}}`.
- **🗂 Onglets, historique, mémoire, plans, skills** — chaque onglet a son propre dossier de projet et son journal ; mémoire utilisateur persistante ; checklists multi-plans dans chaque prompt.
- **🔄 Chaîne de repli** — bascule automatique vers le fournisseur suivant configuré en cas de 429/timeout/panne réseau.

## 🤖 18 fournisseurs d'IA

| Fournisseur | Coût | Idéal pour |
|---|---|---|
| **Claude** | Payant | Longues tâches autonomes, réflexion étendue, cache de prompts |
| **OpenAI** | Payant | Usage général, appels d'outils, vision, `reasoning_effort` |
| **Google Gemini** | Payant (offre gratuite) | Contexte long, vision |
| **Grok** (xAI) | Payant | Infos en temps réel |
| **Mistral** / **Codestral** / **Mistral Vibe** | Payant | Cloud open-weight, code, produit agent |
| **DeepSeek** | Bon marché | Codage économique, rapport de hits de cache |
| **Hugging Face** | Variable | Modèles ouverts, serverless ou endpoints dédiés |
| **OpenRouter** | Payant | 200+ modèles, une clé ; Claude routé via le protocole Anthropic |
| **Z.ai** / **BigModel** | Bon marché | GLM-5.1 — point de départ recommandé |
| **Qwen** (Alibaba) | Bon marché | Qwen 2.5 / 3 via Dashscope |
| **Ollama** (cloud) | Offre gratuite | Modèles ouverts hébergés |
| **Ollama local** / **vLLM** / **LM Studio** | Gratuit + matériel | Entièrement hors ligne ; vraie fenêtre de contexte par modèle détectée |
| **Apple Intelligence** | Gratuit, sur l'appareil | Triage, résumés, compression de tokens (icône cerveau, pas le sélecteur de fournisseur) |

> 💡 Les fournisseurs auto-hébergés ne sont gratuits qu'au sens des frais d'API — un modèle 30B+ utilisable exige un Mac Studio M2/M3/M4 Ultra (64–128 Go). Sans ce matériel, les voies cloud bon marché ci-dessus reviennent bien moins cher.

## Outils

Les noms canoniques viennent de `AgentTools.Name.*` (source : le package [AgentTools](https://github.com/AgentiLoop/AgentTools)). Les interrupteurs par fournisseur permettent de masquer des outils individuels.

| Groupe | Outils |
|---|---|
| **Core** | `done` · `list_tools` · `search` · `web_search` · `fetch` · `chat` · `memory` · `plan` · `goal_state` · `restore_tool_result` · `directory` · `skill` · `ask_user` · `index` |
| **Code / build** | `file` (read/write/edit/diff_apply/undo/list/search/mkdir/…) · `git` · `xcode` (build/run/analyze/snippet/code_review/add_file/bump_version/…) · `agent_script` |
| **Shell** | `user_shell` (Launch Agent) · `root_shell` (Launch Daemon) · `shell` (repli en processus) · `batch` · `multi` |
| **Automatisation macOS** | `accessibility` (25 actions basées sur les éléments) · `applescript` (avec `lookup_sdef`) · `javascript` (JXA) |
| **Web** | `safari` · `selenium` · `mcp_playwright_browser_*` (optionnel) |
| **Sous-agents** | `spawn_agent` · `tell_agent` |

Référence complète par action : [docs/TECHNICAL.md](docs/TECHNICAL.md).

## AgentScript — Scripts Swift avec TCC complet

Les AgentScripts sont de simples fichiers Swift dans `~/Documents/AgentScript/agents/Sources/Scripts/`. Agent! compile chacun en `.dylib` avec SwiftPM (`Package.swift` liste chaque script plus les 51 ponts ScriptingBridge), puis le charge via `dlopen` avec les autorisations TCC d'Agent! lui-même — Accessibilité, Automatisation, Calendrier, Contacts, Mail, Photos, etc. Le LLM les gère avec `agent_script` (`create` / `edit` / `run` / `delete` / `restore` / `pull`) ; ~35 exemples sont fournis dans le dossier (`Hello`, `TodayEvents`, `NowPlaying`, `CheckMail`, `CreateDmg`, `ArchiveXcode`, …).

**Point d'entrée** — pas de code de niveau supérieur, pas de `exit()` ; `stdout` est renvoyé au LLM, la valeur de retour est le code de sortie :

```swift
import Foundation
import CalendarBridge   // tout `import XBridge` est câblé automatiquement — aucune modification de Package.swift

@_cdecl("script_main")
public func scriptMain() -> Int32 {
    print("Hello from AgentScript! 👋")
    return 0
}
```

**Variables d'environnement — comment elles sont DÉFINIES.** Le LLM ne touche jamais lui-même à l'environnement. Il appelle l'outil, et le `ScriptService` d'Agent! exporte les variables dans le processus du script (`env["AGENT_PROJECT_FOLDER"] = cwd`, `env["AGENT_SCRIPT_ARGS"] = arguments` dans `ScriptService+Execution.swift` ; `setenv(...)` pour la variante en processus). Les deux mêmes variables sont exportées vers chaque commande `user_shell` / `root_shell` / `shell`.

```text
Appel d'outil du LLM                                   Ce qu'Agent! exporte vers le script
─────────────────────────────────────────────────────  ─────────────────────────────────────────────
agent_script(action:"run", name:"TodayEvents")         AGENT_PROJECT_FOLDER=/Users/vous/Documents/GitHub/Agent
                                                       (AGENT_SCRIPT_ARGS n'est PAS définie)

agent_script(action:"run", name:"TodayEvents",         AGENT_PROJECT_FOLDER=/Users/vous/Documents/GitHub/Agent
             arguments:"days=3,location=false,json=true")   AGENT_SCRIPT_ARGS="days=3,location=false,json=true"
```

| Variable | Quand définie | Signification |
|---|---|---|
| `AGENT_PROJECT_FOLDER` | Toujours | Le dossier de projet de l'onglet actif (ou `$HOME` s'il n'y en a pas). Le cwd du runner y est aussi positionné. |
| `AGENT_SCRIPT_ARGS` | Seulement quand le LLM passe `arguments:"…"` | La chaîne passée par le LLM, telle quelle. Les exemples utilisent la convention `key=value,key=value`. |

**Variables d'environnement — comment elles sont LUES.** Dans le script, les deux proviennent de `ProcessInfo.processInfo.environment`. C'est exactement le schéma d'analyse de `Hello.swift` / `TodayEvents.swift` :

```swift
import Foundation

@_cdecl("script_main")
public func scriptMain() -> Int32 {
    let env = ProcessInfo.processInfo.environment

    // 1. Dossier de projet — toujours présent ; repli sur le cwd par précaution
    let folder = env["AGENT_PROJECT_FOLDER"] ?? FileManager.default.currentDirectoryPath

    // 2. Arguments — absents sauf si le LLM a passé `arguments:"…"`
    let argsString = env["AGENT_SCRIPT_ARGS"] ?? ""

    // 3. Valeurs par défaut, puis analyse de "key=value,key=value"
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

    print("Dossier de projet : \(folder)")
    print("days=\(daysAhead) location=\(showLocation) json=\(outputJSON)")
    return 0
}
```

Les deux variables sont indépendantes — ne jamais extraire le dossier de projet de `AGENT_SCRIPT_ARGS`. Équivalent Bash dans `user_shell` : `ls "$AGENT_PROJECT_FOLDER/Sources"` (le cwd y est déjà, pas besoin de `cd`).

**Entrée / sortie JSON** — la convention suivie par les exemples fournis :

- **Entrée :** `~/Documents/AgentScript/json/<Name>_input.json` — optionnel ; ses clés priment sur `AGENT_SCRIPT_ARGS`.
- **Sortie :** `~/Documents/AgentScript/json/<Name>_output.json` — écrit quand `json=true` (ou `"json": true` dans le fichier d'entrée), en plus de la sortie lisible sur stdout.

```json
// Hello_input.json
{ "verbose": true, "json": true }

// Hello_output.json
{ "success": true, "userName": "…", "hostName": "…", "osVersion": "…", "timestamp": "…" }
```

Les scripts supprimés vont dans `~/Documents/AgentScript/agents/.Trash/` (`agent_script(action:"restore")`) ; `action:"pull"` récupère la version upstream depuis le dépôt [AgentScripts](https://github.com/AgentiLoop/AgentScripts).

## Confidentialité et sécurité

Vos fichiers, le contenu de votre écran et vos données personnelles ne quittent jamais votre Mac — les fournisseurs cloud ne voient que le texte du prompt ; les fournisseurs locaux gardent tout hors ligne. Chaque action est journalisée.

| Couche | Ce qu'elle fait |
|---|---|
| **Shell Safety Service** | Bloque en dur `rm -rf /`, `rm -rf ~`, `rm -rf` avec glob nu, `--no-preserve-root` — appliqué côté client **et** côté daemon. Impossible à contourner par le LLM. |
| **Confiance des clients XPC** | Les deux listeners exigent une signature de code de la même équipe, dérivée de la propre signature de l'app ; les builds release rejettent les clients sans équipe. |
| **Garde read-before-edit** | Les modifications de fichiers non lus ou modifiés en externe sont refusées (SHA-256), avec lecture automatique au refus. |
| **Sauvegardes de fichiers + rewind** | Chaque modification est sauvegardée (TTL d'une semaine) ; UI de Rollback, `file(action:"undo")` ou `rewind_task` par tâche. |
| **Routage TCC en processus** | Les commandes AppleScript/JXA/screencapture/accessibilité s'exécutent en processus, là où Agent! détient les autorisations TCC, jamais via les daemons. |
| **Contrôle d'exécution des outils** | Le LLM ne peut pas inventer de résultats — chaque appel passe par `dispatchTool()` et renvoie une sortie réelle. Les affirmations « j'ai cliqué/cherché… » sans outil reçoivent une correction injectée. |
| **Erreurs typées + gardes** | Chaque résultat d'outil en échec porte un indice de récupération ; les gardes « disque rayé » et « bloqué » relancent puis s'arrêtent ; les portes de fin limitent les refus à 3 par tâche. |
| **Piste d'audit Console** | Chaque appel d'outil et chaque commande du helper sont journalisés. |

## Raccourcis clavier et commandes slash

| Raccourci | Action |
|---|---|
| `Return` | Lancer la tâche · `⌘ .` / `Esc` annuler |
| `⌘ T` / `⌘ W` / `⌘ 1–9` / `⌘ ⇧ ←→` | Nouvel / fermer / changer / précédent-suivant onglet |
| `⌘ B` / `⌘ D` | Basculer la superposition de sortie LLM / les chevrons |
| `⌘ F` / `⌘ L` / `⌘ V` | Rechercher dans le journal / vider le journal / coller une image |
| `↑` / `↓` | Historique des prompts |
| `⌘ ⇧ M` / `⌘ ⇧ P` | Moniteur Messages / Réglages |
| `⌘ ⇧ K` `L` `H` `J` `U` | Tout effacer / panneau LLM / historique des prompts / historique des tâches / compteurs de tokens |

Les commandes slash s'exécutent en local : `/clear [log|all|llm|history|tasks|tokens]`, `/memory [show|clear|edit|<texte>]`.

## FAQ

**Dois-je savoir coder ?** Non — du français courant (ou votre langue maternelle).
**Combien ça coûte ?** L'app est gratuite (MIT). Vous payez votre fournisseur ; GLM-5.1 via Z.ai/BigModel ou DeepSeek sont les moins chers pour un travail sérieux. Les modèles locaux sont gratuits si vous possédez le matériel.
**Quel Mac me faut-il ?** Apple Silicon, macOS 26.4.1+. N'importe quel Mac récent pour les fournisseurs cloud ; 64 Go+ pour les modèles locaux 30B.
**Quelle différence avec Siri ?** Siri répond. Agent! *agit* — apps, fichiers, code, système.

Plus : [docs/FAQ.md](docs/FAQ.md) · [Architecture technique](docs/TECHNICAL.md) · [Comparaisons](docs/COMPARISON.md) (vs Claude Code, Cursor, Cline, OpenClaw) · [Modèle de sécurité](docs/SECURITY.md)

## Histoire

Agent! est le fruit de trois années de développement d'apps d'IA agentique — ANIE, Game Changer, BattleScript, XCF MCP Server and Client, D1F et environ huit packages Swift originaux. La pièce manquante était une boucle autonome intelligente ; une fois obtenue, le meilleur de ces projets s'est réuni dans Agent!. Il a écrit des jeux vidéo ([Boss-Man](https://github.com/AgentiLoop/bossman)), créé des apps, écrit de la poésie dans Pages via AppleScript, généré des images disque et les a jointes à des releases GitHub. Là où Claude Code repose sur ~65 packages NPM tiers, Agent! est 100 % natif, consomme très peu de RAM et embarque d'origine l'automatisation Xcode, l'analyse Swift Syntax 6.2, l'Accessibilité, AppleScript, AgentScript/ScriptingBridge, l'automatisation Safari et le support MCP.

## Contribuer

Voir [CONTRIBUTING.md](./CONTRIBUTING.md) — compilez depuis les sources en ~5 minutes avec `./build.sh`, sans compte développeur. Les pull requests passent par le workflow CI Build & Test. Consultez les [good first issues](https://github.com/AgentiLoop/Agent/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22).

## Licence

MIT — gratuit et open source.

---

> ⚠️ **Avis Légal et Attribution**
>
> ### Avis de Marque Déposée
>
> « 🦾 Agent! for macOS26 » est un projet logiciel indépendant et n'est **pas** affilié à, approuvé par, sponsorisé par, ni autrement associé à Apple Inc. « Apple », « Mac », « Mac mini », « MacBook », « macOS », et les marques associées sont des marques déposées d'Apple Inc., enregistrées aux États-Unis et dans d'autres pays. Toutes les autres marques déposées, marques de service et noms commerciaux mentionnés ici sont la propriété de leurs détenteurs respectifs et sont utilisés à des fins d'identification uniquement.
>
> « 🦾 Agent! » et le logo 🦾 Agent! sont des marques déposées de AgentiLoop Agent. L'utilisation de ces marques nécessite une autorisation écrite préalable. La licence MIT ci-dessous accorde des droits uniquement sur le code source — elle **n'accorde aucun** droit de marque.
>
> ### Licence du Code Source (MIT)
>
> Le code source de « 🦾 Agent! for macOS26 » est open source et sous licence **MIT**. Vous êtes libre d'utiliser, copier, modifier, fusionner, publier, distribuer, sous-licencier et/ou vendre des copies du code source, sous réserve des conditions du fichier [LICENSE](./LICENSE) (conserver l'avis de copyright et l'avis de permission MIT dans toutes les copies ou parties substantielles du logiciel).
>
> ### Binaires Compilés et Releases
>
> Les binaires compilés, installateurs, builds signés, et artefacts de release distribués via les GitHub Releases de ce projet, [AgentiLoop.ai](https://AgentiLoop.ai), ou tout autre canal officiel, sont l'œuvre protégée par le droit d'auteur de AgentiLoop Agent et **ne sont pas** couverts par la licence MIT qui régit le code source. Tous les droits sur les binaires officiels — y compris le nom « 🦾 Agent! », le logo, l'identité de signature de code, et le Developer ID — sont réservés.
>
> Copyright © 2000, 2023–2026 AgentiLoop Agent, Tous Droits Réservés.
>
> Vous êtes libre de compiler vos propres binaires à partir des sources sous la licence MIT, à condition de ne pas utiliser le nom « 🦾 Agent! », le logo, ou la marque pour identifier votre produit.
>
> ### Clause de Non-Garantie
>
> Ce logiciel est fourni **« TEL QUEL »**, sans garantie d'aucune sorte, expresse ou implicite, y compris mais sans s'y limiter les garanties de qualité marchande, d'adéquation à un usage particulier, et de non-contrefaçon. En aucun cas l'auteur ou le détenteur des droits d'auteur ne pourra être tenu responsable de toute réclamation, dommage ou autre responsabilité, que ce soit dans le cadre d'une action contractuelle, délictuelle, ou autre, découlant de, résultant de, ou en lien avec le logiciel ou l'utilisation ou d'autres transactions du logiciel.
>
> ---
>
> Merci de votre intérêt pour 🦾 Agent! — une application conçue pour les ordinateurs Mac mini, MacBook, et Mac Studio fonctionnant sous macOS 26.4 ou ultérieur sur du matériel et logiciel Mac authentique.
>
> - Website: https://AgentiLoop.ai
> - Github : https://github.com/AgentiLoop/agent
