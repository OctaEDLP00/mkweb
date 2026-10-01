#!/bin/bash

# Formatters
reset='\e[0m'
bold='\e[1m'
dim='\e[2m'
italic='\e[3m'
underline='\e[4m'
blink='\e[5m'
reverse='\e[7m'
hidden='\e[8m'
strikethrough='\e[9m'

# Foreground Colors (Bright)
black='\e[0;90m'
red='\e[0;91m'
green='\e[0;92m'
yellow='\e[0;93m'
blue='\e[0;94m'
purple='\e[0;95m'
cyan='\e[0;96m'
white='\e[0;97m'

# Background (Bright)
BgBlack='\e[100m'
BgRed='\e[101m'
BgGreen='\e[102m'
BgYellow='\e[103m'
BgBlue='\e[104m'
BgPurple='\e[105m'
BgCyan='\e[106m'
BGWhite='\e[107m'

muted='\e[0;2m'

export DEBIAN_FRONTEND=noninteractive

set -euo pipefail

trap ctrl_c INT

declare IS_TYPESCRIPT=0
declare PROJECT_FOLDER=""
declare PROJECT_NAME=""
declare TEMPLATE=""
# ======== helpers =========

enter() {
  echo ""
}

write() {
  echo -e "$1"
}

error() {
  echo -e "${red}[x]${reset} $1"
}

success() {
  echo -e "${green}[✓]${reset} $1"
}

warning() {
  echo -e "${yellow}[!]${reset} $1"
}

info() {
  echo -e "${cyan}[*]${reset} $1"
}

ctrl_c() {
  info "\n${yellow}[*]${reset}${white} Saliendo...${reset}"
  tput cnorm 2>/dev/null || true
  exit 0
}

banner() {
  write "  ${muted}           _                  _     ${reset}"
  write "  ${muted} _ __ ___ | | ____      _____| |__  ${reset}"
  write "  ${muted}| '_ \` _ \| |/ /\ \ /\ / / _ \ '_ \ ${reset}"
  write "  ${muted}| | | | | |   <  \ V  V /  __/ |_) |${reset}"
  write "  ${muted}|_| |_| |_|_|\_\  \_/\_/ \___|_.__/ ${reset}"
  enter
  write "${muted}mkweb es un creador de proyectos para web${reset}"
  enter
}

show_help() {
  info "${white}Usage: ./mkweb ${reset}${muted}-t ${reset}${white}<template> ${reset}${muted}[options]${reset}"
  enter

  write "${white}Templates:${reset}"
  write "    ${purple}vanilla${reset}      ${yellow}Vanilla JavaScript${reset}"
  write "    ${purple}vanilla-ts${reset}   ${yellow}Vanilla TypeScript${reset}"
  write "    ${purple}phaser${reset}       ${blue}Phaser JavaScript${reset}"
  write "    ${purple}phaser-ts${reset}    ${blue}Phaser TypeScript${reset}"
  enter

  write "${white}Options:${reset}"
  write "    ${purple}-t, --template${reset} <template>  ${muted}Project template${reset}"
  write "    ${purple}-n, --name${reset} <name>          ${muted}Project name${reset}"
  write "    ${purple}-h, --help${reset}                 ${muted}Show this help panel${reset}"
  enter

  write "${white}Examples:${reset}"
  write "    ${cyan}./mkweb -t vanilla --name my-project${reset}"
  write "    ${cyan}./mkweb -t phaser-ts -n my-game${reset}"
  write "    ${cyan}./mkweb -t vanilla${reset}"
  enter
}

# if [[ -e "$project_name" ]]; then
#   error "Directory already exists: $project_name"
#   exit 1
# fi

