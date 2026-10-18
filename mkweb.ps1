# mkweb.ps1 — versión PowerShell de mkweb.sh (misma conducta, mismas plantillas).
#
# Uso:
#   ./mkweb.ps1 -t vanilla-ts -n mi-app
#   ./mkweb.ps1 --template phaser --name my-game
#   ./mkweb.ps1                 # interactivo (pregunta plantilla y nombre)
#
# Requiere PowerShell 7+ (pwsh) en Linux/macOS; en Windows también funciona
# con Windows PowerShell 5.1.

# Formatters (ANSI, igual que mkweb.sh)
$reset = "$([char]27)[0m"
$muted = "$([char]27)[0;2m"
$red = "$([char]27)[0;91m"
$green = "$([char]27)[0;92m"
$yellow = "$([char]27)[0;93m"
$blue = "$([char]27)[0;94m"
$purple = "$([char]27)[0;95m"
$cyan = "$([char]27)[0;96m"
$white = "$([char]27)[0;97m"
$esc = [char]27

# Estado global (equivale a las variables de mkweb.sh)
$script:IsTypescript = 0
$script:ProjectFolder = ""
$script:ProjectName = ""
$script:Template = ""

# ======== helpers ========

function Enter {
  Write-Host ""
}

function Write {
  param([string]$Text)
  Write-Host $Text
}

function Error {
  param([string]$Message)
  Write-Host "$red[x]$reset $Message"
}

function Success {
  param([string]$Message)
  Write-Host "$green[✓]$reset $Message"
}

function Warning {
  param([string]$Message)
  Write-Host "$yellow[!]$reset $Message"
}

function Info {
  param([string]$Message)
  Write-Host "$cyan[*]$reset $Message"
}

function Banner {
  Write "  $muted           _                  _     $reset"
  Write "  $muted _ __ ___ | | ____      _____| |__  $reset"
  Write "  $muted| '_ `` _ \| |/ /\ \ /\ / / _ \ '_ \ $reset"
  Write "  $muted| | | | | |   <  \ V  V /  __/ |_) |$reset"
  Write "  $muted|_| |_| |_|_|\_\  \_/\_/ \___|_.__/ $reset"
  Enter
  Write "${muted}mkweb es un creador de proyectos para web$reset"
  Enter
}

function Show-Help {
  Info "${white}Usage: ./mkweb.ps1$reset$muted -t$reset$white <template>$reset$muted [options]$reset"
  Enter

  Write "${white}Templates:$reset"
  Write "    ${purple}vanilla$reset      ${yellow}Vanilla JavaScript$reset"
  Write "    ${purple}vanilla-ts$reset   ${yellow}Vanilla TypeScript$reset"
  Write "    ${purple}phaser$reset       ${blue}Phaser JavaScript$reset"
  Write "    ${purple}phaser-ts$reset    ${blue}Phaser TypeScript$reset"
  Enter

  Write "${white}Options:$reset"
  Write "    $purple-t, --template$reset <template>  ${muted}Project template$reset"
  Write "    $purple-n, --name$reset <name>          ${muted}Project name$reset"
  Write "    $purple-h, --help$reset                 ${muted}Show this help panel$reset"
  Enter

  Write "${white}Examples:$reset"
  Write "    $cyan./mkweb.ps1 -t vanilla --name my-project$reset"
  Write "    $cyan./mkweb.ps1 -t phaser-ts -n my-game$reset"
  Write "    $cyan./mkweb.ps1 -t vanilla$reset"
  Enter
}

function Read-ConsoleLine {
  # read -rp equiv: imprime sin salto y lee una línea (funciona con pipes).
  param([Parameter(Mandatory)][string]$Label)
  Write-Host "$Label" -NoNewline
  return [Console]::In.ReadLine()
}

function Prompt-Template {
  Write "${white}Available templates:${reset}"
  Write "    ${purple}vanilla${reset}      ${yellow}Vanilla JavaScript${reset}"
  Write "    ${purple}vanilla-ts${reset}   ${yellow}Vanilla TypeScript${reset}"
  Write "    ${purple}phaser${reset}       ${blue}Phaser JavaScript${reset}"
  Write "    ${purple}phaser-ts${reset}    ${blue}Phaser TypeScript${reset}"
  Enter
  while ($true) {
    $line = Read-ConsoleLine "◇ Template [vanilla/vanilla-ts/phaser/phaser-ts]: "
    if ($null -eq $line -or $line -eq "") {
      Error "Template is required"
      exit 1
    }
    switch ($line) {
      { $_ -in 'vanilla', 'vanilla-ts', 'phaser', 'phaser-ts' } { $script:Template = $line; return }
      default { Error "Unknown template: $line. Choose one of: vanilla, vanilla-ts, phaser, phaser-ts" }
    }
  }
}

