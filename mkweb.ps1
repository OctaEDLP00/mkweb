# ============ Parameters ===============
[CmdletBinding()]
param (
  [alias('T')]
  [ValidateSet("vanilla", "vanilla-ts", "phaser", "phaser-ts")]
  [string]$Template,
  [alias('N')]
  [ValidateNotNullOrEmpty()]
  [string]$Name,
  [alias('P')]
  [ValidateSet("pnpm", "npm", "yarn", "bun", "nube", "nub", "utoo", "upm")]
  [string]$Pm,
  [alias('I')]
  [switch]$Install,
  [alias('H')]
  [switch]$Help
)

# ============ Enums & Classes ===============

<# enum LogTYpe {
  Info = "info"
  Success = "success"
  Error = "error"
  Warning = "warning"
  Question = "question"
  Debug = "debug"
} #>

enum ProjectEngine {
  Vanilla
  Phaser
}

enum ProjectLanguage {
  JavaScript
  TypeScript
}

class ProjectTemplate {
  [string]$Name
  [ProjectEngine]$Engine
  [ProjectLanguage]$Language

  ProjectTemplate(
    [string]$Name,
    [ProjectEngine]$Engine,
    [ProjectLanguage]$Language
  ) {
    $this.Name = $Name
    $this.Engine = $Engine
    $this.Language = $Language
  }

  [bool] IsTypeScript() {
    return $this.Language -eq [ProjectLanguage]::TypeScript
  }
}

class ProjectContext {
  [string]$Name
  [string]$ProjectPath
  [string]$RootPath
  [string]$PackageManager
  [ProjectTemplate]$Template

  ProjectContext(
    [string]$Name,
    [string]$PackageManager,
    [ProjectTemplate]$Template
  ) {
    $this.Name = $Name
    $this.RootPath = (Get-Location).Path
    $this.ProjectPath = Join-Path $this.RootPath $Name
    $this.PackageManager = $PackageManager
    $this.Template = $Template
  }
}

# ============ Configuration ===============

if (-not ('MkwebCancellation' -as [type])) {
  Add-Type -TypeDefinition @'
using System;

public static class MkwebCancellation {
  private static volatile bool _cancelled;
  private static bool _registered;

  public static bool IsCancelled => _cancelled;

  public static void Register() {
    _cancelled = false;
    if (_registered) return;
    Console.CancelKeyPress += HandleCancelKeyPress;
    _registered = true;
  }

  public static void Unregister() {
    if (!_registered) return;
    Console.CancelKeyPress -= HandleCancelKeyPress;
    _registered = false;
  }

  private static void HandleCancelKeyPress(
    object sender,
    ConsoleCancelEventArgs e
  ) {
    e.Cancel = true;
    _cancelled = true;
  }
}
'@
}

$script:AllowedTemplates = @(
  'vanilla'
  'vanilla-ts'
  'phaser'
  'phaser-ts'
)

$script:AllowedPackageManagers = @(
  'pnpm'
  'npm'
  'yarn'
  'bun'
  'nube'
  'nub'
  'utoo'
  'upm'
)

$script:LogTypes = @{
  info     = @{
    Label        = 'INFO'
    BracketColor = 'DarkGray'
    LabelColor   = 'Cyan'
  }
  success  = @{
    Label        = 'SUCCESS'
    BracketColor = 'DarkGray'
    LabelColor   = 'Green'
  }
  error    = @{
    Label        = 'ERROR'
    BracketColor = 'DarkGray'
    LabelColor   = 'Red'
  }
  warning  = @{
    Label        = 'WARNING'
    BracketColor = 'DarkGray'
    LabelColor   = 'Yellow'
  }
  question = @{
    Label        = 'QUESTION'
    BracketColor = 'DarkGray'
    LabelColor   = 'Magenta'
  }
  debug    = @{
    Label        = 'DEBUG'
    BracketColor = 'Yellow'
    LabelColor   = 'Magenta'
  }
}

$script:Templates = @{
  'vanilla'    = [ProjectTemplate]::new(
    'Vanilla JavaScript',
    [ProjectEngine]::Vanilla,
    [ProjectLanguage]::JavaScript
  )

  'vanilla-ts' = [ProjectTemplate]::new(
    'Vanilla TypeScript',
    [ProjectEngine]::Vanilla,
    [ProjectLanguage]::TypeScript
  )

  'phaser'     = [ProjectTemplate]::new(
    'Phaser JavaScript',
    [ProjectEngine]::Phaser,
    [ProjectLanguage]::JavaScript
  )

  'phaser-ts'  = [ProjectTemplate]::new(
    'Phaser TypeScript',
    [ProjectEngine]::Phaser,
    [ProjectLanguage]::TypeScript
  )
}

