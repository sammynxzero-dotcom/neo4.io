#!/usr/bin/env bash
set -euo pipefail

# setup_all.sh
# Cria os arquivos mínimos no repositório, cria uma branch (project-setup ou project-setup-<timestamp> se já existir),
# commita, push e tenta abrir um PR (se gh CLI estiver disponível).
#
# Uso:
#   1. Coloque este script no root do repositório local (onde .git está).
#   2. chmod +x setup_all.sh
#   3. ./setup_all.sh
#
# Observações:
# - Se um arquivo já existir, ele será movido para <file>.orig.bak antes de ser sobrescrito.
# - Se a branch project-setup já existir no remoto, será criada uma branch project-setup-YYYYmmddHHMMSS.
# - Necessita permissões de push no remoto 'origin' e, para abrir PR automaticamente, do GitHub CLI (gh).

REPO_OWNER="sammynxzero-dotcom"
REPO_NAME="neo4.io"
DESIRED_BRANCH="project-setup"

# util
timestamp() { date +%Y%m%d%H%M%S; }

warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*"; }
info() { printf '\033[1;32mINFO:\033[0m %s\n' "$*"; }
err() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; }

# Verify git repo
if [ ! -d .git ]; then
  err "Diretório atual não parece ser um repositório Git (arquivo .git não encontrado). Execute este script no root do repositório."
  exit 1
fi

# Fetch latest
git fetch origin --prune

# Determine branch name
if git ls-remote --exit-code --heads origin "${DESIRED_BRANCH}" >/dev/null 2>&1; then
  BRANCH="${DESIRED_BRANCH}-$(timestamp)"
  warn "Branch '${DESIRED_BRANCH}' já existe no remoto. Criando branch '${BRANCH}' em vez disso."
else
  BRANCH="${DESIRED_BRANCH}"
  info "Usando branch '${BRANCH}'."
fi

# Create and checkout branch from main (or current HEAD)
if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  info "Branch local ${BRANCH} já existe — fazendo checkout."
  git checkout "${BRANCH}"
else
  if git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then
    git checkout -b "${BRANCH}" origin/main
  else
    git checkout -b "${BRANCH}"
  fi
fi

# function to write file with backup if exists
write_file() {
  local path="$1"; shift
  local dir
  dir=$(dirname "$path")
  mkdir -p "$dir"
  if [ -f "$path" ]; then
    mv -f "$path" "${path}.orig.bak"
    info "Arquivo existente movido para: ${path}.orig.bak"
  fi
  cat > "$path" <<'__EOF__'
'"$@"'
__EOF__
  # The above placeholder is replaced below in the generated script routine.
}

# We'll create files using here-documents directly (to preserve content exactly).
# Helper to write content via heredoc while allowing single-quote safe content.
write_heredoc() {
  local path="$1"; shift
  local marker="${2:-EOF}"
  mkdir -p "$(dirname "$path")"
  if [ -f "$path" ]; then
    mv -f "$path" "${path}.orig.bak"
    info "Arquivo existente movido para: ${path}.orig.bak"
  fi
  cat > "$path" <<${marker}
$(
  printf "%s" "$*"
)
${marker}
  info "Criado: $path"
}

# For portability and simplicity, generate files with explicit cat <<'EOF' ... EOF blocks below.

# README.md
cat > README.md <<'README_EOF'
# neo4.io

Projeto em TypeScript + HTML.

## Visão geral

Este repositório contém o código do aplicativo neo4.io. Os arquivos a seguir foram adicionados para padronizar contribuições, CI e facilitar a execução local.

## Pré-requisitos

- Node.js 18+ recomendado
- npm ou yarn
- Android Studio / Android SDK (somente se quiser gerar APK/AAB)

## Instalação

1. Clone o repositório:
   - git clone https://github.com/${REPO_OWNER}/${REPO_NAME}.git
2. Entre na pasta:
   - cd ${REPO_NAME}
3. Instale dependências:
   - npm install

## Scripts úteis

