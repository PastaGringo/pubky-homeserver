# Pubky Homeserver Stack

Cette stack Docker contient les services essentiels pour faire fonctionner un environnement Pubky complet avec homeserver, nexus, pubky-app et caddy.

## 🏗️ Architecture

La stack comprend les services suivants :

- **homeserver** : Serveur principal Pubky Core (port 6287)
- **nexusd** : Service d'indexation et API REST Pubky Nexus
- **pubky-app** : Application frontend Next.js
- **caddy** : Reverse proxy et serveur web (ports 80/443)
- **httprelay** : Service de relais HTTP (port 15412)

## 📋 Prérequis

- Docker et Docker Compose installés
- Git pour cloner les dépendances
- Au moins 2GB de RAM disponible
- Ports 80, 443, 6287 et 15412 disponibles

## 🚀 Installation et Configuration

### 1. Cloner les dépendances

La stack nécessite les repositories suivants :

```bash
# Cloner pubky-nexus (pour nexusd)
git clone https://github.com/pubky/pubky-nexus.git

# Créer le fichier de configuration nexus
mkdir -p pubky-nexus
touch pubky-nexus/config.toml
```

### 2. Configuration des variables d'environnement

#### Configuration Pubky-App

Créez un fichier `.env` dans le répertoire `pubky-app` basé sur `.env.example` :

```bash
cd pubky-app
cp .env.example .env
```

**Variables principales :**

```env
# Configuration Testnet (développement local)
NEXT_PUBLIC_HOMESERVER=8pinxxgqs41n4aididenw5apqp1urfmzdztr8jt4abrkdn435ewo
NEXT_PUBLIC_NEXUS=http://localhost:8080
NEXT_PUBLIC_TESTNET=true
NEXT_PUBLIC_DEFAULT_HTTP_RELAY=http://localhost:15412/link/
NEXT_PUBLIC_PKARR_RELAYS=["https://pkarr.pubky.app", "https://pkarr.pubky.org"]

# Configuration Mainnet (production)
# NEXT_PUBLIC_HOMESERVER=ufibwbmed6jeq9k4p583go95wofakh9fwpp4k734trq79pd9u1uy
# NEXT_PUBLIC_NEXUS=https://nexus.staging.pubky.app
# NEXT_PUBLIC_TESTNET=false
# NEXT_PUBLIC_DEFAULT_HTTP_RELAY=https://httprelay.staging.pubky.app/link

# Variables optionnelles
NEXT_PUBLIC_MODERATION_ID=euwmq57zefw5ynnkhh37b3gcmhs7g3cptdbw1doaxj1pbmzp3wro
NEXT_PUBLIC_MODERATED_TAGS=["nudity"]
NEXT_PUBLIC_CONFCOLOUR=blue
NEXT_TELEMETRY_DISABLED=1
```

#### Configuration Homeserver

Le homeserver utilise le fichier `homeserver/config/homeserver.config.toml` :

```toml
# Configuration par défaut du homeserver
signup_mode = "invite_only"
lmdb_backup_interval_hours = 24
user_storage_quota_bytes = 1073741824  # 1GB
pubky_listen_socket = "0.0.0.0:6287"
icann_listen_socket = "0.0.0.0:6286"
admin_password = "admin"

# Limites de taux
[rate_limits]
put_per_minute = 60
get_per_minute = 600
list_per_minute = 60
```

#### Configuration Nexus

Créez le fichier `pubky-nexus/config.toml` :

```toml
# Configuration Nexus
testnet = true
homeserver = "8pinxxgqs41n4aididenw5apqp1urfmzdztr8jt4abrkdn435ewo"

[database]
url = "bolt://neo4j:password@nexus-neo4j:7687"

[redis]
url = "redis://nexus-redis:6379"
```

### 3. Configuration Caddy

Le fichier `caddy/Caddyfile` configure le reverse proxy :

