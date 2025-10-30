# 🚀 Spark Template

## 📘 Présentation

**Spark Template** est un dépôt modèle permettant de **créer rapidement une application Spark Scala entièrement prête à l’emploi**, avec :
- une arborescence projet standardisée (`src/main/scala/com/<organisation>/<application>`);
- un fichier `build.sbt` préconfiguré ;
- un environnement Docker fonctionnel (basé sur Spark 3.5) ;
- une configuration de pipeline GitHub Actions pour le build et la publication d’image Docker sur **GHCR.io**.

L’objectif est de permettre à tout développeur de **générer en quelques secondes un nouveau projet Scala Spark**, correctement structuré et immédiatement exécutable dans un cluster Docker.

---

## 🧱 Structure du dépôt

```
spark-template/
├── .github
│   └── workflows
│       ├── docker.yml            # Workflow GitHub Actions pour GHCR
│       └── scala.yml             # Workflow GitHub Actions pour scala
├── .gitignore
├── Dockerfile.custom             # Image Docker de base personnalisable
├── README.md
├── build.sbt                     # Dépendances et configuration SBT
├── docker-compose.yml            # Cluster Spark (master, worker, submit)
├── init-template.sh              # Script d’initialisation du projet
├── run-app.sh                    # Script de build et de soumission Spark
├── spark-start.sh
├── spark-stop.sh
├── spark-submit.sh
└── src
    ├── main
    │   ├── resources
    │   │   ├── log4j2-master.properties
    │   │   ├── log4j2-submit.properties
    │   │   └── log4j2-worker.properties
    │   └── scala
    │       └── Main.scala
    └── test
        └── scala
            ├── MainSpec.scala
            └── utils
                └── SparkTestSession.scala
````

---

## ⚙️ Initialisation d’un nouveau projet

Le script **`init-template.sh`** permet d’instancier un nouveau projet Spark Scala à partir de ce template.

### 🧩 Étapes

Exécute dans ton terminal :

```bash
./init-template.sh
````

Le script te posera une série de questions interactives :

| Paramètre                    | Exemple                      | Description                                                      |
| ---------------------------- | ---------------------------- | ---------------------------------------------------------------- |
| **Nom de l’application**     | `project`               | Nom du projet Scala et du JAR                                    |
| **Nom de l’organisation**    | `emiasd`                     | Utilisé pour le package Scala `com.<organisation>.<application>` |
| **Nom du docker**            | `project`               | Nom du conteneur Docker et du package GHCR                       |
| **Nom d’utilisateur GitHub** | `auduvignac`                 | Utilisé pour créer les liens GHCR (`ghcr.io/<user>/<image>`)     |
| **Image Docker de base**     | *(laisser vide pour défaut)* | Permet de changer la base (`ghcr.io/auduvignac/spark:latest`)           |
| **Token GHCR (optionnel)**   | *(masqué)*                   | Nécessaire uniquement si publication sur GHCR.io                 |

---

## 🏗️ Étapes réalisées automatiquement

Le script :

1. 🧱 Met à jour le fichier `build.sbt` (nom, package, main class).
2. 🚚 Déplace `Main.scala` vers :

   ```
   src/main/scala/com/<organisation>/<application>/Main.scala
   ```
3. 🐳 Met à jour :

   * `Dockerfile.custom`
   * `docker-compose.yml`
   * `.github/workflows/docker.yml`
4. 🏗️ Construit l’image Docker localement avec logs détaillés.
5. 🔑 Si un token GHCR est fourni :

   * connexion à `ghcr.io`
   * push automatique de l’image vers GitHub Container Registry
6. 🔒 À la fin, indique à l’utilisateur que l’image est **privée** par défaut.

---

## 🪵 Exemple d’exécution

```
🚀 Initialisation d'un nouveau projet Spark Scala
=================================================
👉 Nom de l'application (ex: project): project
👉 Nom de l'organisation (ex: emiasd): emiasd
👉 Nom du docker (par défaut: project): project
👉 Nom d'utilisateur GitHub (ex: auduvignac): auduvignac
👉 Image docker de base (par défaut ghcr.io/auduvignac/spark:latest): 

🏗️  Construction locale de l'image Docker : ghcr.io/auduvignac/project:latest
🪵 Affichage en direct des logs du build Docker...
-----------------------------------------------------------
#1 [internal] load Dockerfile.custom
#2 [2/5] RUN apt-get update && apt-get install ...
#3 exporting to image
#4 naming to ghcr.io/auduvignac/project:latest
-----------------------------------------------------------
✅ Image Docker construite localement avec succès.

🔑 Token détecté : connexion à GHCR.io...
Login Succeeded
⬆️  Push de l'image vers GHCR.io...
✅ Image poussée sur GHCR.io avec succès.

-----------------------------------------------------------
🔒 L'image Docker a bien été poussée sur GHCR.io :
    🐳 ghcr.io/auduvignac/project:latest

⚠️  Pour l'instant, cette image est en mode *privé*.
   Pour la rendre *publique*, se rendre sur :
   👉 https://github.com/users/auduvignac/packages/container/project

   Puis clique sur ⚙️  « Package settings » > Visibility > Public
-----------------------------------------------------------
```

---

## 🔧 Utilisation de l’image générée

Une fois ton projet créé et ton image Docker disponible, le lancement du cluster Spark en local s'opère ainsi :

```bash
./run-app.sh
```

Ce script :

* compile ton projet (`sbt assembly`),
* démarre le cluster Spark via `docker-compose`,
* copie ton JAR dans le conteneur `spark-submit`,
* et soumet automatiquement ton job à Spark.

---

## 🔐 Gestion des tokens GHCR

Le **token GHCR** est un **Personal Access Token (PAT)** GitHub, utilisé pour pousser les images sur GitHub Container Registry.

### 🔧 Scopes nécessaires :

```
write:packages
read:packages
delete:packages
```

Crée ton token ici :
👉 [https://github.com/settings/tokens](https://github.com/settings/tokens)

---

## 📦 Lien vers ton image sur GHCR

Une fois poussée, ton image sera disponible à l’adresse :

```
ghcr.io/<github_user>/<docker_name>:latest
```

Et accessible (si publique) sur :

```
https://github.com/users/<github_user>/packages/container/<docker_name>
```

Exemple :

```
ghcr.io/auduvignac/project:latest
https://github.com/users/auduvignac/packages/container/project
```

---

## 🧹 Nettoyage

Pour supprimer une image devenue obsolète :

```bash
docker rmi ghcr.io/<github_user>/<docker_name>:latest
```

Ou depuis GitHub :
👉 [https://github.com/<github_user>?tab=packages](https://github.com/<github_user>?tab=packages)

---

## 🤝 Contribution

Ce dépôt peut être cloné afin d’être adapté à différents cas d’usage :

```bash
git clone https://github.com/<ton_user>/spark-template.git
```

Les contributions sont les bienvenues :

* nouvelles configurations Spark,
* modèles de jobs Scala,
* intégrations CI/CD supplémentaires.

---

## 🧩 Licence

Ce projet est distribué sous licence **MIT** — libre d’utilisation et de modification.

---

### 💡 En résumé

| Commande             | Description                                         |
| -------------------- | --------------------------------------------------- |
| `./init-template.sh` | Initialise un nouveau projet Scala Spark            |
| `./run-app.sh`       | Compile et exécute le projet dans un cluster Docker |
| `docker-compose up`  | Lance manuellement le cluster Spark                 |
| `docker push`        | Publication manuelle sur GHCR.io                    |

---