# ============ Function Utils ===============

function Assert-NotCancelled {
  if ([MkwebCancellation]::IsCancelled) {
    throw [System.OperationCanceledException]::new(
      'Operation cancelled by user'
    )
  }
}

function Read-ConsoleLine {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [string]$Label
  )

  Assert-NotCancelled
  Write-Color '?', " $Label" White, DarkGray -NoNewLine

  # Preserve standard input behavior when input is redirected
  if ([Console]::IsInputRedirected) {
    $value = [Console]::ReadLine()
    Assert-NotCancelled
    return $value
  }

  $buffer = [System.Text.StringBuilder]::new()

  while ($true) {
    Assert-NotCancelled

    if (-not [Console]::KeyAvailable) {
      Start-Sleep -Milliseconds 25
      continue
    }

    $key = [Console]::ReadKey($true)

    switch ($key.Key) {
      Enter {
        [Console]::WriteLine()
        return $buffer.ToString()
      }

      Backspace {
        if ($buffer.Length -gt 0) {
          $buffer.Length--
          [Console]::Write("`b `b")
        }
      }

      default {
        if (-not [char]::IsControl($key.KeyChar)) {
          $null = $buffer.Append($key.KeyChar)
          [Console]::Write($key.KeyChar)
        }
      }
    }
  }
}

function Show-Banner {
  Write-Color "           _                  _     " DarkGray
  Write-Color " _ __ ___ | | ____      _____| |__  " DarkGray
  Write-Color "| '_ `` _ \| |/ /\ \ /\ / / _ \ '_ \" DarkGray
  Write-Color "| | | | | |   <  \ V  V /  __/ |_) |" DarkGray
  Write-Color "|_| |_| |_|_|\_\  \_/\_/ \___|_.__/ " DarkGray
  Write-Host
  Write-Color "mkweb is a project creator for the web" DarkGray
  Write-Host
}

function Show-Usage {
  Write-Color "USAGE" White
  Write-Host
  Write-Color "    ./mkweb.ps1 ", "-Template ", "<template> ", "-Name ", "<name> ", "-Pm ", "<package_manager>" Cyan, DarkGray, White, DarkGray, White, DarkGray, White
}

function Show-Templates {
  Write-Color "TEMPLATES" White
  Write-Host
  Write-Color "    vanilla", "     # Vanilla", " JavaScript" DarkMagenta, DarkGray, Yellow
  Write-Color "    phaser", "      # Phaser", " JavaScript" DarkMagenta, DarkGray, Yellow
  Write-Color "    vanilla-ts", "  # Vanilla", " TypeScript" DarkMagenta, DarkGray, Blue
  Write-Color "    phaser-ts", "   # Phaser", " TypeScript" DarkMagenta, DarkGray, Blue
}

function Show-Options {
  Write-Color "OPTIONS" White
  Write-Host
  Write-Color "    -N, -Name ", "<name>          ", "# Project name" DarkGray, White, DarkGray
  Write-Color "    -T, -Template ", "<template>  ", "# Project template (vanilla|phaser|vanilla-ts|phaser-ts)" DarkGray, White, DarkGray
  Write-Color "    -P, -Pm ", "<value>", "           # Package manager (pnpm|npm|yarn|bun|nube|nub|utoo|upm)" DarkGray, White, DarkGray
  Write-Color "    -I, -Install              # Install dependencies with selected package manager" DarkGray
  Write-Color "    -H, -Help                 # Show this help panel" DarkGray
}

function Show-Examples {
  Write-Color "EXAMPLES" White
  Write-Host
  Write-Color "    ./mkweb.ps1 ", "-T ", "vanilla ", "-N ", "my-project" Cyan, DarkGray, White, DarkGray, White
  Write-Color "    ./mkweb.ps1 ", "-T ", "phaser-ts ", "-N ", "my-game" Cyan, DarkGray, White, DarkGray, White
  Write-Color "    ./mkweb.ps1 ", "-T ", "vanilla" Cyan, DarkGray, White
}

function Show-Help {
  Show-Banner
  Show-Usage
  Write-Host
  Show-Templates
  Write-Host
  Show-Options
  Write-Host
  Show-Examples
  Write-Host
}