```caddyfile
# Configuration des domaines et redirections
{
    auto_https off
}

:80 {
    # Pubky App
    handle /app* {
        reverse_proxy pubky-app:4200
    }
    
    # HTTP Relay avec CORS
    handle /httprelay* {
        reverse_proxy httprelay:15412
        header Access-Control-Allow-Origin *
        header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        header Access-Control-Allow-Headers "Content-Type, Authorization"
    }
    
    # Nexus API
    handle /api* {
        reverse_proxy nexusd:8080
    }
    
    # Homeserver
    handle /homeserver* {
        reverse_proxy homeserver:6287
    }
    
    # Page par défaut
    respond "Pubky Stack is running!"
}
```

## 🔧 Démarrage de la stack

### Lancement complet

```bash
# Démarrer tous les services
docker-compose up -d

# Voir les logs
docker-compose logs -f

# Vérifier le statut
docker-compose ps
```

### Lancement sélectif

```bash
# Démarrer seulement le homeserver
docker-compose up -d homeserver

# Démarrer homeserver + nexus
docker-compose up -d homeserver nexusd

# Démarrer tout sauf pubky-app
docker-compose up -d homeserver nexusd caddy httprelay
```

## 🔍 Vérification et tests

### Vérifier les services

```bash
# Homeserver (doit répondre)
curl http://localhost:6287/health

# Nexus API (via Caddy)
curl http://localhost/api/health

# HTTP Relay
curl http://localhost:15412/health

# Pubky App
curl http://localhost:4200
```

### Générer un token d'invitation

```bash
# Générer un code d'invitation pour le homeserver
curl -X GET "http://localhost:6288/generate_signup_token" \
     -H "X-Admin-Password: admin"
```

## 📁 Structure des volumes

```
homeserver/
├── config/
│   ├── homeserver.config.toml    # Configuration homeserver
│   └── homeserver.entrypoint.sh  # Script de démarrage
└── data/                         # Données persistantes homeserver

caddy/
├── Caddyfile                     # Configuration reverse proxy
└── data/                         # Certificats SSL (volume Docker)

pubky-nexus/
├── config.toml                   # Configuration nexus
└── storage/                      # Données statiques nexus

pubky-app/
├── .env                          # Variables d'environnement
└── docs/                         # Documentation
```

## 🐛 Dépannage

### Problèmes courants

1. **Port déjà utilisé**
   ```bash
   # Vérifier les ports occupés
   netstat -tulpn | grep :80
   netstat -tulpn | grep :443
   ```

2. **Erreur de build pubky-app**
   ```bash
   # Reconstruire l'image
   docker-compose build --no-cache pubky-app
   ```

3. **Nexus ne se connecte pas**
   - Vérifier que le fichier `pubky-nexus/config.toml` existe
   - Vérifier la configuration du homeserver dans config.toml

4. **Homeserver ne démarre pas**
   - Vérifier les permissions sur `homeserver/data/`
   - Vérifier la configuration dans `homeserver.config.toml`

### Logs utiles

```bash
# Logs spécifiques par service
docker-compose logs homeserver
docker-compose logs nexusd
docker-compose logs pubky-app
docker-compose logs caddy

# Logs en temps réel
docker-compose logs -f --tail=100
```

### Redémarrage propre

```bash
# Arrêter tous les services
docker-compose down

# Nettoyer les volumes (ATTENTION: supprime les données)
docker-compose down -v

# Redémarrer
docker-compose up -d
```

## 🔗 URLs d'accès

Une fois la stack démarrée :

- **Application principale** : http://localhost
- **Pubky App** : http://localhost/app
- **API Nexus** : http://localhost/api
- **HTTP Relay** : http://localhost/httprelay
- **Homeserver direct** : http://localhost:6287

## 📚 Documentation supplémentaire

- [Pubky Core](https://github.com/pubky/pubky-core)
- [Pubky Nexus](https://github.com/pubky/pubky-nexus)
- [Pubky App](https://github.com/pubky/pubky-app)
- [Documentation locale Pubky App](./pubky-app/docs/local.md)

## 🤝 Contribution

Pour contribuer à cette stack :

1. Fork le repository
2. Créer une branche feature
3. Tester les modifications avec `docker-compose up`
4. Soumettre une pull request

## 📄 Licence

Ce projet suit les licences des projets Pubky individuels.