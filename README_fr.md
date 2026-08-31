# 🦾 Agent! pour macOS 26.4.1 ou ultérieur

## **IA Agentique pour votre Mac de Bureau**

[![Latest Release](https://img.shields.io/github/v/release/AgentiLoop/Agent?label=Download&color=blue&style=for-the-badge)](https://github.com/AgentiLoop/Agent/releases/latest)
[![GitHub Stars](https://img.shields.io/github/stars/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Stars&color=gold)](https://github.com/AgentiLoop/Agent/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Forks&color=white)](https://github.com/AgentiLoop/Agent/fork)
[![macOS 26.4+](https://img.shields.io/badge/macOS-26.4.1-green?style=for-the-badge)](https://github.com/apple)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange?style=for-the-badge)](https://www.swift.org)
<a href="https://www.paypal.com/ncp/payment/9C6RY2UAE5M3S"><img src="https://img.shields.io/badge/Donation-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Tip Jar" /></a>

## Échecs dans Agent
<img width="1176" height="724" alt="Screenshot 2026-08-23 at 7 34 10 PM" src="https://github.com/user-attachments/assets/d3b2f1e5-1dab-44f7-95f6-008424ee794c" />

## Histoire et technologie derrière Agent!
Agent! ne s'est pas fait du jour au lendemain. C'est le résultat de trois années passées à construire des applications d'IA agentique, en s'appuyant sur environ une douzaine de projets développés en cours de route. Certains ont été publiés sous les noms ANIE, Game Changer, BattleScript, XCF MCP Server and Client, D1F, et environ huit packages Swift originaux. La pièce manquante était de parvenir à une boucle temporelle autonome et intelligente. Une fois cela atteint, j'ai intégré le meilleur des trois années précédentes. Le résultat est Agent! pour macOS 26.4.1 ou ultérieur.

L'objectif initial était de créer un « tueur de Cursor ». Ce qui en est ressorti est quelque chose de plus intéressant : une IA agentique qui a de vraies jambes. Agent! n'est limité que par votre imagination. Il peut écrire du code, y compris des jeux vidéo comme Boss-Man, https://github.com/AgentiLoop/bossman, créer des applications, écrire de la poésie via AppleScript dans Pages, générer des images disque et les joindre à des releases GitHub. Il peut automatiser la plupart des tâches sur votre Mac. Demandez-lui ce que vous voulez en anglais simple ou dans votre langue maternelle et, après une configuration initiale et des validations de l'utilisateur, il fera tout son possible pour exaucer votre souhait. Agent! est infatigable et cherche à satisfaire.

Toute la propriété intellectuelle d'Agent! est originale et open source. Chaque dépendance de package Swift et l'application elle-même ont été écrites à l'origine par la même personne. C'est un écosystème véritablement différent. La plupart des applications d'IA agentique comme Claude Code s'appuient sur 65 packages NPM tiers. Agent! est 100 % natif, nécessite très peu de RAM, et pèse 35,5 non compressé. Cette empreinte comprend l'automatisation Xcode, un package Swift Syntax 6.2 pour le dépannage d'applications natives, Accessibility, AppleScript, AgentScript/ScriptingBridge, l'automatisation de Safari, le support des serveurs MCP, et plus encore. Prêt à l'emploi.

## Nouveautés 🚀

**v1.0.92 (186) — La version de l'autonomie auto-vérifiante** · [Notes de version complètes →](https://github.com/AgentiLoop/Agent/releases/tag/v1.0.92.186)

Agent! prouve désormais son travail. Une tâche ne peut se déclarer terminée que si ses critères de réussite sont vérifiés avec des preuves (`goal_state`), un critique optionnel examine le diff avant l'achèvement, et chaque fichier modifié peut être annulé en un seul geste (`rewind_task`). Réflexion étendue pour Claude, `reasoning_effort` pour les fournisseurs compatibles OpenAI, et un contexte stable pour le cache de prompts qui se compacte à la fenêtre réelle de chaque modèle — de manière récupérable, avec tous les résultats d'outils déversés sur disque. Les erreurs d'outils typées portent des indices de récupération, les sous-agents exécutent leurs propres modèles (jusqu'à 6 chercheurs en lecture seule), les hooks d'événements sont entièrement câblés, et 57 tests réussis maintiennent l'honnêteté du système.

**Une application. N'importe quelle IA. Contrôle total sur votre Mac.**

Agent! relie **18 fournisseurs de LLM** — Claude, GPT, Gemini, Grok, Mistral, DeepSeek, Qwen, Z.ai, BigModel, Hugging Face, **OpenRouter**, Ollama (cloud et local), vLLM, LM Studio, Codestral, Mistral Vibe, et **Apple Intelligence** sur l'appareil — dans une application macOS native qui ne se contente pas de parler de faire des choses. Elle les fait.

Regardez-le lire votre base de code, corriger le bug, compiler le projet Xcode et valider le diff pendant que vous préparez un café. Dites-lui d'ouvrir Safari et de vous envoyer un texto avec le prix des vols pour Tokyo. Dites *« Agent! »* depuis l'autre bout de la pièce et faites-lui exécuter votre suite de tests à la voix. Envoyez un texto à votre Mac depuis iMessage et obtenez une réponse soignée avant même d'atteindre votre voiture.

Il modifie les fichiers avec des diffs chirurgicaux de remplacement de chaîne — chaque modification annulable en un clic depuis une restauration façon Time Machine. Il pilote n'importe quelle application Mac via l'API Accessibility — sans besoin d'AppleScript. Il se souvient de vos préférences d'une session à l'autre. Il génère des sous-agents parallèles pour le travail qui se ramifie. Il indexe des bases de code entières dans une carte de dépôt JSONL portable que n'importe quel LLM peut consommer. Il exécute des commandes shell en votre nom, ou en tant que root via un Launch Daemon que vous approuvez une seule fois.

Utilisez votre propre clé API. Exécutez-le entièrement en local sur Ollama, vLLM ou LM Studio. Ou utilisez-le gratuitement, pour toujours, avec Apple Intelligence. Pas d'abonnement. Pas de télémétrie. Pas de dépendance à un fournisseur. Vos clés, votre machine, vos données.

Téléchargez-le. Dites ce dont vous avez besoin. Regardez-le se réaliser.

## Démarrage Rapide (Téléchargement)

1. **Téléchargez** [Agent!](https://github.com/AgentiLoop/Agent/releases/latest) et faites-le glisser vers Applications
2. **Ouvrez Agent!** -- il configure tout automatiquement
3. **Choisissez votre IA** -- Réglages → choisissez un fournisseur → entrez la clé API

## Démarrage Rapide (Compiler depuis les sources)

1. **Clonez le dépôt :**
   ```bash
   git clone https://github.com/AgentiLoop/agent.git
   cd Agent
   ```

#### Option A : Compiler avec Xcode (compte Apple Developer)
2. **Ouvrez `Agent.xcodeproj` dans Xcode.**
3. **Compilez et exécutez la cible `Agent`.**
4. **Approuvez l'outil auxiliaire :** Lorsque vous y êtes invité, autorisez le daemon privilégié pour permettre l'exécution de commandes au niveau root.

#### Option B : Compiler sans compte Apple Developer
2. **Exécutez le script de compilation** (nécessite uniquement les Xcode Command Line Tools) :
   ```bash
   ./build.sh              # Build Debug
   ./build.sh Release      # Build Release
   ```
3. L'application se trouve dans `build/DerivedData/Build/Products/Debug/Agent!.app`
4. **Lancez-la :** `open "build/DerivedData/Build/Products/Debug/Agent!.app"`

> ⚠️ Sans compte développeur, l'application est signée en ad-hoc. Les assistants Launch Agent/Daemon ne s'enregistreront pas (SMAppService nécessite un Team ID), mais la boucle du LLM, tous les outils, l'accessibilité, AppleScript, le shell et MCP fonctionnent tous.

#### Ensuite :
5. **Configurez votre fournisseur d'IA :** Allez dans Réglages et entrez votre clé API ou sélectionnez un fournisseur local comme Ollama.

> 💡 **Configuration GLM économique :** **GLM-5.1** fonctionne sur les quatre fournisseurs économiques — **Ollama**, **Hugging Face**, **Z.ai**, **BigModel** — pour quelques centimes par million de tokens. Nouveau ici ? Commencez avec **Z.ai** (inscription la plus rapide, GLM-5.1 est le modèle par défaut, rien à provisionner). Vous exécutez en local ? Seul **GLM-4.7-Turbo** (32B) tient sur du matériel grand public (Mac M2/M3/M4, 64-128 Go, via Ollama) — GLM-5 et GLM-5.1 sont trop volumineux (~1,6 To), utilisez-les via les fournisseurs cloud ci-dessus.


## Que peut-il faire ?

> *« Joue ma playlist Workout dans Music »*
> *« Compile le projet Xcode et corrige les erreurs »*
> *« Prends une photo avec Photo Booth »*
> *« Envoie un iMessage à Maman disant que je serai à la maison à 18h »*
> *« Ouvre Safari et cherche des vols pour Tokyo »*
> *« Refactorise cette classe en fichiers plus petits »*
> *« Quels événements ai-je dans mon calendrier aujourd'hui ? »*

Tapez simplement ce que vous voulez. Agent! trouve comment et le fait.

---

## Fonctionnalités Clés

### 🧠 Cadre d'IA Agentique
Boucle de tâches autonome intégrée qui raisonne, exécute et s'auto-corrige. Agent! ne se contente pas d'exécuter du code ; il observe les résultats, débogue les erreurs et itère jusqu'à ce que la tâche soit terminée. L'état d'objectif avec des critères de réussite vérifiés par des preuves signifie qu'une tâche ne peut se déclarer terminée que si elle le prouve.

### 🛠 Programmation Agentique
Environnement de programmation complet intégré. Lit les bases de code, modifie les fichiers avec précision, exécute des commandes shell, compile des projets Xcode, gère git, et active automatiquement le mode codage pour concentrer l'IA sur les outils de développement. Remplace Claude Code, Cursor et Cline -- pas de terminal, pas de plugins IDE, pas d'abonnement mensuel. Comprend des **sauvegardes façon Time Machine** pour chaque modification de fichier, vous permettant d'annuler instantanément toute modification.

### 🔍 Découverte Dynamique d'Outils
Détecte et utilise automatiquement les outils disponibles (Xcode, Playwright, Shell, etc.) selon votre instruction. Aucune configuration manuelle requise pour les outils principaux.

### 🛡 Exécution Privilégiée
Exécute en toute sécurité des commandes au niveau root via un Launch Daemon macOS dédié. L'utilisateur approuve le daemon une fois, puis l'agent peut exécuter des commandes de manière autonome via XPC.

#### Pourquoi il n'y a pas de `setCodeSigningRequirement` manuel sur le listener XPC

Les utilisateurs demandent parfois pourquoi le listener XPC d'`AgentHelper` accepte les connexions sans une vérification manuelle de `connection.setCodeSigningRequirement(...)`. La réponse courte : **SMAppService impose déjà l'identité de signature une couche en dessous de votre code**, donc la vérification serait redondante.

Cette recommandation est un vestige de l'ère pré-SMAppService, **SMJobBless**, où launchd ne validait pas l'identité pour vous et le serveur XPC devait lui-même définir une chaîne d'exigence désignée. SMAppService a changé ce contrat :

- Le plist intégré au bundle de l'application, associé à l'enregistrement soumis à signature, **constitue** l'exigence de signature de code.
- Les noms de service Mach (`Agent.app.redacted.helper`, `Agent.app.redacted.user`) sont associés au bundle signé qui les a enregistrés — aucun autre bundle ne peut les revendiquer.
- Toute incohérence de signature (falsification, re-signature, Team ID différent, substitution de bundle) **rompt le canal XPC au niveau de launchd** — `listener(_:shouldAcceptNewConnection:)` n'est même jamais invoqué.

**Preuve empirique :** Agent! lui-même a tenté de re-signer ses propres daemons lors d'une expérience et a immédiatement perdu la capacité de se connecter. `NSXPCConnection` vers les deux services Mach a échoué au niveau de launchd avant qu'un seul octet n'atteigne le délégué du listener — exactement le comportement qu'un appel manuel à `setCodeSigningRequirement` imposerait, sauf que SMAppService le fait dans le chemin de recherche XPC du noyau, où il ne peut être contourné depuis l'espace utilisateur.

| Application | Mécanisme | Contournable depuis l'espace utilisateur ? |
|---|---|---|
| L'assistant doit être dans le bundle d'application signé | Gatekeeper + enregistrement SMAppService | Non |
| L'assistant doit correspondre au Team ID de l'application (469UCUB275) | Signature de code + SMAppService | Non |
| Nom du service Mach lié au bundle signé | espace de noms launchd / XPC | Non |
| Le hash du binaire assistant correspond à l'identité enregistrée | SMAppService + recherche XPC du noyau | Non (la re-signature rompt le canal) |
| L'utilisateur a approuvé l'assistant | Réglages Système → Éléments de connexion et extensions | Non (geste utilisateur requis) |

Ajouter explicitement `setCodeSigningRequirement` serait une défense en profondeur raisonnable (utile seulement si l'application était un jour portée hors de SMAppService, ou si SIP était désactivé), mais ce **n'est pas une faille** dans l'architecture actuelle. Voir [docs/SECURITY.md](docs/SECURITY.md) pour l'analyse complète de l'ancrage de confiance.

### 🖥 Automatisation du Bureau (AXorcist)
Contrôlez n'importe quelle application Mac via l'API Accessibility. Cliquez sur des boutons, tapez dans des champs, naviguez dans les menus, faites défiler, glissez -- tout programmatiquement. Propulsé par [AXorcist](https://github.com/steipete/AXorcist) pour une recherche d'éléments fiable et à correspondance floue.

### 🤖 18 Fournisseurs d'IA

Le sélecteur de fournisseur (Réglages LLM, bouton de barre d'outils #7) affiche 17 fournisseurs ; Apple Intelligence est accessible via l'icône de cerveau séparée (#8). Source de vérité : `AgentTools.APIProvider`.

| Fournisseur | Clé API | Idéal pour |
|---|---|---|
| **Claude** (Anthropic) | Payant | Tâches autonomes longues, raisonnement complexe, cache de prompts |
| **OpenAI** | Payant | Usage général, appel d'outils, vision |
| **Google Gemini** | Payant (niveau gratuit) | Contexte long, vision, rapidité |
| **Grok** (xAI) | Payant | Informations en temps réel |
| **Mistral** | Payant | Cloud à poids ouverts, appel d'outils rapide |
| **Codestral** (Mistral) | Payant | Mistral spécialisé code |
| **Mistral Vibe** | Payant | Produit de chat/agent de Mistral |
| **DeepSeek** | Économique | Cloud économique, codage solide, rapport de hits de cache de prompts |
| **Hugging Face** | Variable | Modèles open source hébergés sans serveur ou sur des endpoints dédiés |
| **OpenRouter** | Payant | Plus de 200 modèles via une seule clé API — Claude, GPT, Gemini, Llama, Mistral et plus. Le bascule de protocole intelligent achemine les modèles Claude via le protocole Anthropic, tout le reste via OpenAI |
| **Z.ai** | Économique | GLM-5.1 via API — point de départ recommandé |
| **BigModel** (Zhipu) | Économique | Famille GLM via l'API Zhipu |
| **Qwen** (Alibaba) | Économique | Qwen 2.5 / 3 via Dashscope |
| **Ollama** (cloud) | Niveau gratuit | Exécute des modèles ouverts via l'endpoint hébergé d'Ollama |
| **Ollama Local** | Gratuit + matériel | Daemon Ollama auto-hébergé — entièrement hors ligne, sans compte |
| **vLLM** | Gratuit + matériel | Serveur vLLM auto-hébergé avec cache de préfixe |
| **LM Studio** | Gratuit + matériel | Auto-hébergé, GUI la plus simple pour les modèles locaux |
| **Apple Intelligence** | Gratuit, sur l'appareil | Triage, résumé, compression de tokens (via l'icône de cerveau, pas le sélecteur de fournisseur) |

> 💡 **Les fournisseurs auto-hébergés « gratuits » (Ollama Local, vLLM, LM Studio) ne sont gratuits qu'au sens des frais d'API.** Exécuter un modèle 30B+ à une vitesse utilisable nécessite un Mac Studio M2/M3/M4 Ultra (64-128 Go de mémoire unifiée) ou une machine Linux avec 24 Go+ de VRAM. Si vous ne possédez pas déjà ce matériel, les options cloud ci-dessus (Ollama Cloud, Hugging Face, Z.ai, BigModel, DeepSeek) sont nettement moins chères que de l'acheter.

## Boutons de la Barre d'Outils

L'en-tête d'Agent! contient **15 boutons** pour un accès rapide aux réglages, moniteurs et outils. Chaque bouton ouvre une popover au clic. Source de vérité : `Agent/Views/HeaderSectionView.swift`.

| # | Icône | Nom | Ce que ça fait |
|---|------|------|--------------|
| 1 | ⚙️ | **Services** | Active/désactive le Launch Agent / Launch Daemon, gère le dossier de projet, scanne la sortie des commandes |
| 2 | 💬 | **Moniteur de Messages** | Active/désactive la surveillance iMessage — vert quand actif. Ouvre la liste des destinataires et l'interface d'approbation |
| 3 | ✋ | **Accessibilité** | Ouvre la feuille de réglages Accessibilité (statut des permissions, diagnostics axorcist) |
| 4 | 🖥️ | **Serveurs MCP** | Ajoute/supprime/configure des serveurs MCP (Model Context Protocol) — étend Agent! avec des outils `mcp_*` |
| 5 | </> | **Préférences de Codage** | Active/désactive l'auto-vérification, les tests visuels, l'auto-PR, l'auto-scaffold. Vert quand une option est activée |
| 6 | 🔧 | **Outils** | Bascules d'outils par fournisseur. Active/désactive les outils intégrés et MCP individuels |
| 7 | 🧠 | **Réglages LLM** | Choisissez le fournisseur d'IA, le modèle, la clé API, l'URL de base. Pulse quand une tâche est en cours |
| 8 | 🧬 | **Apple Intelligence** | Configure FoundationModels (Apple AI sur l'appareil). Rempli lorsque disponible |
| 9 | 🎛️ | **Options de l'Agent** | Température, itérations maximales, capture d'écran auto par vision, encouragement du mode plan, etc. |
| 10 | 🔄 | **Chaîne de Secours** | Configure l'ordre de secours des fournisseurs — Agent! réessaie avec le fournisseur suivant quand l'un échoue |
| 11 | 🔲 | **HUD** | Active/désactive la superposition de lignes de balayage façon CRT verte sur la vue de sortie du LLM |
| 12 | 📊 | **Utilisation LLM** | Suivi de l'utilisation des tokens et des coûts par modèle. Vert quand il y a une utilisation enregistrée |
| 13 | ↩️ | **Restauration** | Navigateur de sauvegardes de fichiers façon Time Machine. Restaure toute version précédente de tout fichier modifié par Agent! |
| 14 | 🕐 | **Historique** | Instructions passées, erreurs et résumés de tâches pour l'onglet actif. Relancez une instruction précédente en un clic |
| 15 | 🗑️ | **Effacer le Journal** | Supprime le journal d'activité de l'onglet actif (ou tout l'historique des tâches quand aucun onglet n'est sélectionné). Demande confirmation d'abord |

---

### 🎙 Contrôle Vocal — Mot-clé « Agent! »
**Dictée ancrée au mot-clé via `SFSpeechRecognizer`.** Cliquez sur le microphone dans la barre de saisie pour démarrer la session de mot-clé, puis dites **« Agent! »** suivi de votre tâche. La transcription se fait sur l'appareil, en temps réel, et écoute « agent » comme mot complet (pas comme sous-chaîne de « intelligent » ou « management »). Tout ce que vous dites après le mot de réveil devient la tâche — après ~2,5 secondes de silence, elle s'exécute automatiquement. La session boucle automatiquement : quand une tâche se termine, elle se remet à l'écoute. Cliquez sur le micro pour arrêter.

### 📱 Contrôle à Distance via iMessage
Envoyez un texto à votre Mac depuis votre iPhone :
```
Agent! Quelle chanson joue ?
Agent! Vérifie mes e-mails
Agent! Chanson suivante
```
Votre Mac exécute la tâche et vous répond par texto avec le résultat. Seuls les contacts approuvés peuvent envoyer des commandes.

### 🌐 Automatisation Web
Pilote Safari mains libres -- recherche sur Google, clique sur des liens, remplit des formulaires, lit des pages, extrait des informations.

### 📋 Planification Intelligente
Pour les tâches complexes, Agent! crée un plan étape par étape, travaille sur chaque étape et les coche en temps réel.

### 🗂 Onglets
Travaillez sur plusieurs tâches simultanément. Chaque onglet a son propre dossier de projet et son propre historique de conversation.

### 📸 Capture d'écran et Vision
Prenez des captures d'écran ou collez des images. Les modèles d'IA capables de vision analysent ce qu'ils voient -- décrivent le contenu, lisent le texte, repèrent les problèmes d'interface.

### 🌐 Automatisation Web Safari (Intégrée)

Agent! comprend une automatisation web Safari intégrée via JavaScript et AppleScript. Recherchez sur Google, cliquez sur des liens, remplissez des formulaires, lisez le contenu des pages et exécutez du JavaScript -- tout mains libres.

**Pour activer :** Ouvrez Safari → Réglages → Avancé → cochez « Afficher les fonctionnalités pour les développeurs Web ». Puis allez dans le menu Développement → cochez « Autoriser JavaScript depuis les événements Apple ».

### 🎭 Automatisation Web Playwright (Optionnelle)

Automatisation multi-navigateur complète via [Microsoft Playwright MCP](https://github.com/microsoft/playwright-mcp). Cliquez, tapez, capturez l'écran et naviguez sur n'importe quel site dans Chrome, Firefox ou WebKit -- tout contrôlé par l'IA.

**Configuration (une seule fois) :**

```bash
# 1. Installez Node.js (si ce n'est pas déjà fait)
brew install node

# 2. Installez le serveur Playwright MCP globalement
npm install -g @playwright/mcp@latest

# 3. Installez les binaires de navigateur (choisissez-en un ou tous)
npx playwright install chromium          # Chrome (~165 Mo)
npx playwright install firefox           # Firefox (~97 Mo)
npx playwright install webkit            # Safari/WebKit (~75 Mo)
npx playwright install                   # Tous les navigateurs
```

**Configurez dans Agent! :**

Allez dans Réglages → Serveurs MCP → Ajouter un Serveur, collez ce JSON :

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

> **Remarque :** Si `npx` est introuvable, utilisez le chemin complet : exécutez `which npx` dans Terminal et remplacez `"npx"` par le résultat (ex. `"/opt/homebrew/bin/npx"`).

Activez, et les outils Playwright apparaissent automatiquement. L'IA peut maintenant contrôler les navigateurs directement.

### Outils — ce que `list_tools` renvoie réellement

Voici les noms d'outils canoniques définis dans `AgentTools.Name.*` et exposés à chaque fournisseur de LLM via `AgentTools.tools(for:)`. Source de vérité : `~/Documents/GitHub/AgentTools/Sources/AgentTools/AgentTools.swift`. Les bascules de préférences utilisateur de l'application peuvent masquer des outils individuels par fournisseur, mais la liste ci-dessous est l'ensemble complet que le LLM voit jamais.

#### Cœur / découverte

| Outil | Actions / arguments | Ce que ça fait |
|---|---|---|
| **done** | `summary` | Signale que la tâche est terminée. Requis à la fin de chaque tâche |
| **list_tools** | — | Renvoie la liste d'outils active pour le fournisseur actuel (intégrés + MCP) |
| **search** | `query` | Recherche web via Exa, Tavily ou DuckDuckGo (celui dont la clé est configurée) |
| **chat** | `write` / `transform` / `fix` / `about` | Écrit de la prose, transforme/corrige du texte, décrit les capacités d'Agent |
| **memory** | `read` / `write` / `append` / `clear` | Préférences utilisateur persistantes. « souviens-toi de X » → `append` |
| **plan** | `create` / `update` / `read` / `list` / `delete` | CRUD multi-plan avec suivi de statut par étape |
| **goal_state** | `set` / `get` / `mark` / `clear` | Objectif persistant + critères de réussite ; marquer comme terminé nécessite une preuve |
| **restore_tool_result** | `tool_use_id` | Récupère le texte complet d'un résultat d'outil tronqué par la compaction |
| **directory** | `get` / `set` / `home` / `documents` / `library` / `none` / `cd` | Dossier de projet pour l'onglet actuel |
| **fetch** | `url` | Récupère l'URL, retire le HTML, plafond de 8K caractères |
| **skill** | `list` / `invoke` / `save` / `delete` | Modèles de prompts réutilisables |
| **ask_user** | `question` | Dialogue utilisateur en cours de tâche (attend jusqu'à 5 min) |

#### Code / fichiers / build

| Outil | Actions / arguments | Ce que ça fait |
|---|---|---|
| **file** | `read` / `write` / `edit` / `create` / `apply` / `undo` / `diff_apply` / `list` / `search` / `read_dir` / `mkdir` / `cd` / `if_to_switch` / `extract_function` | Toutes les opérations de fichier. `edit` = remplacement d'une seule chaîne. `diff_apply` = préféré pour les modifications de code multi-lignes |
| **git** | `status` / `diff` / `log` / `commit` / `diff_patch` / `branch` / `worktree` | Opérations git — à utiliser à la place de git en shell |
| **xcode** | `build` / `run` / `list_projects` / `select_project` / `add_file` / `remove_file` / `grant_permission` / `analyze` / `snippet` / `code_review` / `get_version` / `bump_version` / `bump_build` | Intégration native Xcode. Les erreurs dans le journal d'activité sont cliquables |
| **agent_script** | `list` / `read` / `create` / `update` / `edit` / `run` / `delete` / `combine` / `restore` / `pull` / `list_backups` | Scripts dylib Swift dans `~/Documents/AgentScript/agents/` avec TCC complet |

#### Shell / niveaux de privilège

| Outil | Arguments | Ce que ça fait |
|---|---|---|
| **user_shell** | `command` | Shell en tant qu'utilisateur actuel via Launch Agent. Outil shell principal |
| **root_shell** | `command` | Shell en tant que ROOT via Launch Daemon. Tâches admin uniquement — pas de sudo |
| **shell** | `command` | Shell interne de secours (quand Launch Agent est désactivé) |
| **batch** | `commands` | Plusieurs commandes shell en un seul appel (séparées par des retours à la ligne) |
| **multi** | `description`, `tasks` | Plusieurs appels d'outils en un seul lot |

#### Automatisation macOS

| Outil | Actions / arguments | Ce que ça fait |
|---|---|---|
| **accessibility** | `open_app` / `find_element` / `click_element` / `type_into_element` / `scroll_to_element` / `list_windows` / `inspect_element` / `get_properties` / `perform_action` / `set_properties` / `get_focused_element` / `get_children` / `read_focused` / `wait_for_element` / `wait_adaptive` / `highlight_element` / `manage_app` / `show_menu` / `click_menu_item` / `set_window_frame` / `get_window_frame` / `screenshot` / `check_permission` / `request_permission` / `get_audit_log` | Automatisation basée sur les éléments via AXorcist. Chaque action prend `role`+`title`+`appBundleId` — pas de coordonnées |
| **applescript** | `execute` / `lookup_sdef` / `list` / `run` / `save` / `delete` | NSAppleScript sur place avec TCC |
| **javascript** | `execute` / `list` / `run` / `save` / `delete` | JXA (JavaScript for Automation) |

#### Automatisation web

| Outil | Actions / arguments | Ce que ça fait |
|---|---|---|
| **safari** | `open` / `find` / `click` / `type` / `execute_js` / `get_url` / `get_title` / `read_content` / `google_search` / `scroll_to` / `select` / `submit` / `navigate` / `list_tabs` / `switch_tab` / `list_windows` / `scan` / `search` | Automatisation Safari via JavaScript + AppleScript |
| **selenium** | `start` / `stop` / `navigate` / `find` / `click` / `type` / `execute` / `screenshot` / `wait` | Session Selenium WebDriver — utilisez `safari` pour un usage normal de Safari |
| **mcp_playwright_browser_\*** | (voir Playwright MCP) | Optionnel. Automatisation multi-navigateur via Playwright MCP |

#### Sous-agents

| Outil | Arguments | Ce que ça fait |
|---|---|---|
| **spawn_agent** | `name`, `prompt`, `tools`, `model`, `max_iterations` | Génère un sous-agent isolé. 3 simultanés (jusqu'à 6 en lecture seule). Remplacement de modèle optionnel + résultats basés sur fichiers |
| **tell_agent** | `to`, `message` | Envoie un message à la boîte aux lettres d'un sous-agent en cours d'exécution |

> 💡 **Remarque :** L'application sur l'appareil filtre cette liste par fournisseur — activez/désactivez les outils individuels dans la popover **Outils** (bouton #6 dans la barre d'outils ci-dessus). Apple Intelligence a son propre ensemble minimal par défaut en raison de sa petite fenêtre de contexte. Les outils MCP sont ajoutés à l'exécution sous la forme `mcp_<serveur>_<outil>` et listés sous « --- MCP Tools --- » par `list_tools`.

## Confidentialité et Sécurité

- **Vos données restent sur votre Mac.** Les fichiers, le contenu de l'écran et les données personnelles ne sont jamais téléchargés.
- **L'IA cloud ne voit que le texte de votre prompt.** Utilisez l'IA locale pour rester 100 % hors ligne.
- **Vous gardez le contrôle.** Agent! affiche tout ce qu'il fait et enregistre chaque action.
- **Construit sur le modèle de sécurité d'Apple.** Les permissions macOS protègent votre système.

### Couches de Défense

| Couche | Ce que ça fait |
|---|---|
| **Service de Sécurité Shell** | Bloque strictement les commandes catastrophiques (`rm -rf /`, `rm -rf ~`, `dd` vers `/dev/disk`, fork bombs, `--no-preserve-root`) avant même que le Process ne soit construit. Ne peut pas être contourné par le LLM. |
| **Routage TCC sur Place** | Un détecteur à 17 mots-clés route les commandes AppleScript, osascript, JXA, screencapture, accessibility, Shortcuts et ScriptingBridge pour qu'elles s'exécutent sur place, là où Agent! détient les autorisations TCC — jamais via le Launch Agent/Daemon (identifiants de bundle distincts = pas de TCC). |
| **Sauvegarde de Fichier à Chaque Modification** | `FileBackupService` prend automatiquement un instantané de chaque fichier avant `write_file`, `edit_file` et `diff_apply`. Récupérable via `file(action:"restore")` ou l'interface de Restauration. TTL d'une semaine. |
| **Corbeille d'Agent Script** | `delete_agent` copie le script vers `~/Documents/AgentScript/agents/.Trash/` avant sa suppression. Récupérable via `agent_script(action:"restore")`. |
| **Normalisation du Répertoire de Travail** | Chaque chemin d'exécution shell (`executeTCC`, `UserService`, `HelperService`) normalise le répertoire de travail — si un chemin de fichier est accidentellement passé comme cwd, il est réduit au répertoire parent au lieu de planter avec « Not a directory ». |
| **Drainage de Tâche Avant Démarrage** | Démarrer une nouvelle tâche attend la fin complète de la tâche précédente avant de commencer — évite que des boucles de réessai orphelines mélangent la sortie du journal entre fournisseurs. |
| **Chaîne de Secours** | Quand le LLM principal échoue (429, timeout, réseau), Agent! bascule automatiquement vers le fournisseur suivant dans la chaîne configurée par l'utilisateur après 2 échecs. |
| **Erreurs Exploitables** | Chaque erreur d'outil inclut un indice `Recovery:` indiquant précisément au LLM quoi essayer ensuite — pas de messages d'erreur sans issue qui gaspillent des tours. |
| **Invalidation du Cache de Lecture** | Le cache de lecture de fichiers est invalidé aussi bien lors des modifications réussies qu'échouées, afin que le LLM obtienne toujours du contenu à jour à la lecture suivante. |
| **Recherche par Nom de Base** | Quand `read_file` ou `edit_file` reçoit un chemin erroné, Agent! recherche dans les répertoires voisins des fichiers portant le même nom et renvoie les bons chemins en ligne — le LLM s'auto-corrige en un tour. |
| **Verrouillage de l'Exécution d'Outils** | Le LLM ne peut pas fabriquer de résultats d'outils. Tous les appels d'outils passent par le `dispatchTool()` de l'application → exécution réelle (XPC, shell, sur place) → sortie réelle renvoyée sous forme de `tool_result`. Le LLM ne voit et ne résume que des sorties qui se sont réellement produites. Si un outil échoue, l'erreur réelle est renvoyée — le LLM ne peut pas revendiquer un succès sans un événement d'exécution correspondant. |
| **action_not_performed** | Défense à deux niveaux contre les fausses affirmations d'action : **(1) Prompt** — le prompt système ordonne au LLM de dire « action non effectuée » si aucun outil n'a été appelé. **(2) Application** — si le LLM renvoie un texte affirmant « j'ai cherché/ouvert/cliqué » mais n'a fait aucun appel d'outil ce tour-ci, une correction est injectée pour le forcer à utiliser l'outil réel. |

---

## Raccourcis Clavier

Source de vérité : le `.onSubmit` du TextField dans `Agent/Views/InputSectionView.swift` pour `Return`, et le bloc en ligne `NSEvent.addLocalMonitorForEvents` dans `Agent/Views/ContentView.swift` pour tout le reste.

| Raccourci | Action |
|---|---|
| `Return` | Exécute la tâche actuelle (soumission du TextField — aucun modificateur requis) |
| `⌘ .` / `Escape` | Annule la tâche en cours |
| `⌘ B` | Active/désactive la superposition de Sortie LLM (afficher/masquer) |
| `⌘ D` | Active/désactive les deux chevrons LLM de l'onglet actuel (développer/réduire) |
| `⌘ T` | Nouvel onglet |
| `⌘ W` | Ferme l'onglet actuel (ou quitte s'il n'y a pas d'onglets) |
| `⌘ 1`–`⌘ 9` | Change d'onglet. `⌘1` est l'onglet principal ; `⌘2`–`⌘9` sont des onglets de script |
| `⌘ Shift ←` / `⌘ Shift →` | Onglet précédent / suivant |
| `⌘ F` | Active/désactive la barre de recherche du journal d'activité |
| `⌘ L` | Efface le journal de l'onglet actif |
| `⌘ V` | Colle une image depuis le presse-papiers |
| `↑` / `↓` | Historique des instructions (dans le champ de saisie) |
| `⌘ Shift M` | Active/désactive le Moniteur de Messages |
| `⌘ Shift P` | Ouvre les Réglages (l'éditeur de prompt système s'y trouve) |
| `⌘ Shift K` | Tout effacer (réinitialisation complète) |
| `⌘ Shift L` | Efface uniquement le panneau de sortie LLM |
| `⌘ Shift H` | Efface l'historique des instructions |
| `⌘ Shift J` | Efface l'historique des tâches |
| `⌘ Shift U` | Efface les compteurs de tokens |

## Commandes Slash

Tapez-les dans le champ de saisie et appuyez sur Entrée — elles s'exécutent localement sans passer par aucun LLM. Source de vérité : `AgentViewModel+RunStop.swift`.

| Commande | Action |
|---|---|
| `/clear` ou `/clear log` | Efface le journal d'activité de l'onglet actuel |
| `/clear all` | Efface tout (journal, sortie LLM, historique des prompts, historique des tâches, tokens) |
| `/clear llm` | Efface uniquement le panneau de sortie LLM |
| `/clear history` | Efface l'historique des instructions |
| `/clear tasks` | Efface l'historique des tâches |
| `/clear tokens` | Réinitialise les compteurs de tokens (tâche + session) |
| `/memory` ou `/memory show` | Affiche le contenu actuel du fichier mémoire dans le journal d'activité |
| `/memory clear` | Efface la mémoire |
| `/memory edit` | Ouvre `~/Documents/AgentScript/memory.md` dans l'éditeur par défaut du système |
| `/memory <texte>` | Ajoute `<texte>` à la mémoire (tout ce qui suit `/memory` devient la nouvelle ligne) |

---

## FAQ

**Ai-je besoin de savoir coder ?** Non. Tapez simplement ce que vous voulez en anglais simple.

**Est-ce sûr ?** Oui. Automatisation macOS standard, journalisation complète de l'activité, vous approuvez les permissions.

**Combien ça coûte ?** L'application Agent! elle-même est gratuite (licence MIT). Les fournisseurs d'IA cloud facturent l'usage de l'API — les options les moins chères pour un travail sérieux sont GLM-5/5.1 via Z.ai, BigModel ou Hugging Face (quelques centimes par million de tokens), ou DeepSeek pour du codage économique. Les modèles locaux auto-hébergés (Ollama, vLLM, LM Studio) n'ont pas de frais d'API mais n'ont de sens que si vous possédez déjà le matériel pour les faire tourner — voir la note matérielle ci-dessous.

**De quel Mac ai-je besoin ?** macOS 26.4.1. Apple Silicon requis. Pour les fournisseurs cloud, n'importe quel Mac moderne convient. Pour les modèles locaux auto-hébergés (Ollama, vLLM, LM Studio) : un modèle 7B tient dans 16 Go de mémoire unifiée, un modèle 13B dans 24 Go, un modèle 30B nécessite 64 Go+ (territoire Mac Studio M2/M3/M4 Ultra). Apple Intelligence (le médiateur sur l'appareil pour le triage / la compression de tokens) nécessite un Mac Apple Silicon avec Apple Intelligence activé dans Réglages Système.

**En quoi est-ce différent de Siri ?** Siri répond aux questions. Agent! *effectue des actions* -- contrôle des applications, gère des fichiers, compile du code, automatise des flux de travail.

---

## Documentation

- [Architecture Technique](docs/TECHNICAL.md) -- Outils, scripting, détails pour développeurs
- [Comparaisons](docs/COMPARISON.md) -- vs Claude Code, Cursor, Cline, OpenClaw
- [Modèle de Sécurité](docs/SECURITY.md) -- Architecture XPC, séparation des privilèges
- [FAQ](docs/FAQ.md) -- Questions fréquentes

---

## Outils Xcode Intégrés

Agent! comprend une intégration native à Xcode qui fonctionne sans aucune configuration de serveur MCP. Ces outils intégrés sont souvent plus rapides et plus fiables que l'alternative MCP puisqu'ils s'exécutent directement dans l'application.

| Outil | Ce que ça fait |
|---|---|
| **xcode build** | Compile le projet Xcode actuel, capture les erreurs et avertissements. Les erreurs dans le journal d'activité sont **cliquables** et s'ouvrent directement dans Xcode. |
| **xcode run** | Compile et exécute l'application |
| **xcode list_projects** | Découvre les espaces de travail et projets Xcode ouverts |
| **xcode select_project** | Change de projet actif |
| **xcode grant_permission** | Accorde l'accès aux fichiers au dossier de projet Xcode |
| **xcode get_version** | Lit la version marketing actuelle et le numéro de build du projet Xcode |
| **xcode bump_version** | Incrémente la version marketing (majeure, mineure ou patch), met à jour le numéro de build, compile pour vérifier, et valide automatiquement |
| **xcode bump_build** | Incrémente uniquement le numéro de build |

Dites simplement *« incrémente la version »* et Agent! lit la version actuelle, demande majeure/mineure/patch, met à jour Info.plist et les réglages du projet, compile pour vérifier, et valide la modification. Pas d'édition manuelle de plist, pas de numéros de build oubliés.

L'IA utilise automatiquement ces outils quand vous lui demandez de compiler, corriger des erreurs, ou travailler avec des projets Xcode. Aucune configuration nécessaire -- il suffit d'avoir votre projet ouvert dans Xcode.

> 🚀 **Support iOS/iPadOS :** Bientôt disponible ! Le support natif pour compiler, exécuter et tester des applications iOS et iPadOS directement depuis Agent! est en développement.

> **Astuce :** Pour la plupart des flux de travail de codage, les outils intégrés suffisent. Le serveur MCP Xcode ci-dessous ajoute des extras comme le rendu SwiftUI Preview et la recherche de documentation.


---

<img width="1349" height="1438" alt="Screenshot 2026-04-02 at 12 00 03 PM" src="https://github.com/user-attachments/assets/b0d9346e-f807-4089-bab3-29c7058868d8" />

## Deux façons de parler à Agent! — voix et iMessage

Les deux fonctionnalités utilisent le même mot de réveil : **« Agent! »** (insensible à la casse — `Agent!`, `agent!`, `AGENT!`, même juste `Agent ` ou `agent ` fonctionnent).

### 🎤 Voix (mot-clé de dictée)

Cliquez sur le microphone dans la barre de saisie et démarrez la session de mot-clé, puis parlez. Agent! transcrit en temps réel avec `SFSpeechRecognizer` et écoute le mot « agent » comme mot complet (pas comme sous-chaîne de « intelligent » ou « management »). Tout ce que vous dites après « agent » devient la tâche. Après ~2,5 secondes de silence, la tâche s'exécute automatiquement.

Exemples :
- *« Agent, quelle chanson joue ? »*
- *« Agent prends une capture d'écran de Safari »*
- *« Agent compile le projet Xcode »*

La session de mot-clé boucle automatiquement — une fois une tâche terminée, elle se remet à l'écoute. Cliquez à nouveau sur le micro pour arrêter.

### 📱 iMessage (contrôle à distance)

Envoyez un texto à votre Mac depuis votre iPhone. Agent! interroge `~/Library/Messages/chat.db` toutes les 5 secondes pour les nouveaux messages et réagit à tout ce qui commence par **`Agent!`** (insensible à la casse, le point d'exclamation est facultatif).

Exemples :
```
Agent! Quelle chanson joue ?
agent! vérifie mes e-mails
AGENT! chanson suivante
Agent  ouvre Safari
```

Agent! envoie immédiatement un accusé de réception « Je m'en occupe... », exécute la tâche sur un onglet Messages dédié en utilisant la configuration LLM de votre onglet principal, puis vous renvoie le résultat par texto.

**Configuration (une seule fois) :**

1. **Accordez l'Accès Complet au Disque** — Réglages Système → Confidentialité et Sécurité → Accès Complet au Disque → activez Agent! (requis pour lire `chat.db` directement via SQLite)
2. **Ouvrez le Moniteur de Messages** — bouton #2 de la barre d'outils (icône de bulle de discussion, devient vert quand actif)
3. **Approuvez un expéditeur** — dès qu'un message arrive d'un nouveau contact, ce contact apparaît dans la liste des destinataires. Activez-le pour l'approuver.

Seuls les expéditeurs approuvés peuvent exécuter des tâches. Les messages non approuvés sont enregistrés mais ignorés. Votre réponse est renvoyée via AppleScript au même identifiant qui a envoyé la commande, plafonnée à 4000 caractères.

Les réponses sortantes ont tout « Agent! » initial retiré afin que le Mac destinataire ne déclenche pas sa propre boucle de commandes.

---

Agent! prend en charge les serveurs [MCP](https://modelcontextprotocol.io) pour des capacités étendues. Configurez-les dans Réglages → Serveurs MCP.

### Serveur MCP Xcode

Connectez Agent! directement à Xcode pour des opérations conscientes du projet :

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

**Le MCP Xcode fournit :**
- Opérations de fichiers conscientes du projet (lecture/écriture/modification/suppression)
- Intégration de compilation et de tests
- Rendu SwiftUI Preview
- Exécution d'extraits de code
- Recherche dans la Documentation pour Développeurs Apple
- Suivi des problèmes en temps réel


---

## Licence

MIT - libre et open source.

---

<div align="center">

### **Agent! pour macOS 26.4.1 - IA Agentique pour votre Mac de Bureau**
> Remarque : Claude fait référence au modèle d'IA Anthropic intégré à Agent! pour la fonctionnalité LLM. Ce n'est pas un contributeur humain d'Agent!
</div>

---

## Agent! vs Claude Code — Comparaison Architecturale

Agent! est une application macOS 100 % originale en Swift pur. Ce n'est ni un portage, ni un fork, ni un dérivé d'un autre projet.

| | Claude Code | Agent! |
|---|---|---|
| **Langage** | TypeScript/JavaScript | Swift 6.2 pur |
| **Framework UI** | Ink (React de terminal) | SwiftUI (natif macOS) |
| **Plateforme** | CLI — Linux, macOS, Windows | macOS 26.4.1 natif uniquement |
| **Runtime** | Node.js/Bun | Binaire compilé natif |
| **Architecture** | REPL de terminal avec streaming | Application de bureau avec daemons XPC |
| **Accessibilité** | Aucune (CLI) | AX macOS complet via AXorcist (25 actions de premier niveau, 30+ sous-types AX via `perform_action`) |
| **AppleScript** | Aucun | NSAppleScript + JXA complet sur place avec TCC |
| **Intégration Xcode** | Via Bash (`xcodebuild`) | Native (build/run/analyze/snippet/add_file/bump_version/code_review — 13 actions) |
| **Apple Intelligence** | Aucune | FoundationModels sur l'appareil — gère le tri des salutations/petites discussions, les résumés de tâches, les explications d'erreurs, et la compression de tokens de Niveau 1. L'automatisation d'interface est gérée par le LLM principal via l'outil `accessibility`, pas par Apple AI |
| **ScriptingBridge** | Aucun | SDEF complet + 51 ponts d'événements (Finder, Mail, Music, Safari, Calendar, etc.) |
| **Vision** | Entrée image via API | Entrée image via API |
| **Captures d'écran auto** | Aucune (pas d'UI) | Auto-vérification optionnelle après actions UI (désactivée par défaut — voir `visionAutoScreenshotEnabled`) |
| **iMessage** | Aucun | Agent distant via Messages (Accès Complet au Disque requis pour `chat.db`) |
| **Voix** | Aucune | Dictée ancrée au mot-clé via SFSpeechRecognizer |
| **Effet CRT** | Aucun | Superposition optionnelle de lignes de balayage SwiftUI Canvas (bascule via bouton HUD) |
| **Modèle de Privilège** | Sandbox utilisateur | Launch Agent XPC (utilisateur) + Launch Daemon (root) |
| **Sous-agents** | Outil Task (documenté publiquement ; détails d'implémentation non précisés par Anthropic) | Jusqu'à 3 simultanés (6 en lecture seule) agents isolés avec messagerie par boîte aux lettres et remplacement de modèle par agent |
| **MCP** | stdio/SSE Node.js | Package Swift AgentMCP |
| **Scripts** | Aucun | Compilation dylib Swift à l'exécution, chargée par dlopen sur place avec TCC complet |
| **Cache de prompts** | `cache_control` éphémère d'Anthropic | `cache_control` éphémère d'Anthropic + suivi automatique des hits de cache de préfixe pour OpenAI/Z.ai/Grok/Mistral/Gemini/Qwen/DeepSeek ; `keep_alive: 30m` d'Ollama |
| **Compaction de Contexte** | Claude cloud (tokens payants ; conversation renvoyée à Anthropic) | En paliers : Niveau 1 = résumé sur l'appareil par Apple Intelligence (gratuit, privé, sans tokens API). Niveau 2 = élagage agressif si Apple AI indisponible. Le seuil s'adapte à la fenêtre de contexte du modèle (~55 %, 2K–400K), les résumés sont mémorisés, disjoncteur à 3 échecs, résultats d'outils complets déversés sur disque avant troncature |

## Agent! vs Cursor — Comparaison Rapide

Cursor est un excellent éditeur de code avec IA. Agent! joue un jeu différent : c'est un agent pour tout votre **Mac**, pas seulement votre base de code.

| | Cursor | Agent! |
|---|---|---|
| **Ce que c'est** | Éditeur de code IA (fork de VS Code, Electron) | Application agent SwiftUI native macOS |
| **Portée** | Votre base de code | Tout votre Mac — code, applications, fichiers, système |
| **Tarification** | Abonnement | Gratuit et open source (MIT) — apportez votre propre clé API ou exécutez en local |
| **Modèles locaux** | Cloud d'abord | Ollama, vLLM, LM Studio, Apple Intelligence sur l'appareil |
| **Automatisation d'applications Mac** | Aucune | API Accessibility, AppleScript/JXA, ScriptingBridge (51 ponts d'applications) |
| **Tâches admin au niveau root** | Aucune | Launch Daemon privilégié via XPC (approuvé une fois) |
| **Contrôle voix / iMessage** | Aucun | Dictée par mot-clé + agent distant via Messages |
| **Intégration Xcode** | `xcodebuild` en terminal | Outils natifs de build/run/analyze/code-review |
| **Télémétrie** | Compte cloud requis | Aucune — vos clés, votre machine, vos données |

Si vous vivez dans un seul dépôt toute la journée, Cursor est excellent. Si vous voulez un agent qui compile aussi votre projet Xcode, pilote Safari, vous envoie les résultats par texto, et installe des logiciels en tant que root -- c'est Agent!.

## Contribuer

Envie de bidouiller Agent! ? Consultez [CONTRIBUTING.md](./CONTRIBUTING.md) — vous pouvez compiler depuis les sources en environ 5 minutes avec seulement les Xcode Command Line Tools (`./build.sh`), sans compte Apple Developer requis. Consultez les [good first issues](https://github.com/AgentiLoop/Agent/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) pour des tâches de démarrage bien délimitées.

---


> ⚠️ **Avis Légal et Attribution**
>
> ### Avis de Marque Déposée
>
> « 🦾 Agent! for macOS26 » est un projet logiciel indépendant et n'est **pas** affilié à, approuvé par, sponsorisé par, ni autrement associé à Apple Inc. « Apple », « Mac », « Mac mini », « MacBook », « macOS », et les marques associées sont des marques déposées d'Apple Inc., enregistrées aux États-Unis et dans d'autres pays. Toutes les autres marques déposées, marques de service et noms commerciaux mentionnés ici sont la propriété de leurs détenteurs respectifs et sont utilisés à des fins d'identification uniquement.
>
> « 🦾 Agent! » et le logo 🦾 Agent! sont des marques déposées de Heisenburg. L'utilisation de ces marques nécessite une autorisation écrite préalable. La licence MIT ci-dessous accorde des droits uniquement sur le code source — elle **n'accorde aucun** droit de marque.
>
> ### Licence du Code Source (MIT)
>
> Le code source de « 🦾 Agent! for macOS26 » est open source et sous licence **MIT**. Vous êtes libre d'utiliser, copier, modifier, fusionner, publier, distribuer, sous-licencier et/ou vendre des copies du code source, sous réserve des conditions du fichier [LICENSE](./LICENSE) (conserver l'avis de copyright et l'avis de permission MIT dans toutes les copies ou parties substantielles du logiciel).
>
> ### Binaires Compilés et Releases
>
> Les binaires compilés, installateurs, builds signés, et artefacts de release distribués via les GitHub Releases de ce projet, [AgentiLoop.ai](https://AgentiLoop.ai), ou tout autre canal officiel, sont l'œuvre protégée par le droit d'auteur de Heisenburg et **ne sont pas** couverts par la licence MIT qui régit le code source. Tous les droits sur les binaires officiels — y compris le nom « 🦾 Agent! », le logo, l'identité de signature de code, et le Developer ID — sont réservés.
>
> Copyright © 2000, 2023–2026 Heisenburg, Tous Droits Réservés.
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
> Cordialement,
> **Heisenburg**
> Ingénieur Déployé sur le Terrain, 🦾 Agent! pour macOS 26.4.1
> https://AgentiLoop.ai
> https://github.com/AgentiLoop/agent