modify_config_file() {
  if [[ $IS_TYPESCRIPT -eq 1 ]]; then
    if [[ $TEMPLATE == "phaser-ts" ]]; then
      cat > "$PROJECT_FOLDER/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "lib": [
      "es6",
      "dom",
      "dom.iterable",
      "scripthost"
    ],
    "typeRoots": [ "./node_modules/phaser/types" ],
    "types": [ "phaser" ],
    "paths": {
      "~/*": ["./src/*"]
    }
  }
}
EOF
    elif [[ $TEMPLATE == "vanilla-ts" ]]; then
      cat > "$PROJECT_FOLDER/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "target": "es2023",
    "module": "esnext",
    "lib": ["ES2023", "DOM"],
    "types": ["vite/client"],
    "paths": {
      "~/*": ["./src/*"]
    },
    "allowArbitraryExtensions": true,
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,
    "moduleDetection": "force",
    "noEmit": true,

    /* Linting */
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "erasableSyntaxOnly": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}
EOF
    fi
  else
    if [[ $TEMPLATE == "phaser" ]]; then
      cat > "$PROJECT_FOLDER/jsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "target": "es2023",
    "module": "esnext",
    "lib": ["ES2023", "DOM"],
    "types": ["vite/client"],
    "paths": {
      "~/*": ["./src/*"]
    },
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "moduleDetection": "force",
    "noEmit": true,

    /* Linting */
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}
EOF
    elif [[ $TEMPLATE == "vanilla" ]]; then
      cat > "$PROJECT_FOLDER/jsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "target": "es2023",
    "module": "esnext",
    "lib": ["ES2023", "DOM"],
    "types": ["vite/client"],
    "paths": {
      "~/*": ["./src/*"]
    },
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "moduleDetection": "force",
    "noEmit": true,

    /* Linting */
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}
EOF
    fi
  fi
}

is_typescript() {
  if [[ "$TEMPLATE" == "vanilla-ts" || "$TEMPLATE" == "phaser-ts" ]]; then
    IS_TYPESCRIPT=1
  else
    IS_TYPESCRIPT=0
  fi
}

create_vanilla_structure() {
  if [[ $IS_TYPESCRIPT -eq 1 ]]; then
    local folders=(
      public/assets/audio
      public/assets/font
      src/modules
      src/assets
      src/types
    )
  else
    local folders=(
      public/assets/audio
      public/assets/font
      src/modules
      src/assets
    )
  fi

  for folder in "${folders[@]}"; do
    mkdir -p "$PROJECT_FOLDER/$folder"
  done

  if [[ $IS_TYPESCRIPT -eq 1 ]]; then
    touch "$PROJECT_FOLDER/public/favicon.svg"
    touch "$PROJECT_FOLDER/src/types/index.ts"
    touch "$PROJECT_FOLDER/src/main.ts"
    touch "$PROJECT_FOLDER/vite.config.ts"
    touch "$PROJECT_FOLDER/index.html"
    touch "$PROJECT_FOLDER/.editorconfig"
    touch "$PROJECT_FOLDER/README.md"
    touch "$PROJECT_FOLDER/package.json"
    touch "$PROJECT_FOLDER/tsconfig.json"
  else
    touch "$PROJECT_FOLDER/public/style.css"
    touch "$PROJECT_FOLDER/src/config.js"
    touch "$PROJECT_FOLDER/src/main.js"
    touch "$PROJECT_FOLDER/vite.config.js"
    touch "$PROJECT_FOLDER/index.html"
    touch "$PROJECT_FOLDER/.editorconfig"
    touch "$PROJECT_FOLDER/README.md"
    touch "$PROJECT_FOLDER/package.json"
    touch "$PROJECT_FOLDER/jsconfig.json"
  fi
}

create_phaser_structure() {
  if [[ $IS_TYPESCRIPT -eq 1 ]]; then
    local folders=(
      public/assets/audio
      public/assets/font
      public/assets/ui
      src/modules
      src/scenes
      src/types
    )
  else
    local folders=(
      public/assets/audio
      public/assets/font
      public/assets/ui
      src/modules
      src/scenes
    )
  fi

  for folder in "${folders[@]}"; do
    mkdir -p "$PROJECT_FOLDER/$folder"
  done

  if [[ $IS_TYPESCRIPT -eq 1 ]]; then
    touch "$PROJECT_FOLDER/public/style.css"
    touch "$PROJECT_FOLDER/src/scenes/Preloader.ts"
    touch "$PROJECT_FOLDER/src/types/index.ts"
    touch "$PROJECT_FOLDER/src/config.ts"
    touch "$PROJECT_FOLDER/src/main.ts"
    touch "$PROJECT_FOLDER/vite.config.ts"
    touch "$PROJECT_FOLDER/index.html"
    touch "$PROJECT_FOLDER/.editorconfig"
    touch "$PROJECT_FOLDER/README.md"
    touch "$PROJECT_FOLDER/package.json"
    touch "$PROJECT_FOLDER/tsconfig.json"
  else
    touch "$PROJECT_FOLDER/public/style.css"
    touch "$PROJECT_FOLDER/src/scenes/Preloader.js"
    touch "$PROJECT_FOLDER/src/config.js"
    touch "$PROJECT_FOLDER/src/main.js"
    touch "$PROJECT_FOLDER/vite.config.js"
    touch "$PROJECT_FOLDER/index.html"
    touch "$PROJECT_FOLDER/.editorconfig"
    touch "$PROJECT_FOLDER/README.md"
    touch "$PROJECT_FOLDER/package.json"
    touch "$PROJECT_FOLDER/jsconfig.json"
  fi
}