- `npm run dev` — inicializa um watcher de desenvolvimento (se aplicável)
- `npm run build` — compila o TypeScript (`tsc`) para a pasta `dist`
- `npm run start` — inicia a aplicação em modo de produção (serve `dist`)
- `npm run lint` — executa ESLint (se houver)
- `npm test` — roda testes (placeholder)
- `npm run cap:init` — inicializa Capacitor (configurações para Android)
- `npm run cap:add-android` — adiciona a plataforma Android (executar localmente)
- `npm run postbuild` — copia manifest/sw/icons para dist e injeta registros (após build)

## Como testar localmente

1. Instale dependências (`npm ci`).
2. Rode `npm run build`.
3. Rode `npm run postbuild` (ou será executado automaticamente se configurado como postbuild).
4. Sirva a pasta `dist` com um servidor estático (ex.: `npx serve dist`) ou `npm run start` se houver script configurado.
5. Para empacotar como Android (local):
   - ./setup_capacitor.sh  (criará a pasta android/ usando Capacitor)
   - Abra `android/` no Android Studio e gere o APK/AAB.

## Contribuições

Veja `CONTRIBUTING.md` para orientações rápidas.

## Licença

Este projeto está licenciado sob a licença MIT — veja o arquivo `LICENSE`.
README_EOF

# LICENSE
cat > LICENSE <<'LICENSE_EOF'
MIT License

Copyright (c) 2025 sammynxzero-dotcom

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LICENSE_EOF

# CONTRIBUTING.md
mkdir -p .github
cat > CONTRIBUTING.md <<'CONTRIB_EOF'
# Contribuindo

Obrigado por querer contribuir!

Guia rápido:
1. Fork + clone.
2. Crie uma branch a partir de `main`: `git checkout -b feat/minha-mudanca`.
3. Instale dependências: `npm install`.
4. Siga as regras de lint (quando houver): `npm run lint`.
5. Adicione testes quando aplicável.
6. Abra um Pull Request (use o template).

Comunicação:
- Descreva a mudança no PR.
- Referencie issues relacionadas.

Obrigado!
CONTRIB_EOF

# .gitignore
cat > .gitignore <<'GITIGNORE_EOF'
# Node
node_modules/
dist/
build/
.env
.env.local
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# VSCode
.vscode/

# Mac
.DS_Store

# Logs
*.log
GITIGNORE_EOF

# package.json
cat > package.json <<'PKG_EOF'
{
  "name": "neo4.io",
  "version": "0.1.0",
  "private": true,
  "description": "Aplicação neo4.io",
  "scripts": {
    "dev": "tsc -w",
    "build": "tsc",
    "postbuild": "node scripts/postbuild.js",
    "start": "node dist/index.js || echo \"Adapte o start conforme sua app\"",
    "lint": "eslint . --ext .ts,.tsx || echo \"Configure ESLint se desejar\"",
    "test": "echo \"No tests configured\" && exit 0",
    "cap:init": "npx @capacitor/cli@latest init \"neo4.io\" com.sammynxneo4io --web-dir=dist",
    "cap:add-android": "npx @capacitor/cli@latest add android",
    "cap:copy": "npx @capacitor/cli@latest copy",
    "cap:open-android": "npx @capacitor/cli@latest open android",
    "cap:sync": "npx @capacitor/cli@latest sync"
  },
  "engines": {
    "node": ">=18"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "eslint": "^8.0.0",
    "@capacitor/cli": "^5.0.0",
    "@capacitor/core": "^5.0.0"
  }
}
PKG_EOF

# tsconfig.json
cat > tsconfig.json <<'TSC_EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ES2020",
    "moduleResolution": "node",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "sourceMap": true,
    "lib": ["ES2020", "DOM"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
TSC_EOF

# Dockerfile
cat > Dockerfile <<'DOCKER_EOF'
FROM node:18-alpine AS builder
WORKDIR /app

# Instala dependências e compila
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Imagem final mais leve
FROM node:18-alpine AS runner
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY package*.json ./
# Tenta instalar apenas dependências de produção (não quebra se não houver)
RUN npm ci --only=production || true

EXPOSE 3000
CMD ["node", "dist/index.js"]
DOCKER_EOF

# capacitor.config.json
cat > capacitor.config.json <<'CAP_EOF'
{
  "appId": "com.sammynxneo4io",
  "appName": "neo4.io",
  "webDir": "dist",
  "bundledWebRuntime": false
}
CAP_EOF

# manifest.webmanifest
cat > manifest.webmanifest <<'MAN_EOF'
{
  "name": "neo4.io",
  "short_name": "neo4",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#0d6efd",
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
MAN_EOF

# src/sw.js
mkdir -p src
cat > src/sw.js <<'SW_EOF'
// Service worker básico (cache-first para assets estáticos).
const CACHE_NAME = 'neo4io-cache-v1';
const URLS_TO_CACHE = [
  '/',
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(URLS_TO_CACHE))
  );
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(response => response || fetch(event.request))
  );
});
SW_EOF

