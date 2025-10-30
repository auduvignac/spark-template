#!/usr/bin/env bash
set -e

echo "🚀 Initialisation d'un nouveau projet Spark Scala"
echo "================================================="

# ==============================
# 🧭 Saisie des paramètres
# ==============================
read -rp "👉 Nom de l'application (ex: project): " APP_NAME
read -rp "👉 Nom de l'organisation (ex: emiasd): " ORG_NAME
read -rp "👉 Nom du docker (par défaut: $APP_NAME): " DOCKER_NAME
read -rp "👉 Image docker de base (par défaut ghcr.io/auduvignac/spark:latest): " DOCKER_BASE
read -rp "👉 Nom d'utilisateur GitHub (ex: auduvignac): " GITHUB_USER
read -rp "👉 Adresse mail de l'utilisateur (ex: $GITHUB_USER@users.noreply.github.com): " GITHUB_EMAIL
read -rsp "🔑 Token GitHub (Personal Access Token avec write:packages) [laisser vide pour build local] : " GHCR_TOKEN

# ==============================
# 🧩 Validation des entrées
# ==============================
if [[ -z "$APP_NAME" ]]; then
  echo "❌ Nom d'application invalide."
  exit 1
fi
if [[ -z "$ORG_NAME" ]]; then
  echo "❌ Nom d'organisation invalide."
  exit 1
fi
if [[ -z "$GITHUB_USER" ]]; then
  echo "❌ Nom d'utilisateur GitHub invalide."
  exit 1
fi

# Valeurs par défaut
if [[ -z "$DOCKER_NAME" ]]; then
  DOCKER_NAME="$APP_NAME"
fi
if [[ -z "$DOCKER_BASE" ]]; then
  DOCKER_BASE="ghcr.io/auduvignac/spark:latest"
fi
if [[ -z "$GITHUB_EMAIL" ]]; then
  GITHUB_EMAIL="${GITHUB_USER}@users.noreply.github.com"
fi