modify_package_json() {
  if [[ $IS_TYPESCRIPT -eq 1 ]]; then
    if [[ "$TEMPLATE" == "vanilla-ts" ]]; then
    cat > "$PROJECT_FOLDER/package.json" <<EOF
{
  "name": "$PROJECT_NAME",
  "private": true,
  "version": "0.0.0",
  "description": "",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "@types/node": "latest",
    "typescript": "latest",
    "vite": "latest"
  }
}
EOF
    elif [[ "$TEMPLATE" == "phaser-ts" ]]; then
      cat > "$PROJECT_FOLDER/package.json" <<EOF
{
  "name": "$PROJECT_NAME",
  "private": true,
  "version": "0.0.0",
  "description": "",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "@types/node": "latest",
    "vite": "latest"
  },
  "dependencies": {
    "phaser": "latest"
  }
}
EOF
    fi
  else
    if [[ "$TEMPLATE" == "vanilla" ]]; then
      cat > "$PROJECT_FOLDER/package.json" <<EOF
{
  "name": "$PROJECT_NAME",
  "private": true,
  "version": "0.0.0",
  "description": "",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "@types/node": "latest"
    "vite": "latest"
  }
}
EOF
    elif [[ "$TEMPLATE" == "phaser" ]]; then
      cat > "$PROJECT_FOLDER/package.json" <<EOF
{
  "name": "$PROJECT_NAME",
  "private": true,
  "version": "0.0.0",
  "description": "",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "@types/node": "latest"
    "vite": "latest"
  },
  "dependencies": {
    "phaser": "latest"
  }
}
EOF
    fi
  fi
}

# ======== file contents (based on vite-template-ts/ and phaser-template-ts/) =========

prompt_template() {
  write "${white}Available templates:${reset}"
  write "    ${purple}vanilla${reset}      ${yellow}Vanilla JavaScript${reset}"
  write "    ${purple}vanilla-ts${reset}   ${yellow}Vanilla TypeScript${reset}"
  write "    ${purple}phaser${reset}       ${blue}Phaser JavaScript${reset}"
  write "    ${purple}phaser-ts${reset}    ${blue}Phaser TypeScript${reset}"
  enter
  while true; do
    read -rp "◇ Template [vanilla/vanilla-ts/phaser/phaser-ts]: " TEMPLATE || {
      error "Template is required"
      exit 1
    }
    case "$TEMPLATE" in
      vanilla | vanilla-ts | phaser | phaser-ts) break ;;
      *) error "Unknown template: $TEMPLATE. Choose one of: vanilla, vanilla-ts, phaser, phaser-ts" ;;
    esac
  done
}

prompt_project_name() {
  read -rp "◇ Project name: " PROJECT_NAME || {
    error "Project name is required"
    exit 1
  }
  if [[ -z "$PROJECT_NAME" ]]; then
    error "Project name is required"
    exit 1
  fi
}