function Prompt-ProjectName {
  $line = Read-ConsoleLine "◇ Project name: "
  if ($null -eq $line -or $line -eq "") {
    Error "Project name is required"
    exit 1
  }
  $script:ProjectName = $line
}

# ======== generación: estructura + configs ========

function Set-IsTypeScript {
  if ($Template -in 'vanilla-ts', 'phaser-ts') { $script:IsTypescript = 1 }
  else { $script:IsTypescript = 0 }
}

function New-VanillaStructure {
  $folders = if ($IsTypescript -eq 1) {
    'public/assets/audio', 'public/assets/font', 'src/modules', 'src/assets', 'src/types'
  }
  else {
    'public/assets/audio', 'public/assets/font', 'src/modules', 'src/assets'
  }
  foreach ($f in $folders) { New-Item -ItemType Directory -Force -Path (Join-Path $ProjectFolder $f) | Out-Null }

  if ($IsTypescript -eq 1) {
    $files = 'public/favicon.svg', 'src/types/index.ts', 'src/main.ts', 'vite.config.ts', 'index.html', '.editorconfig', 'README.md', 'package.json', 'tsconfig.json'
  }
  else {
    $files = 'public/style.css', 'src/config.js', 'src/main.js', 'vite.config.js', 'index.html', '.editorconfig', 'README.md', 'package.json', 'jsconfig.json'
  }
  foreach ($f in $files) { New-Item -ItemType File -Force -Path (Join-Path $ProjectFolder $f) | Out-Null }
}

function New-PhaserStructure {
  $folders = if ($IsTypescript -eq 1) {
    'public/assets/audio', 'public/assets/font', 'public/assets/ui', 'src/modules', 'src/scenes', 'src/types'
  }
  else {
    'public/assets/audio', 'public/assets/font', 'public/assets/ui', 'src/modules', 'src/scenes'
  }
  foreach ($f in $folders) { New-Item -ItemType Directory -Force -Path (Join-Path $ProjectFolder $f) | Out-Null }

  if ($IsTypescript -eq 1) {
    $files = 'public/style.css', 'src/scenes/Preloader.ts', 'src/types/index.ts', 'src/config.ts', 'src/main.ts', 'vite.config.ts', 'index.html', '.editorconfig', 'README.md', 'package.json', 'tsconfig.json'
  }
  else {
    $files = 'public/style.css', 'src/scenes/Preloader.js', 'src/config.js', 'src/main.js', 'vite.config.js', 'index.html', '.editorconfig', 'README.md', 'package.json', 'jsconfig.json'
  }
  foreach ($f in $files) { New-Item -ItemType File -Force -Path (Join-Path $ProjectFolder $f) | Out-Null }
}

