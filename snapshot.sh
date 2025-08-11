#!/usr/bin/env bash
set -euo pipefail

OUT="firebyte_dashboard_snapshot.txt"
echo "=== Firebyte Studio Dashboard Snapshot ($(date)) ===" > "$OUT"

# Základné info o prostredí
{
  echo -e "\n--- 🧰 Environment ---"
  node -v 2>/dev/null || echo "node: n/a"
  npm -v 2>/dev/null || echo "npm: n/a"
  grep -E '"name"|"version"' package.json | sed 's/^[[:space:]]*//'
} >> "$OUT"

# Scripts z package.json
{
  echo -e "\n--- 📦 package.json scripts ---"
  jq -r '.scripts' package.json 2>/dev/null || grep -A100 '"scripts":' package.json
} >> "$OUT"

# Štruktúra src/ (do hĺbky 3)
{
  echo -e "\n--- 📂 src/ structure (depth<=3) ---"
  find src -maxdepth 3 -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) | sort
} >> "$OUT"

# App routes (Next.js App Router)
{
  echo -e "\n--- 🗺️ src/app routes ---"
  if [ -d src/app ]; then
    find src/app -type f \( -name "page.tsx" -o -name "route.ts" \) | sort
  else
    echo "src/app not found"
  fi
} >> "$OUT"

# Kľúčové komponenty (layout, header, sidebar)
dump_head () { f="$1"; n="${2:-40}"; [ -f "$f" ] && { echo -e "\n--- ✨ $f (first $n lines) ---"; head -n "$n" "$f"; }; }
{
  dump_head "src/app/layout.tsx" 60
  dump_head "src/app/page.tsx" 60
  # Header / Sidebar – rôzne možné názvy
  for f in \
    src/components/header.tsx src/components/Header.tsx \
    src/components/sidebar-nav.tsx src/components/Sidebar.tsx \
    src/components/navigation/Sidebar.tsx
  do
    dump_head "$f" 60
  done
} >> "$OUT"

# Wizard komponenty
{
  echo -e "\n--- 🧩 Wizard components ---"
  if [ -d src/components/wizard ]; then
    find src/components/wizard -maxdepth 2 -type f \( -name "*.tsx" -o -name "*.ts" \) | sort
    for f in src/components/wizard/WizardContext.tsx \
             src/components/wizard/NewAIProjectWizard.tsx \
             src/components/wizard/Step1Template.tsx \
             src/components/wizard/Step2Modules.tsx \
             src/components/wizard/Step3Deploy.tsx
    do
      dump_head "$f" 40
    done
  else
    echo "No wizard folder found."
  fi
} >> "$OUT"

# Logo komponent (FirebyteLogo)
{
  echo -e "\n--- 🔥 Logo component (FirebyteLogo) ---"
  grep -iRl "FirebyteLogo" src 2>/dev/null | sort || true
  dump_head "src/components/logo/FirebyteLogo.tsx" 60
} >> "$OUT"

# AMOLED Parallax efekt
{
  echo -e "\n--- 🌌 AMOLED Parallax ---"
  if [ -d src/components/effects ]; then
    find src/components/effects -maxdepth 2 -type f | sort
    dump_head "src/components/effects/AmoledParallax.tsx" 60
  else
    echo "No effects folder found."
  fi
} >> "$OUT"

# i18n zdroje pre Story/Roadmap / Teaser
{
  echo -e "\n--- 🌍 i18n files ---"
  find src -type f -path "*/lib/i18n/*" -o -path "*/i18n/*" 2>/dev/null | sort || true
  dump_head "src/lib/i18n/storyRoadmap.ts" 80
} >> "$OUT"

# API routes dôležité pre AI / jobs / ecommerce
{
  echo -e "\n--- 🛠️ API routes (AI / jobs / ecommerce) ---"
  find src/app/api -type f \( -name "route.ts" -o -name "*.ts" \) 2>/dev/null | sort || echo "No src/app/api folder."
} >> "$OUT"

# ESLint/TS config rýchly náhľad
{
  echo -e "\n--- 🧪 Lint/TS configs ---"
  [ -f eslint.config.mjs ] && echo "eslint.config.mjs present"
  [ -f tsconfig.json ] && echo "tsconfig.json present"
} >> "$OUT"

# Port 8000 kontrola
{
  echo -e "\n--- 🌐 Port check (8000) ---"
  (ss -ltn 2>/dev/null | grep ":8000" ) || (netstat -ltn 2>/dev/null | grep ":8000" ) || echo "Port 8000 seems free (or tools not available)."
} >> "$OUT"

echo -e "\n✅ Snapshot saved to: $OUT"