write_base_files() {
  cat > "$PROJECT_FOLDER/.editorconfig" <<'EOF'
# EditorConfig is awesome: https://EditorConfig.org

# top-most EditorConfig file
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = false
insert_final_newline = false
EOF

  cat > "$PROJECT_FOLDER/.gitignore" <<'EOF'
# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

node_modules
dist
dist-ssr
*.local

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
.DS_Store
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?
EOF

  cat > "$PROJECT_FOLDER/README.md" <<EOF
# $PROJECT_NAME

Template: \`$TEMPLATE\`

## Scripts

\`\`\`sh
npm run dev      # start dev server
npm run build    # build for production
npm run preview  # preview production build
\`\`\`
EOF

  if [[ $IS_TYPESCRIPT -eq 1 ]]; then
    printf 'export {}\n' > "$PROJECT_FOLDER/src/types/index.ts"
  fi

  # Minimal placeholder so <link rel="icon"> never 404s
  # (reference templates ship binary favicons that cannot be inlined here).
  cat > "$PROJECT_FOLDER/public/favicon.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect width="32" height="32" rx="6" fill="#863bff"/><text x="16" y="22" font-size="16" text-anchor="middle" fill="#fff" font-family="sans-serif">W</text></svg>
EOF
}

write_index_html() {
  if [[ "$TEMPLATE" == phaser || "$TEMPLATE" == phaser-ts ]]; then
    local ext="js"
    [[ $IS_TYPESCRIPT -eq 1 ]] && ext="ts"
    cat > "$PROJECT_FOLDER/index.html" <<EOF
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>$PROJECT_NAME</title>
    <meta name="viewport" content="width=device-width" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <link rel="stylesheet" href="/style.css">
    <script type="module" src="/src/main.$ext"></script>
  </head>
  <body>
    <div id="app">
      <div id="game-container"></div>
    </div>
  </body>
</html>
EOF
  else
    local ext="js"
    [[ $IS_TYPESCRIPT -eq 1 ]] && ext="ts"
    cat > "$PROJECT_FOLDER/index.html" <<EOF
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>$PROJECT_NAME</title>
    <meta name="viewport" content="width=device-width" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <script type="module" src="/src/main.$ext"></script>
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
EOF
  fi
}

write_vanilla_src() {
  local ext="js"
  [[ $IS_TYPESCRIPT -eq 1 ]] && ext="ts"

  # Vanilla styles live in src/ (like vite-template-ts). The JS skeleton
  # touches public/style.css, so remove that leftover if present.
  rm -f "$PROJECT_FOLDER/public/style.css"

  # src/style.css — simplified from vite-template-ts/src/style.css
  cat > "$PROJECT_FOLDER/src/style.css" <<'EOF'
:root {
  color-scheme: light dark;
  font-family: system-ui, sans-serif;
}

body {
  margin: 0;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
}

#app {
  text-align: center;
}

button {
  font: inherit;
  padding: 8px 16px;
  cursor: pointer;
}
EOF

  if [[ $IS_TYPESCRIPT -eq 1 ]]; then
    # src/counter.ts — from vite-template-ts/src/counter.ts
    cat > "$PROJECT_FOLDER/src/counter.ts" <<'EOF'
export function setupCounter(element: HTMLButtonElement) {
  let counter = 0
  const setCounter = (count: number) => {
    counter = count
    element.innerHTML = `Count is ${counter}`
  }
  element.addEventListener('click', () => setCounter(counter + 1))
  setCounter(0)
}
EOF
    # src/main.ts — adapted from vite-template-ts/src/main.ts (no binary assets)
    cat > "$PROJECT_FOLDER/src/main.ts" <<'EOF'
import './style.css'
import { setupCounter } from './counter.ts'

document.querySelector<HTMLDivElement>('#app')!.innerHTML = `
  <div>
    <h1>Get started</h1>
    <p>Edit <code>src/main.ts</code> and save to test <code>HMR</code></p>
  </div>
  <button id="counter" type="button"></button>
`

setupCounter(document.querySelector<HTMLButtonElement>('#counter')!)
EOF
  else
    cat > "$PROJECT_FOLDER/src/counter.js" <<'EOF'
export function setupCounter(element) {
  let counter = 0
  const setCounter = (count) => {
    counter = count
    element.innerHTML = `Count is ${counter}`
  }
  element.addEventListener('click', () => setCounter(counter + 1))
  setCounter(0)
}
EOF
    cat > "$PROJECT_FOLDER/src/main.js" <<'EOF'
import './style.css'
import { setupCounter } from './counter.js'

document.querySelector('#app').innerHTML = `
  <div>
    <h1>Get started</h1>
    <p>Edit <code>src/main.js</code> and save to test <code>HMR</code></p>
  </div>
  <button id="counter" type="button"></button>
`

setupCounter(document.querySelector('#counter'))
EOF
    cat > "$PROJECT_FOLDER/src/config.js" <<'EOF'
export const appName = 'vanilla'
EOF
  fi
}

write_phaser_src() {
  # public/style.css — from phaser-template-ts/public/style.css
  cat > "$PROJECT_FOLDER/public/style.css" <<'EOF'
body {
  margin: 0;
  padding: 0;
  color: rgba(255, 255, 255, 0.87);
  background-color: #000000;
}

#app {
  width: 100%;
  height: 100vh;
  overflow: hidden;
  display: flex;
  justify-content: center;
  align-items: center;
}
EOF

  if [[ $IS_TYPESCRIPT -eq 1 ]]; then
    # src/main.ts — from phaser-template-ts/src/main.ts
    cat > "$PROJECT_FOLDER/src/main.ts" <<'EOF'
import { Game } from 'phaser';
import { config } from './config.js'

new Game(config);
EOF
    # src/config.ts — from phaser-template-ts/src/config.ts
    cat > "$PROJECT_FOLDER/src/config.ts" <<'EOF'
import { Preloader } from './scenes/Preloader.js';
import { Types } from 'phaser';

export const config = {
  title: 'Card Memory Game',
  type: Phaser.AUTO,
  width: 549,
  height: 480,
  parent: 'game-container',
  backgroundColor: '#192a56',
  pixelArt: true,
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH
  },
  scene: [
    Preloader
  ],

} satisfies Types.Core.GameConfig;
EOF
    # src/scenes/Preloader.ts — from phaser-template-ts/src/scenes/Preloader.ts
    cat > "$PROJECT_FOLDER/src/scenes/Preloader.ts" <<'EOF'
import { Scene } from 'phaser';

export class Preloader extends Scene {
  constructor() {
    super({
      key: 'Preloader'
    });
  }

  preload() {
    this.load.setPath("assets/");

    this.load.image("volume-icon", "ui/volume-icon.png");
    this.load.image("volume-icon_off", "ui/volume-icon_off.png");

    this.load.audio("theme-song", "audio/fat-caps-audionatix.mp3");
    this.load.audio("whoosh", "audio/whoosh.mp3");
    this.load.audio("card-flip", "audio/card-flip.mp3");
    this.load.audio("card-match", "audio/card-match.mp3");
    this.load.audio("card-mismatch", "audio/card-mismatch.mp3");
    this.load.audio("card-slide", "audio/card-slide.mp3");
    this.load.audio("victory", "audio/victory.mp3");
    this.load.image("background");
    this.load.image("card-back", "cards/card-back.png");
    this.load.image("card-0", "cards/card-0.png");
    this.load.image("card-1", "cards/card-1.png");
    this.load.image("card-2", "cards/card-2.png");
    this.load.image("card-3", "cards/card-3.png");
    this.load.image("card-4", "cards/card-4.png");
    this.load.image("card-5", "cards/card-5.png");

    this.load.image("heart", "ui/heart.png");

  }

  create() {
    this.scene.start("Play");
  }
}
EOF
  else
    cat > "$PROJECT_FOLDER/src/main.js" <<'EOF'
import { Game } from 'phaser';
import { config } from './config.js'

new Game(config);
EOF
    cat > "$PROJECT_FOLDER/src/config.js" <<'EOF'
import { Preloader } from './scenes/Preloader.js';

/**
 * @type {import('phaser').Types.Core.GameConfig}
 */
export const config = {
  title: 'Card Memory Game',
  type: Phaser.AUTO,
  width: 549,
  height: 480,
  parent: 'game-container',
  backgroundColor: '#192a56',
  pixelArt: true,
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH
  },
  scene: [
    Preloader
  ],
};
EOF
    cat > "$PROJECT_FOLDER/src/scenes/Preloader.js" <<'EOF'
import { Scene } from 'phaser';

export class Preloader extends Scene {
  constructor() {
    super({
      key: 'Preloader'
    });
  }

  preload() {
    this.load.setPath("assets/");

    this.load.image("volume-icon", "ui/volume-icon.png");
    this.load.image("volume-icon_off", "ui/volume-icon_off.png");

    this.load.audio("theme-song", "audio/fat-caps-audionatix.mp3");
    this.load.audio("whoosh", "audio/whoosh.mp3");
    this.load.audio("card-flip", "audio/card-flip.mp3");
    this.load.audio("card-match", "audio/card-match.mp3");
    this.load.audio("card-mismatch", "audio/card-mismatch.mp3");
    this.load.audio("card-slide", "audio/card-slide.mp3");
    this.load.audio("victory", "audio/victory.mp3");
    this.load.image("background");
    this.load.image("card-back", "cards/card-back.png");
    this.load.image("card-0", "cards/card-0.png");
    this.load.image("card-1", "cards/card-1.png");
    this.load.image("card-2", "cards/card-2.png");
    this.load.image("card-3", "cards/card-3.png");
    this.load.image("card-4", "cards/card-4.png");
    this.load.image("card-5", "cards/card-5.png");

    this.load.image("heart", "ui/heart.png");

  }

  create() {
    this.scene.start("Play");
  }
}
EOF
  fi
}

write_vite_config() {
  local ext="js" ref="jsconfig.json"
  if [[ $IS_TYPESCRIPT -eq 1 ]]; then
    ext="ts"
    ref="tsconfig.json"
  fi

  if [[ "$TEMPLATE" == vanilla || "$TEMPLATE" == vanilla-ts ]]; then
    cat > "$PROJECT_FOLDER/vite.config.$ext" <<EOF
import { defineConfig } from 'vite'
import path from 'node:path'

export default defineConfig({
  resolve: {
    alias: {
      // Mirrors the "~/*" mapping in $ref
      '~': path.resolve(process.cwd(), 'src')
    }
  }
})
EOF
  else
    cat > "$PROJECT_FOLDER/vite.config.$ext" <<EOF
import { defineConfig } from 'vite';
import path from 'node:path';

export default defineConfig({
  resolve: {
    alias: {
      // Mirrors the "~/*" mapping in $ref
      '~': path.resolve(process.cwd(), 'src'),
    },
  },
});
EOF
  fi
}

create_project() {
  is_typescript
  PROJECT_FOLDER="$PROJECT_NAME"

  if [[ -e "$PROJECT_FOLDER" ]]; then
    error "Directory already exists: $PROJECT_FOLDER"
    exit 1
  fi

  info "$TEMPLATE template selected"
  info "project folder: $PROJECT_NAME"

  case "$TEMPLATE" in
    vanilla | vanilla-ts)
      create_vanilla_structure
      ;;
    phaser | phaser-ts)
      create_phaser_structure
      ;;
  esac

  modify_package_json
  modify_config_file
  write_base_files
  write_index_html
  write_vite_config

  case "$TEMPLATE" in
    vanilla | vanilla-ts)
      write_vanilla_src
      ;;
    phaser | phaser-ts)
      write_phaser_src
      ;;
  esac

  # Keep empty asset folders in git
  find "$PROJECT_FOLDER" -type d -empty -exec touch "{}/.gitkeep" \;

  success "Project '$PROJECT_NAME' created with template '$TEMPLATE'"
  write "  ${muted}cd ${PROJECT_NAME} && npm install && npm run dev${reset}"
}

# ======== entry point =========

init() {
  trap 'tput cnorm 2>/dev/null || true' EXIT

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t | --template)
        if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
          error "Option $1 requires an argument"
          exit 1
        fi

        TEMPLATE="$2"
        shift 2
        ;;
      -n | --name)
        if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
          error "Option $1 requires an argument"
          exit 1
        fi

        PROJECT_NAME="$2"
        shift 2
        ;;
      -h | --help)
        banner
        show_help
        exit 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        error "Unknown option: $1"
        show_help
        exit 1
        ;;
      *)
        error "Unknown argument: $1"
        show_help
        exit 1
        ;;
    esac
  done

  # Interactive fallback: ask for whatever was not passed as a flag.
  #   ./mkweb                      -> asks template + name
  #   ./mkweb -t phaser            -> asks only name
  #   ./mkweb -t vanilla -n myapp  -> asks nothing
  local banner_shown=0
  if [[ -z "${TEMPLATE:-}" ]]; then
    banner
    banner_shown=1
    prompt_template
  fi

  case "$TEMPLATE" in
    vanilla | vanilla-ts | phaser | phaser-ts) ;;
    *)
      error "Unknown template: $TEMPLATE"
      exit 1
      ;;
  esac

  if [[ -z "${PROJECT_NAME:-}" ]]; then
    if [[ $banner_shown -eq 0 ]]; then
      banner
      banner_shown=1
    fi
    prompt_project_name
  fi

  if [[ -e "$PROJECT_NAME" ]]; then
    error "Directory already exists: $PROJECT_NAME"
    exit 1
  fi

  create_project
}

init "$@"
