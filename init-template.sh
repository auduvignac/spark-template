#!/usr/bin/env bash
set -e

echo "🚀 Initialisation d'un nouveau projet Spark Scala"

# ==============================
# 1️⃣  Demande du nom de l'application
# ==============================
read -rp "👉 Nom de l'application: " APP_NAME

if [[ -z "$APP_NAME" ]]; then
  echo "❌ Nom d'application invalide."
  exit 1
fi

# Nom du package (remplace - par _)
PKG_NAME=$(echo "$APP_NAME" | tr '-' '_' | tr ' ' '_')

echo "📦 Nom du package : $PKG_NAME"

# ==============================
# 2️⃣  Mise à jour du build.sbt
# ==============================
if [[ -f build.sbt ]]; then
  echo "🧱 Mise à jour du build.sbt..."
  sed -i.bak "s/^name := .*/name := \"$APP_NAME\"/" build.sbt
  rm -f build.sbt.bak
else
  echo "⚠️ build.sbt introuvable, rien à modifier."
fi

# ==============================
# 3️⃣  Déplacement du Main.scala
# ==============================
MAIN_SRC="src/main/scala/Main.scala"
TARGET_DIR="src/main/scala/$PKG_NAME"
TARGET_MAIN="$TARGET_DIR/Main.scala"

if [[ -f "$MAIN_SRC" ]]; then
  echo "📂 Création du dossier : $TARGET_DIR"
  mkdir -p "$TARGET_DIR"

  echo "🚚 Déplacement de Main.scala..."
  mv "$MAIN_SRC" "$TARGET_MAIN"

  # Ajout du package au début du fichier
  if ! grep -q "^package " "$TARGET_MAIN"; then
    echo "📦 Ajout du package dans Main.scala"
    sed -i "1ipackage $PKG_NAME\n" "$TARGET_MAIN"
  fi
else
  echo "⚠️ Aucun fichier Main.scala trouvé à $MAIN_SRC"
fi

# ==============================
# 4️⃣  (Optionnel) Mise à jour du fichier de test
# ==============================
TEST_SRC="src/test/scala/MainSpec.scala"
if [[ -f "$TEST_SRC" ]]; then
  sed -i.bak "s/import utils./import $PKG_NAME.utils./" "$TEST_SRC" 2>/dev/null || true
  rm -f "$TEST_SRC.bak"
fi

# ==============================
# 5️⃣  Affichage récapitulatif
# ==============================
echo ""
echo "✅ Projet initialisé avec succès !"
echo "---------------------------------------------"
echo "📦 Application : $APP_NAME"
echo "📂 Package     : $PKG_NAME"
echo "🧱 build.sbt   : mis à jour"
echo "📄 Main.scala  : déplacé vers $TARGET_MAIN"
echo "---------------------------------------------"
echo ""
echo "Prochaine étape :"
echo "  sbt clean package"