function Set-PackageJson {
  if ($IsTypescript -eq 1 -and $Template -eq 'vanilla-ts') {
    @"
{
  "name": "$ProjectName",
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
"@ | Set-FileContent "package.json"
  }
  elseif ($IsTypescript -eq 1 -and $Template -eq 'phaser-ts') {
    @"
{
  "name": "$ProjectName",
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
"@ | Set-FileContent "package.json"
  }
  elseif ($Template -eq 'vanilla') {
    @"
{
  "name": "$ProjectName",
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
  }
}
"@ | Set-FileContent "package.json"
  }
  elseif ($Template -eq 'phaser') {
    @"
{
  "name": "$ProjectName",
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
"@ | Set-FileContent "package.json"
  }
}

function Set-FileContent {
  # set_file REL CONTENIDO (por pipeline) - escribe UTF8 sin BOM, un \n final.
  param(
    [Parameter(Mandatory, Position = 0)][string]$Relative,
    [Parameter(Mandatory, ValueFromPipeline)][AllowEmptyString()][string]$Text
  )
  process {
    $t = if ($Text.Length -gt 0) { $Text.TrimEnd() + "`n" } else { $Text }
    [IO.File]::WriteAllText((Join-Path $script:ProjectFolder $Relative), $t, [Text.UTF8Encoding]::new($false))
  }
}

function Set-ConfigFile {
  if ($IsTypescript -eq 1) {
    if ($Template -eq 'phaser-ts') {
      @'
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
'@ | Set-FileContent "tsconfig.json"
    }
    elseif ($Template -eq 'vanilla-ts') {
      @'
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
'@ | Set-FileContent "tsconfig.json"
    }
  }
  else {
    if ($Template -in 'phaser', 'vanilla') {
      @'
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
'@ | Set-FileContent "jsconfig.json"
    }
  }
}

function Set-BaseFiles {
    @'
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
'@ | Set-FileContent ".editorconfig"

    @'
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
'@ | Set-FileContent ".gitignore"

@"
# $ProjectName

Template: ``$Template``

## Scripts

``````sh
npm run dev      # start dev server
npm run build    # build for production
npm run preview  # preview production build
``````
"@ | Set-FileContent "README.md"

    if ($IsTypescript -eq 1) {
        "export {}" | Set-FileContent "src/types/index.ts"
    }

    @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect width="32" height="32" rx="6" fill="#863bff"/><text x="16" y="22" font-size="16" text-anchor="middle" fill="#fff" font-family="sans-serif">W</text></svg>
'@ | Set-FileContent "public/favicon.svg"
}

function Set-IndexHtml {
    $ext = if ($IsTypescript -eq 1) { "ts" } else { "js" }
    if ($Template -in 'phaser', 'phaser-ts') {
        @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>$ProjectName</title>
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
"@ | Set-FileContent "index.html"
    }
    else {
        @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>$ProjectName</title>
    <meta name="viewport" content="width=device-width" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <script type="module" src="/src/main.$ext"></script>
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
"@ | Set-FileContent "index.html"
    }
}

function Set-ViteConfig {
    $ext = "js"; $ref = "jsconfig.json"
    if ($IsTypescript -eq 1) { $ext = "ts"; $ref = "tsconfig.json" }

    if ($Template -in 'vanilla', 'vanilla-ts') {
        @"
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
"@ | Set-FileContent "vite.config.$ext"
    }
    else {
        @"
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
"@ | Set-FileContent "vite.config.$ext"
    }
}

function Set-VanillaSrc {
  $ext = if ($IsTypescript -eq 1) { "ts" } else { "js" }

  # Los estilos de vanilla viven en src/ (como vite-template-ts); el
  # esqueleto JS creó public/style.css, lo removemos si quedó.
  Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $ProjectFolder "public/style.css")

  # src/style.css — simplificado de vite-template-ts/src/style.css
  @'
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
'@ | Set-FileContent "src/style.css"

  if ($IsTypescript -eq 1) {
    # src/counter.ts — de vite-template-ts/src/counter.ts
    @'
export function setupCounter(element: HTMLButtonElement) {
  let counter = 0
  const setCounter = (count: number) => {
    counter = count
    element.innerHTML = `Count is ${counter}`
  }
  element.addEventListener('click', () => setCounter(counter + 1))
  setCounter(0)
}
'@ | Set-FileContent "src/counter.ts"

    # src/main.ts — adaptado de vite-template-ts/src/main.ts (sin assets binarios)
    @'
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
'@ | Set-FileContent "src/main.ts"
  }
  else {
    @'
export function setupCounter(element) {
  let counter = 0
  const setCounter = (count) => {
    counter = count
    element.innerHTML = `Count is ${counter}`
  }
  element.addEventListener('click', () => setCounter(counter + 1))
  setCounter(0)
}
'@ | Set-FileContent "src/counter.js"

    @'
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
'@ | Set-FileContent "src/main.js"

    "export const appName = 'vanilla'" | Set-FileContent "src/config.js"
  }
}

function Set-PhaserSrc {
  # public/style.css — de phaser-template-ts/public/style.css
  @'
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
'@ | Set-FileContent "public/style.css"

  if ($IsTypescript -eq 1) {
    # src/main.ts — de phaser-template-ts/src/main.ts
    @'
import { Game } from 'phaser';
import { config } from './config.js'

new Game(config);
'@ | Set-FileContent "src/main.ts"

    # src/config.ts — de phaser-template-ts/src/config.ts
    @'
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
'@ | Set-FileContent "src/config.ts"

    # src/scenes/Preloader.ts — de phaser-template-ts/src/scenes/Preloader.ts
    @'
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
'@ | Set-FileContent "src/scenes/Preloader.ts"
  }
  else {
    @'
import { Game } from 'phaser';
import { config } from './config.js'

new Game(config);
'@ | Set-FileContent "src/main.js"

    @'
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
'@ | Set-FileContent "src/config.js"

    @'
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
'@ | Set-FileContent "src/scenes/Preloader.js"
  }
}

function CreateProject {
  Set-IsTypeScript
  $script:ProjectFolder = $ProjectName

  if (Test-Path -LiteralPath $ProjectFolder) {
    Error "Directory already exists: $ProjectFolder"
    exit 1
  }

  Info "$($Template) template selected"
  Info "project folder: $($ProjectName)"

  switch ($Template) {
    { $_ -in 'vanilla', 'vanilla-ts' } { New-VanillaStructure }
    { $_ -in 'phaser', 'phaser-ts' } { New-PhaserStructure }
  }

  Set-PackageJson
  Set-ConfigFile
  Set-BaseFiles
  Set-IndexHtml
  Set-ViteConfig

  switch ($Template) {
    { $_ -in 'vanilla', 'vanilla-ts' } { Set-VanillaSrc }
    { $_ -in 'phaser', 'phaser-ts' } { Set-PhaserSrc }
  }

  # Mantener carpetas vacías en git (equivale a find -type d -empty -exec touch)
  Get-ChildItem -LiteralPath $ProjectFolder -Recurse -Directory |
  Sort-Object { $_.FullName.Length } -Descending |
  ForEach-Object {
    $count = (Get-ChildItem -Force -LiteralPath $_.FullName | Measure-Object).Count
    if ($count -eq 0) {
      New-Item -ItemType File -Force -Path (Join-Path $_.FullName ".gitkeep") | Out-Null
    }
  }

  Success "Project '$($ProjectName)' created with template '$($Template)'"
  Write "  ${muted}cd $($ProjectName) && npm install && npm run dev$reset"
}

# ======== entry point ========

function Init {
  # Parsing manual de argumentos - igual que el while/case de mkweb.sh.
  $rest = @()
  foreach ($a in $args) { $rest += $a }
  $i = 0
  while ($i -lt $rest.Count) {
    $token = $rest[$i]
    if ($token -in '-t', '--template') {
      if (($i + 1) -ge $rest.Count -or $rest[$i + 1] -like '-*') {
        Error "Option $token requires an argument"
        exit 1
      }
      $script:Template = $rest[$i + 1]
      $i += 2
      continue
    }
    elseif ($token -in '-n', '--name') {
      if (($i + 1) -ge $rest.Count -or $rest[$i + 1] -like '-*') {
        Error "Option $token requires an argument"
        exit 1
      }
      $script:ProjectName = $rest[$i + 1]
      $i += 2
      continue
    }
    elseif ($token -in '-h', '--help') {
      Banner
      Show-Help
      exit 0
    }
    elseif ($token -eq '--') {
      # bash: shift + break - ignora el resto
      $i = $rest.Count
      continue
    }
    elseif ($token -like '-*') {
      Error "Unknown option: $token"
      Show-Help
      exit 1
    }
    else {
      Error "Unknown argument: $token"
      Show-Help
      exit 1
    }
  }

  # Fallback interactivo: pregunta lo que no vino por flag.
  #   ./mkweb                      -> pregunta plantilla + nombre
  #   ./mkweb -t phaser            -> pregunta sólo nombre
  #   ./mkweb -t vanilla -n mi-app -> pregunta nada
  $bannerShown = 0
  if ([string]::IsNullOrEmpty($script:Template)) {
    Banner
    $bannerShown = 1
    Prompt-Template
  }

  if ($script:Template -notin 'vanilla', 'vanilla-ts', 'phaser', 'phaser-ts') {
    Error "Unknown template: $($script:Template)"
    exit 1
  }

  if ([string]::IsNullOrEmpty($script:ProjectName)) {
    if ($bannerShown -eq 0) {
      Banner
      $bannerShown = 1
    }
    Prompt-ProjectName
  }

  if (Test-Path -LiteralPath $script:ProjectName) {
    Error "Directory already exists: $($script:ProjectName)"
    exit 1
  }

  CreateProject
}

Init @args