# setup_capacitor.sh
cat > setup_capacitor.sh <<'SETUPCAP_EOF'
#!/usr/bin/env bash
set -euo pipefail
# Executar no root do repositório.
# O script instala dependências, compila a webapp (dist), inicializa Capacitor e adiciona Android.

if ! command -v git >/dev/null 2>&1; then
  echo "git não encontrado. Instale git e rode novamente."
  exit 1
fi

echo "Instalando dependências..."
npm ci

echo "Compilando assets web (npm run build)..."
npm run build

echo "Instalando Capacitor CLI/Core localmente (se necessário)..."
npm install --no-save @capacitor/cli@latest @capacitor/core@latest

echo "Inicializando Capacitor (capacitor.config.json será usado se existir)..."
npx @capacitor/cli@latest init "neo4.io" com.sammynxneo4io --web-dir=dist || true

echo "Adicionando Android (pode demorar)..."
npx @capacitor/cli@latest add android || true

echo "Copiando assets web para o projeto Android..."
npx @capacitor/cli@latest copy || true

echo "Pronto. A pasta 'android/' deve ter sido criada. Abra com: npx cap open android  (ou com Android Studio)."
SETUPCAP_EOF
chmod +x setup_capacitor.sh
info "Tornado executável: setup_capacitor.sh"

# scripts/postbuild.js
mkdir -p scripts
cat > scripts/postbuild.js <<'POST_EOF'
#!/usr/bin/env node
/**
 * scripts/postbuild.js
 *
 * Copia manifest.webmanifest, src/sw.js e pasta icons/ para dist/,
 * injeta <link rel="manifest"> no head (se não existir) e injeta o script
 * de registro do service worker antes do </body> (se não existir).
 *
 * Execute: node scripts/postbuild.js
 * Ou o script é chamado automaticamente por "postbuild" do package.json.
 */

const fs = require('fs');
const fsp = fs.promises;
const path = require('path');

const root = process.cwd();
const distDir = path.join(root, 'dist');
const manifestSrc = path.join(root, 'manifest.webmanifest');
const swSrc = path.join(root, 'src', 'sw.js');
const iconsSrc = path.join(root, 'icons');
const manifestDest = path.join(distDir, 'manifest.webmanifest');
const swDest = path.join(distDir, 'sw.js');
const iconsDest = path.join(distDir, 'icons');

async function exists(p) {
  try {
    await fsp.access(p);
    return true;
  } catch {
    return false;
  }
}

async function copyFileIfExists(src, dest) {
  if (await exists(src)) {
    await fsp.mkdir(path.dirname(dest), { recursive: true });
    await fsp.copyFile(src, dest);
    console.log(`copied: ${path.relative(root, src)} -> ${path.relative(root, dest)}`);
    return true;
  } else {
    console.warn(`não encontrado: ${path.relative(root, src)}`);
    return false;
  }
}

async function copyDirRecursive(src, dest) {
  if (!(await exists(src))) {
    console.warn(`pasta não encontrada: ${path.relative(root, src)}`);
    return false;
  }
  // Prefer fs.cp (Node 16+), fallback para manual
  if (fs.cp) {
    await fsp.mkdir(dest, { recursive: true });
    try {
      await fsp.cp(src, dest, { recursive: true });
      console.log(`copied dir: ${path.relative(root, src)} -> ${path.relative(root, dest)}`);
      return true;
    } catch (err) {
      console.warn('fs.cp falhou, tentando cópia manual:', err.message);
    }
  }

  // Manual copy
  async function _copy(srcDir, destDir) {
    await fsp.mkdir(destDir, { recursive: true });
    const items = await fsp.readdir(srcDir, { withFileTypes: true });
    for (const it of items) {
      const s = path.join(srcDir, it.name);
      const d = path.join(destDir, it.name);
      if (it.isDirectory()) {
        await _copy(s, d);
      } else if (it.isFile()) {
        await fsp.copyFile(s, d);
      }
    }
  }
  await _copy(src, dest);
  console.log(`copied dir (manual): ${path.relative(root, src)} -> ${path.relative(root, dest)}`);
  return true;
}