function ConvertTo-CapitalizedString {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]$InputString
  )

  process {
    if ([string]::IsNullOrWhiteSpace($InputString)) {
      return $InputString
    }

    $textInfo = [System.Globalization.CultureInfo]::InvariantCulture.TextInfo

    return $textInfo.ToUpper($InputString.Substring(0, 1)) + $InputString.Substring(1)
  }
}

# ============ Console UI ===============

function Write-Color {
  <#
    .LINK
    [PSWriteColor | PSGalery](https://www.powershellgallery.com/packages/PSWriteColor/1.0.3)
    [Github Repository](https://github.com/EvotecIT/PSWriteColor)
   #>
  [alias('Write-Colour')]
  [CmdletBinding()]
  param (
    [alias ('T')] [String[]]$Text,
    [alias ('C', 'ForegroundColor', 'FGC')] [ConsoleColor[]]$Color = [ConsoleColor]::White,
    [alias ('B', 'BGC')] [ConsoleColor[]]$BackGroundColor = $null,
    [alias ('Indent')][int] $StartTab = 0,
    [int] $LinesBefore = 0,
    [int] $LinesAfter = 0,
    [int] $StartSpaces = 0,
    [alias ('L')] [string] $LogFile = '',
    [Alias('DateFormat', 'TimeFormat')][string] $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss',
    [alias ('LogTimeStamp')][bool] $LogTime = $true,
    [int] $LogRetry = 2,
    [ValidateSet('unknown', 'string', 'unicode', 'bigendianunicode', 'utf8', 'utf7', 'utf32', 'ascii', 'default', 'oem')][string]$Encoding = 'Unicode',
    [switch] $ShowTime,
    [switch] $NoNewLine,
    [switch] $HorizontalCenter,
    [alias('HideConsole')][switch] $NoConsoleOutput
  )
  if (-not $NoConsoleOutput) {
    $DefaultColor = $Color[0]
    if ($null -ne $BackGroundColor -and $BackGroundColor.Count -ne $Color.Count) {
      Write-Error "Colors, BackGroundColors parameters count doesn't match. Terminated."
      return
    }
    if ($LinesBefore -ne 0) { for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } } # Add empty line before
    if ($HorizontalCenter) {
      $MessageLength = 0
      foreach ($Value in $Text) {
        $MessageLength += $Value.Length
      }

      $WindowWidth = $Host.UI.RawUI.BufferSize.Width
      $CenterPosition = [Math]::Max(0, $WindowWidth / 2 - [Math]::Floor($MessageLength / 2))

      # Only write spaces to the console if window width is greater than the message length
      if ($WindowWidth -ge $MessageLength) {
        Write-Host ("{0}" -f (' ' * $CenterPosition)) -NoNewline
      }
    } # Center the line horizontally according to the powershell window size
    if ($StartTab -ne 0) { for ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewline } }  # Add TABS before text
    if ($StartSpaces -ne 0) { for ($i = 0; $i -lt $StartSpaces; $i++) { Write-Host ' ' -NoNewline } }  # Add SPACES before text
    if ($ShowTime) { Write-Host "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline } # Add Time before output
    if ($Text.Count -ne 0) {
      if ($Color.Count -ge $Text.Count) {
        # the real deal coloring
        if ($null -eq $BackGroundColor) {
          for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewline }
        }
        else {
          for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline }
        }
      }
      else {
        if ($null -eq $BackGroundColor) {
          for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewline }
          for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewline }
        }
        else {
          for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline }
          for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -BackgroundColor $BackGroundColor[0] -NoNewline }
        }
      }
    }
    if ($NoNewLine -eq $true) { Write-Host -NoNewline } else { Write-Host } # Support for no new line
    if ($LinesAfter -ne 0) { for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host -Object "`n" -NoNewline } }  # Add empty line after
  }
  if ($Text.Count -and $LogFile) {
    # Save to file
    $TextToFile = ""
    for ($i = 0; $i -lt $Text.Length; $i++) {
      $TextToFile += $Text[$i]
    }
    $Saved = $false
    $Retry = 0
    do {
      $Retry++
      try {
        if ($LogTime) {
          "[$([datetime]::Now.ToString($DateTimeFormat))] $TextToFile" | Out-File $LogFile $Encoding -Append -ErrorAction Stop -WhatIf:$false
        }
        else {
          "$TextToFile" | Out-File $LogFile $Encoding -Append -ErrorAction Stop -WhatIf:$false
        }
        $Saved = $true
      }
      catch {
        if ($Saved -eq $false -and $Retry -eq $LogRetry) {
          Write-Warning "Write-Color - Couldn't write to log file $($_.Exception.Message). Tried ($Retry/$LogRetry))"
        }
        else {
          Write-Warning "Write-Color - Couldn't write to log file $($_.Exception.Message). Retrying... ($Retry/$LogRetry)"
        }
      }
    } until ($Saved -eq $true -or $Retry -ge $LogRetry)
  }
}