# ==============================
# 🔧 Construction des variables
# ==============================
PKG_PROJECT=$(echo "$APP_NAME" | tr '-' '_' | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
PKG_ORG=$(echo "$ORG_NAME" | tr '-' '_' | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
PACKAGE_PATH="com/$PKG_ORG/$PKG_PROJECT"
FULL_PACKAGE="com.$PKG_ORG.$PKG_PROJECT"

IMAGE_NAME="ghcr.io/${GITHUB_USER}/${DOCKER_NAME}:latest"

echo ""
echo "📦 Package Scala : $FULL_PACKAGE"
echo "🐳 Image Docker   : $IMAGE_NAME"
echo "🧱 Image de base  : $DOCKER_BASE"
echo "📂 Arborescence   : src/main/scala/$PACKAGE_PATH"

# ==============================
# 🧱 Mise à jour du build.sbt
# ==============================
if [[ -f build.sbt ]]; then
  echo "🧱 Mise à jour du build.sbt..."
  sed -i.bak "s/^name := .*/name := \"$APP_NAME\"/" build.sbt
  sed -i.bak "s/Compile \/ mainClass :=.*/Compile \/ mainClass := Some(\"$FULL_PACKAGE.Main\")/" build.sbt
  sed -i.bak "s/assembly \/ mainClass :=.*/assembly \/ mainClass := Some(\"$FULL_PACKAGE.Main\")/" build.sbt
  rm -f build.sbt.bak
fi

# ==============================
# 🚚 Déplacement du Main.scala
# ==============================
MAIN_SRC="src/main/scala/Main.scala"
TARGET_DIR="src/main/scala/$PACKAGE_PATH"
TARGET_MAIN="$TARGET_DIR/Main.scala"

if [[ -f "$MAIN_SRC" ]]; then
  echo "📂 Création du dossier : $TARGET_DIR"
  mkdir -p "$TARGET_DIR"

  echo "🚚 Déplacement de Main.scala..."
  mv "$MAIN_SRC" "$TARGET_MAIN"

  if grep -q "^package " "$TARGET_MAIN"; then
    sed -i "s/^package .*/package $FULL_PACKAGE/" "$TARGET_MAIN"
  else
    sed -i "1ipackage $FULL_PACKAGE\n" "$TARGET_MAIN"
  fi
else
  echo "⚠️ Aucun fichier Main.scala trouvé à $MAIN_SRC"
fi

# ==============================
# 🐳 Mise à jour docker-compose.yml
# ==============================
COMPOSE_FILE="docker-compose.yml"
if [[ -f "$COMPOSE_FILE" ]]; then
  echo "🐳 Mise à jour de $COMPOSE_FILE..."
  sed -i.bak "s|ghcr.io/.*/spark:latest|${IMAGE_NAME}|g" "$COMPOSE_FILE"
  rm -f "$COMPOSE_FILE.bak"
fi

# ==============================
# ⚙️  Mise à jour du workflow GitHub Actions
# ==============================
WORKFLOW_FILE=".github/workflows/docker.yml"
if [[ -f "$WORKFLOW_FILE" ]]; then
  echo "⚙️  Mise à jour du workflow GitHub Actions..."
  sed -i.bak "s|ghcr.io/.*/spark:latest|${IMAGE_NAME}|g" "$WORKFLOW_FILE"
  sed -i.bak "s|-u .* --password-stdin|-u ${GITHUB_USER} --password-stdin|" "$WORKFLOW_FILE"
  rm -f "$WORKFLOW_FILE.bak"
fi

# ==============================
# 🧩 Mise à jour du Dockerfile.custom
# ==============================
DOCKERFILE="Dockerfile.custom"
if [[ -f "$DOCKERFILE" ]]; then
  echo "🧩 Mise à jour de $DOCKERFILE..."
  sed -i.bak "s|LABEL maintainer=.*|LABEL maintainer=\"${GITHUB_USER} <${GITHUB_EMAIL}>\"|" "$DOCKERFILE"
  sed -i.bak "s|LABEL description=.*|LABEL description=\"Image personnalisée pour le projet ${APP_NAME}\"|" "$DOCKERFILE"
  sed -i.bak "s|^FROM .*|FROM ${DOCKER_BASE}|" "$DOCKERFILE"
  rm -f "$DOCKERFILE.bak"
fi

# ==============================
# 🏗️  Build de l'image Docker locale
# ==============================
echo ""
echo "🏗️  Construction locale de l'image Docker : $IMAGE_NAME"
echo "🪵 Affichage en direct des logs du build Docker..."
echo "-----------------------------------------------------------"
docker build --progress=plain -f Dockerfile.custom -t "$IMAGE_NAME" .
echo "-----------------------------------------------------------"
echo "✅ Image Docker construite localement avec succès."

# ==============================
# 🔐 Connexion & push (si token fourni)
# ==============================
if [[ -n "$GHCR_TOKEN" ]]; then
  echo ""
  echo "🔑 Token détecté : connexion à GHCR.io..."
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin

  echo "🔎 Vérification de l'existence de l'image sur GHCR.io..."
  if docker manifest inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "⚠️  L'image $IMAGE_NAME existe déjà sur GHCR."
    read -rp "Souhaitez-vous la remplacer ? (y/N): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
      echo "❌ Annulé par l'utilisateur. Aucune modification."
      exit 0
    else
      echo "♻️  L'image existante sera remplacée."
    fi
  else
    echo "✅ Aucune image existante trouvée. Création d'une nouvelle."
  fi

  echo "⬆️  Push de l'image vers GHCR.io..."
  docker push "$IMAGE_NAME"
  echo "✅ L'image Docker a été poussée avec succès sur GHCR.io :"
  echo "    🐳 $IMAGE_NAME"
  echo ""
  echo "⚠️  Pour l'instant, cette image est en mode *privé*."
  echo "   Pour la rendre *publique*, se rendre sur :"
  echo "   👉 https://github.com/users/${GITHUB_USER}/packages/container/${DOCKER_NAME}"
  echo ""
  echo "   Puis cliquer sur ⚙️  « Package settings » > Visibility > Public"
  echo "-----------------------------------------------------------"

else
  echo ""
  echo "⚠️ Aucun token GHCR fourni. L'image reste locale."
  echo "➡️ Vous pouvez la pousser plus tard avec :"
  echo "   docker login ghcr.io -u $GITHUB_USER"
  echo "   docker push $IMAGE_NAME"
fi

# ==============================
# ✅ Résumé final
# ==============================
echo ""
echo "✅ Projet initialisé avec succès !"
echo "-----------------------------------------------------------"
echo "📦 Application : $APP_NAME"
echo "🏢 Organisation : $ORG_NAME"
echo "👤 GitHub user  : $GITHUB_USER"
echo "🐳 Docker       : $DOCKER_NAME"
echo "🧱 Image        : $IMAGE_NAME"
echo "🧩 Base image   : $DOCKER_BASE"
echo "-----------------------------------------------------------"

if [[ -n "$GHCR_TOKEN" ]]; then
  echo "📤 Image poussée sur : https://ghcr.io/${GITHUB_USER}/${DOCKER_NAME}"
else
  echo "💾 Image disponible localement : ${IMAGE_NAME}"
fi

echo ""
echo "Prochaine étape :"
echo "  docker run -it ${IMAGE_NAME} bash"