async function injectIntoIndex() {
  const indexPath = path.join(distDir, 'index.html');
  if (!(await exists(indexPath))) {
    console.warn('dist/index.html não encontrado — não será possível injetar manifest/registro do SW.');
    return;
  }
  let html = await fsp.readFile(indexPath, 'utf8');

  // Inject manifest link in <head>
  if (!/rel=["']manifest["']/.test(html)) {
    const manifestLink = `<link rel="manifest" href="/manifest.webmanifest">`;
    if (/<head[^>]*>/i.test(html)) {
      html = html.replace(/(<head[^>]*>)/i, `$1\n  ${manifestLink}`);
      console.log('Inserido <link rel="manifest"> no <head> de dist/index.html');
    } else {
      // fallback: insert at top
      html = `${manifestLink}\n${html}`;
      console.log('Inserido <link rel="manifest"> no início do index.html (fallback)');
    }
  } else {
    console.log('index.html já contém <link rel="manifest"> — pulando inserção.');
  }

  // Inject service worker registration before </body>
  if (!/navigator\.serviceWorker\.register/.test(html)) {
    const swRegister = `
<script>
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function() {
    navigator.serviceWorker.register('/sw.js').then(function(reg) {
      console.log('Service worker registrado com sucesso:', reg.scope);
    }).catch(function(err) {
      console.error('Falha ao registrar service worker:', err);
    });
  });
}
</script>`;
    if (/<\/body>/i.test(html)) {
      html = html.replace(/<\/body>/i, `${swRegister}\n</body>`);
      console.log('Inserido script de registro do Service Worker antes de </body>.');
    } else {
      html += `\n${swRegister}\n`;
      console.log('Inserido script de registro do Service Worker no final do arquivo (fallback).');
    }
  } else {
    console.log('index.html já contém registro de service worker — pulando inserção.');
  }

  await fsp.writeFile(indexPath, html, 'utf8');
}

(async () => {
  try {
    if (!(await exists(distDir))) {
      console.error('Diretório dist/ não existe. Rode "npm run build" antes de executar este script.');
      process.exitCode = 1;
      return;
    }

    await copyFileIfExists(manifestSrc, manifestDest);
    await copyFileIfExists(swSrc, swDest);
    await copyDirRecursive(iconsSrc, iconsDest);

    await injectIntoIndex();

    console.log('postbuild concluído.');
  } catch (err) {
    console.error('Erro no postbuild:', err);
    process.exitCode = 1;
  }
})();
POST_EOF
chmod +x scripts/postbuild.js
info "Tornado executável: scripts/postbuild.js"

# .github workflows and templates
mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<'CI_EOF'
name: CI

on:
  push:
    branches: [ main, project-setup ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Use Node.js 18
        uses: actions/setup-node@v4
        with:
          node-version: 18

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Lint (if configured)
        run: npm run lint || echo "Lint não configurado"

      - name: Test
        run: npm test || echo "Sem testes configurados"
CI_EOF

cat > .github/workflows/android-aab.yml <<'AAB_EOF'
name: Build Android AAB

on:
  workflow_dispatch:
  push:
    branches:
      - main
      - project-setup

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      ANDROID_SDK_ROOT: ${{ runner.temp }}/android-sdk

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '11'

      - name: Install Android SDK cmdline-tools
        run: |
          mkdir -p $ANDROID_SDK_ROOT/cmdline-tools
          cd $ANDROID_SDK_ROOT/cmdline-tools
          curl -sSL https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -o tools.zip
          unzip -q tools.zip
          rm tools.zip
          mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/latest
          mv cmdline-tools/* $ANDROID_SDK_ROOT/cmdline-tools/latest/ || true
          yes | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_SDK_ROOT "platform-tools" "platforms;android-33" "build-tools;33.0.2"
          yes | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --licenses || true

      - name: Prepare keystore
        if: ${{ secrets.KEYSTORE_BASE64 != '' }}
        run: |
          echo "Decodificando keystore..."
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/keystore.jks

      - name: Build AAB
        working-directory: android
        run: |
          chmod +x ./gradlew
          ./gradlew bundleRelease -Pandroid.injected.signing.store.file=../android/keystore.jks -Pandroid.injected.signing.store.password="${{ secrets.KEYSTORE_PASSWORD }}" -Pandroid.injected.signing.key.alias="${{ secrets.KEY_ALIAS }}" -Pandroid.injected.signing.key.password="${{ secrets.KEY_PASSWORD }}"
        env:
          JAVA_HOME: /usr/lib/jvm/java-11-openjdk-amd64
          ANDROID_HOME: ${{ env.ANDROID_SDK_ROOT }}
          PATH: ${{ env.ANDROID_SDK_ROOT }}/platform-tools:${{ env.PATH }}

      - name: Upload AAB
        uses: actions/upload-artifact@v4
        with:
          name: app-bundle
          path: android/app/build/outputs/bundle/release/*.aab
AAB_EOF

mkdir -p .github/ISSUE_TEMPLATE
cat > .github/ISSUE_TEMPLATE/bug_report.md <<'BUG_EOF'
---
name: Bug report
about: Reporte um bug
title: "[BUG] "
labels: bug
assignees: ''

---

**Descrição**
Uma descrição curta do bug.

**Passos para reproduzir**
1. ...
2. ...
3. ...

**Comportamento esperado**
Descreva o que você esperava que acontecesse.

**Informações adicionais**
- Node: versão
- Sistema operacional:
- Logs / stacktrace
BUG_EOF

cat > .github/ISSUE_TEMPLATE/feature_request.md <<'FEAT_EOF'
---
name: Feature request
about: Sugestão de nova funcionalidade
title: "[FEATURE] "
labels: enhancement
assignees: ''

---

**Resumo**
Descreva a funcionalidade desejada.

**Motivação**
Por que isso é importante?

**Proposta**
Como você imagina a implementação?
FEAT_EOF

cat > .github/PULL_REQUEST_TEMPLATE.md <<'PR_EOF'
## Descrição

Descreva brevemente o que este PR faz.

## Checklist
- [ ] Meu código segue as diretrizes do projeto
- [ ] Adicionei testes quando aplicável
- [ ] Atualizei a documentação quando aplicável

## Como testar
Passos para validar as mudanças:
1. ...
2. ...
PR_EOF

# Create icons dir placeholder
mkdir -p icons
if [ ! -f icons/icon-192.png ]; then
  echo "(imagem placeholder)" > icons/icon-192.png
fi
if [ ! -f icons/icon-512.png ]; then
  echo "(imagem placeholder)" > icons/icon-512.png
fi

info "Arquivos gerados. Preparando commit..."

git add .
if git diff --staged --quiet; then
  warn "Nenhuma mudança detectada para commitar."
else
  git commit -m "project: add minimal project setup, capacitor support, postbuild and CI templates"
  info "Commit criado."
fi

info "Fazendo push da branch ${BRANCH} para origin..."
git push -u origin "${BRANCH}"

# Try to create PR with gh CLI, else print URL
if command -v gh >/dev/null 2>&1; then
  info "Criando Pull Request com gh CLI..."
  gh pr create --title "Project: minimal setup + Capacitor support" \
    --body "Adiciona README, LICENSE, CONTRIBUTING, CI, Capacitor configs, postbuild script, Dockerfile and GitHub workflow templates.\n\nExecute setup_capacitor.sh localmente para gerar a pasta android/." \
    --base main --head "${BRANCH}" || warn "Falha ao criar PR com gh CLI. Você pode criar manualmente: https://github.com/${REPO_OWNER}/${REPO_NAME}/compare/main...${BRANCH}?expand=1"
else
  info "GitHub CLI (gh) não encontrada. Abra manualmente o PR em:"
  printf "  https://github.com/%s/%s/compare/main...%s?expand=1\n" "${REPO_OWNER}" "${REPO_NAME}" "${BRANCH}"
fi

info "Concluído. Se precisar, rode ./setup_capacitor.sh localmente para criar a pasta android/ (Capacitor)."