function Write-LogMessage {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateSet(
      'info',
      'success',
      'error',
      'warning',
      'question',
      'debug'
    )]
    [string] $Type,

    [Parameter(Mandatory)]
    [object] $Message
  )

  $Type = $Type.Trim().ToLowerInvariant()
  $logs = $script:LogTypes[$Type]

  # Prefijo [ INFO ]
  Write-Color `
    -Text '[', $logs.Label, ']' `
    -Color $logs.BracketColor, $logs.LabelColor, $logs.BracketColor `
    -NoNewLine

  Write-Color -Text ' ' -NoNewLine

  # Mensaje
  if ($Message -is [array]) {
    Write-Color $Message
  }
  else {
    Write-Color $Message White -LinesAfter 1
  }
}

function Write-LastMessage {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ProjectContext]$Context,
    [switch]$Install
  )

  Write-Color "cd $($Context.ProjectPath.Split([char[]]@('/'))[-1])"
  if (-not $Install.IsPresent) {
    Write-Color "pnpm install"
  }
  Write-Color "pnpm run dev"
  Write-Host
  Write-Color "🎉 Happy Coding!!"
}

# ============ Interactive Function Utils ===============

function Resolve-ProjectName {
  [CmdletBinding()]
  param (
    [string]$Value
  )
  if (-not $Value) { $Value = Read-ConsoleLine 'Project name: ' }
  return $Value
}

function Resolve-ProjectTemplate {
  [CmdletBinding()]
  param (
    [string]$Value
  )

  while ($true) {
    if (-not $Value) { $Value = Read-ConsoleLine 'Project template: ' }
    $Value = $Value.Trim().ToLowerInvariant()
    if ($Value -in $script:AllowedTemplates) { return $Value }
    Write-LogMessage warning "Unknown template: $Value"
    Write-LogMessage info "Available templates: $($script:AllowedTemplates -join ', ')"
    $Value = $null
  }
}

function Resolve-PackageManager {
  [CmdletBinding()]
  param (
    [string]$Value
  )

  while ($true) {
    if (-not $Value) { $Value = Read-ConsoleLine 'Package manager: ' }
    $Value = $Value.Trim().ToLowerInvariant()
    if ($Value -in $script:AllowedPackageManagers) { return $Value }
    Write-LogMessage warning "Unknown package manager: $Value"
    Write-LogMessage info "Available package managers: $($script:AllowedPackageManagers -join ', ')"
    $Value = $null
  }
}

function Resolve-Install {
  [CmdletBinding()]
  param (
    [switch]$Value,
    [switch]$Interactive
  )

  if ($Value.IsPresent) {
    return $true
  }

  if (-not $Interactive.IsPresent) {
    return $false
  }

  while ($true) {
    $answer = Read-ConsoleLine 'Install dependencies? (y/n): '
    $answer = $answer.Trim().ToLowerInvariant()

    switch ($answer) {
      { $_ -in @('y', 'yes') } {
        return $true
      }

      { $_ -in @('n', 'no') } {
        return $false
      }

      default {
        Write-LogMessage warning 'Please answer yes (y) or no (n)'
      }
    }
  }
}

# ============ Project Generators ===============

function Get-ProjectSourceFiles {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ProjectContext]$Context
  )

  $files = @{}

  $sources = @(
    Get-CommonSourceFiles -Context $Context

    switch ($Context.Template.Language) {
      ([ProjectLanguage]::JavaScript) {
        Get-JavaScriptSourceFiles -Context $Context
      }

      ([ProjectLanguage]::TypeScript) {
        Get-TypeScriptSourceFiles -Context $Context
      }

      default {
        throw "Unsupported project language: $($Context.Template.Language)"
      }
    }

    switch ($Context.Template.Engine) {
      ([ProjectEngine]::Vanilla) {
        Get-VanillaSourceFiles -Context $Context
      }

      ([ProjectEngine]::Phaser) {
        Get-PhaserSourceFiles -Context $Context
      }

      default {
        throw "Unsupported project engine: $($Context.Template.Engine)"
      }
    }
  )

  foreach ($source in $sources) {
    foreach ($path in @($source.Keys)) {
      if ($files.ContainsKey($path)) {
        throw "Duplicate project file: $path"
      }

      $files[$path] = $source[$path]
    }
  }

  return $files
}

function New-ProjectDirectory {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ProjectContext]$Context
  )

  if (Test-Path -LiteralPath $Context.ProjectPath) {
    throw "Project directory already exists: $($Context.ProjectPath)"
  }

  New-Item -Path $Context.ProjectPath -ItemType Directory -ErrorAction Stop | Out-Null

  Write-LogMessage success 'Project directory created'
}

function Write-ProjectFiles {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ProjectContext]$Context,

    [Parameter(Mandatory)]
    [System.Collections.IDictionary]$Files
  )

  $encoding = [System.Text.UTF8Encoding]::new($false)

  foreach ($relativePath in $Files.Keys) {
    $filePath = Join-Path $Context.ProjectPath $relativePath
    $directory = Split-Path -Path $filePath -Parent

    if (-not (Test-Path -LiteralPath $directory)) {
      New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText(
      $filePath,
      [string]$Files[$relativePath],
      $encoding
    )
  }

  Write-LogMessage success "$($Files.Count) project files generated"
}

function Invoke-ProjectGenerator {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ProjectContext]$Context
  )
  New-ProjectDirectory -Context $Context
  $files = Get-ProjectSourceFiles -Context $Context
  Write-ProjectFiles -Context $Context -Files $files
  Write-LogMessage success "Project '$($Context.Name)' created with template $($Context.Template)"
}

function Invoke-PackageManagerInstall {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ProjectContext]$Context
  )

  $command = Get-Command `
    -Name $Context.PackageManager `
    -CommandType Application `
    -ErrorAction SilentlyContinue

  if (-not $command) {
    throw "Package manager not found: $($Context.PackageManager)"
  }

  $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $command.Source
  $startInfo.WorkingDirectory = $Context.ProjectPath
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardOutput = $true
  $startInfo.CreateNoWindow = $false
  $null = $startInfo.ArgumentList.Add('install')

  $process = [System.Diagnostics.Process]::new()
  $process.StartInfo = $startInfo

  $stdoutTask = $null

  Write-LogMessage info "Installing dependencies with $($Context.PackageManager)..."

  try {
    if (-not $process.Start()) {
      throw 'Failed to start package manager process'
    }

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()

    while (-not $process.HasExited) {
      Assert-NotCancelled
      Start-Sleep -Milliseconds 100
    }

    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
      throw "Package manager exited with code $($process.ExitCode)"
    }

    Write-LogMessage success 'Dependencies installed successfully'
  }
  catch [System.OperationCanceledException] {
    if (-not $process.HasExited) {
      $process.Kill($true)
      $process.WaitForExit()
    }

    throw
  }
  finally {
    if ($stdoutTask) {
      $null = $stdoutTask.GetAwaiter().GetResult()
    }

    $process.Dispose()
  }
}

# ============ Source Generators ===============

function Get-CommonSourceFiles {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ProjectContext]$Context
  )

  $templateKey = $Context.Template.Engine.ToString().ToLower()

  if ($Context.Template.IsTypeScript()) {
    $templateKey += '-ts'
  }

  $readme = @'
# {{PROJECT_NAME}}

Template: `{{TEMPLATE}}`

## Scripts

```sh
npm run dev      # start dev server
npm run build    # build for production
npm run preview  # preview production build
```
'@

  $readme = $readme.Replace('{{PROJECT_NAME}}', $Context.Name)
  $readme = $readme.Replace('{{TEMPLATE}}', $templateKey)

  return @{
    '.editorconfig'                = @'
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
'@

    '.gitignore'                   = @'
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
'@

    'README.md'                    = $readme

    'public/favicon.svg'           = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect width="32" height="32" rx="6" fill="#863bff"/><text x="16" y="22" font-size="16" text-anchor="middle" fill="#fff" font-family="sans-serif">W</text></svg>
'@

    'public/assets/audio/.gitkeep' = ''
    'public/assets/font/.gitkeep'  = ''
    'src/modules/.gitkeep'         = ''
    'src/assets/.gitkeep'          = ''
  }
}

function Get-JavaScriptSourceFiles {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ProjectContext]$Context
  )

  $files = @{}

  switch ($Context.Template.Engine) {
    ([ProjectEngine]::Vanilla) {
      $files['index.html'] = @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>{{PROJECT_NAME}}</title>
    <meta name="viewport" content="width=device-width" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <script type="module" src="/src/main.js"></script>
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
'@

      $files['jsconfig.json'] = @'
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
'@

      $files['package.json'] = @'
{
  "name": "{{PROJECT_NAME}}",
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
'@

      $files['vite.config.js'] = @'
import { defineConfig } from 'vite'
import path from 'node:path'

export default defineConfig({
  resolve: {
    alias: {
      // Mirrors the "~/*" mapping in jsconfig.json
      '~': path.resolve(process.cwd(), 'src')
    }
  }
})
'@

      $files['src/config.js'] = @'
export const appName = 'vanilla'
'@

      $files['src/counter.js'] = @'
export function setupCounter(element) {
  let counter = 0
  const setCounter = (count) => {
    counter = count
    element.innerHTML = `Count is ${counter}`
  }
  element.addEventListener('click', () => setCounter(counter + 1))
  setCounter(0)
}
'@

      $files['src/main.js'] = @'
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
'@

      $files['src/style.css'] = @'
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
'@
    }

    ([ProjectEngine]::Phaser) {
      $files['index.html'] = @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>{{PROJECT_NAME}}</title>
    <meta name="viewport" content="width=device-width" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <link rel="stylesheet" href="/style.css">
    <script type="module" src="/src/main.js"></script>
  </head>
  <body>
    <div id="app">
      <div id="game-container"></div>
    </div>
  </body>
</html>
'@

      $files['jsconfig.json'] = @'
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
'@

      $files['package.json'] = @'
{
  "name": "{{PROJECT_NAME}}",
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
'@

      $files['vite.config.js'] = @'
import { defineConfig } from 'vite';
import path from 'node:path';

export default defineConfig({
  resolve: {
    alias: {
      // Mirrors the "~/*" mapping in jsconfig.json
      '~': path.resolve(process.cwd(), 'src'),
    },
  },
});
'@

      $files['public/style.css'] = @'
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
'@

      $files['src/main.js'] = @'
import { Game } from 'phaser';
import { config } from './config.js'

new Game(config);
'@

      $files['src/config.js'] = @'
import { Preloader } from './scenes/Preloader.js';
import { AUTO, Scale } from 'phaser'

/**
 * @type {import('phaser').Types.Core.GameConfig}
 */
export const config = {
  title: 'Card Memory Game',
  type: AUTO,
  width: 549,
  height: 480,
  parent: 'game-container',
  backgroundColor: '#192a56',
  pixelArt: true,
  scale: {
    mode: Scale.FIT,
    autoCenter: Scale.CENTER_BOTH
  },
  scene: [
    Preloader
  ],
};
'@

      $files['src/scenes/Preloader.js'] = @'
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
'@
    }

    default {
      throw "Unsupported project engine: $($Context.Template.Engine)"
    }
  }

  foreach ($path in @($files.Keys)) {
    $files[$path] = $files[$path].Replace(
      '{{PROJECT_NAME}}',
      $Context.Name
    )
  }

  return $files
}

function Get-TypeScriptSourceFiles {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ProjectContext]$Context
  )

  $files = @{}

  switch ($Context.Template.Engine) {
    ([ProjectEngine]::Vanilla) {
      $files['index.html'] = @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>{{PROJECT_NAME}}</title>
    <meta name="viewport" content="width=device-width" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <script type="module" src="/src/main.ts"></script>
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
'@

      $files['tsconfig.json'] = @'
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
'@

      $files['package.json'] = @'
{
  "name": "{{PROJECT_NAME}}",
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
'@

      $files['vite.config.ts'] = @'
import { defineConfig } from 'vite'
import path from 'node:path'

export default defineConfig({
  resolve: {
    alias: {
      // Mirrors the "~/*" mapping in tsconfig.json
      '~': path.resolve(process.cwd(), 'src')
    }
  }
})
'@

      $files['src/counter.ts'] = @'
export function setupCounter(element: HTMLButtonElement) {
  let counter = 0
  const setCounter = (count: number) => {
    counter = count
    element.innerHTML = `Count is ${counter}`
  }
  element.addEventListener('click', () => setCounter(counter + 1))
  setCounter(0)
}
'@

      $files['src/main.ts'] = @'
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
'@

      $files['src/style.css'] = @'
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
'@
    }

    ([ProjectEngine]::Phaser) {
      $files['index.html'] = @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>{{PROJECT_NAME}}</title>
    <meta name="viewport" content="width=device-width" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <link rel="stylesheet" href="/style.css">
    <script type="module" src="/src/main.ts"></script>
  </head>
  <body>
    <div id="app">
      <div id="game-container"></div>
    </div>
  </body>
</html>
'@

      $files['tsconfig.json'] = @'
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
'@

      $files['package.json'] = @'
{
  "name": "{{PROJECT_NAME}}",
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
'@

      $files['vite.config.ts'] = @'
import { defineConfig } from 'vite';
import path from 'node:path';

export default defineConfig({
  resolve: {
    alias: {
      // Mirrors the "~/*" mapping in tsconfig.json
      '~': path.resolve(process.cwd(), 'src'),
    },
  },
});
'@

      $files['public/style.css'] = @'
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
'@

      $files['src/main.ts'] = @'
import { Game } from 'phaser';
import { config } from './config.js'

new Game(config);
'@

      $files['src/config.ts'] = @'
import { Preloader } from './scenes/Preloader.js';
import { Types, AUTO, Scale } from 'phaser';

export const config = {
  title: 'Card Memory Game',
  type: AUTO,
  width: 549,
  height: 480,
  parent: 'game-container',
  backgroundColor: '#192a56',
  pixelArt: true,
  scale: {
    mode: Scale.FIT,
    autoCenter: Scale.CENTER_BOTH
  },
  scene: [
    Preloader
  ],

} satisfies Types.Core.GameConfig;
'@

      $files['src/scenes/Preloader.ts'] = @'
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
'@
    }

    default {
      throw "Unsupported project engine: $($Context.Template.Engine)"
    }
  }

  foreach ($path in @($files.Keys)) {
    $files[$path] = $files[$path].Replace(
      '{{PROJECT_NAME}}',
      $Context.Name
    )
  }

  return $files
}

function Get-VanillaSourceFiles {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ProjectContext]$Context
  )

  $files = @{}

  if ($Context.Template.IsTypeScript()) {
    $files['src/types/.gitkeep'] = ''
  }

  return $files
}

function Get-PhaserSourceFiles {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ProjectContext]$Context
  )

  $files = @{
    'public/assets/ui/.gitkeep' = ''
  }

  if ($Context.Template.IsTypeScript()) {
    $files['src/types/.gitkeep'] = ''
  }

  return $files
}

# ============ Main Function ===============
function Invoke-Main {
  [CmdletBinding()]
  param (
    [switch]$InteractiveMode
  )
  [MkwebCancellation]::Register()

  try {
    if ($Help) {
      Show-Help
      return
    }

    $projectName = Resolve-ProjectName $Name
    Assert-NotCancelled
    $templateKey = Resolve-ProjectTemplate $Template
    Assert-NotCancelled
    $packageManager = Resolve-PackageManager $Pm
    Assert-NotCancelled
    $install = Resolve-Install -Value:$Install -Interactive:$InteractiveMode
    Assert-NotCancelled

    $projectTemplate = $script:Templates[$templateKey]
    $context = [ProjectContext]::new(
      $projectName,
      $packageManager,
      $projectTemplate
    )

    Write-LogMessage info "$($templateKey.Split('-') -join ' ') template selected"
    Write-LogMessage info "Project folder: $($context.ProjectPath.Split([char[]]@('/'))[-1])"
    Write-LogMessage info "Package manager: $($context.PackageManager)"

    Invoke-ProjectGenerator -Context $context

    if ($install) {
      Assert-NotCancelled
      Invoke-PackageManagerInstall -Context $context
      Write-LastMessage -Context $context -Install:$install
    }
    else {
      Write-LastMessage -Context $context
    }


  }
  catch [System.OperationCanceledException] {
    Write-LogMessage warning 'Operation cancelled by user'
    return
  }
  finally {
    [MkwebCancellation]::Unregister()
  }
}

# ============ Execution ===============

$interactiveMode = -not ($Name -and $Template -and $Pm)

Invoke-Main -InteractiveMode:$interactiveMode
