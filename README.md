# WordPress Landing Page - Production Deployment

A production-ready WordPress deployment using Docker, Traefik reverse proxy, and automated CI/CD with GitHub Actions.

## 🏗️ Architecture

-   **WordPress** (PHP-FPM + Nginx)
-   **MariaDB** (Database)
-   **Traefik** (Reverse proxy with automatic SSL)
-   **Ansible** (Infrastructure automation)
-   **GitHub Actions** (CI/CD pipeline)

## 🚀 Quick Start

### Prerequisites

1. **VPS Requirements:**

    - Ubuntu 20.04+ or Debian 11+
    - Root or sudo access
    - SSH key access
    - 1GB+ RAM, 20GB+ storage

2. **Domain Setup:**

    - Domain pointing to your VPS IP
    - Subdomain for Traefik dashboard (optional)

3. **Local Requirements:**
    - Git
    - Ansible (for manual deployment)

### 1. Clone and Configure

```bash
git clone <your-repo>
cd landing
cp env.template .env
```

### 2. Configure Environment

Edit `.env` with your actual values:

```bash
# Required configuration
DOMAIN=yourdomain.com
DB_ROOT_PASSWORD=secure_root_password
DB_NAME=wordpress_db
DB_USER=wp_user
DB_PASSWORD=secure_db_password
ACME_EMAIL=admin@yourdomain.com
```

### 3. Set Up GitHub Secrets

Add these secrets to your GitHub repository:

| Secret             | Description                    | Example                          |
| ------------------ | ------------------------------ | -------------------------------- |
| `SSH_PRIVATE_KEY`  | SSH private key for VPS access | `-----BEGIN PRIVATE KEY-----...` |
| `VPS_HOST`         | Your VPS IP address            | `123.456.789.123`                |
| `VPS_USER`         | SSH username                   | `root`                           |
| `DOMAIN_NAME`      | Your domain                    | `yourdomain.com`                 |
| `ACME_EMAIL`       | Email for Let's Encrypt        | `admin@yourdomain.com`           |
| `DB_ROOT_PASSWORD` | MariaDB root password          | `secure_password`                |
| `DB_NAME`          | WordPress database name        | `wordpress_db`                   |
| `DB_USER`          | WordPress database user        | `wp_user`                        |
| `DB_PASSWORD`      | WordPress database password    | `secure_password`                |
| `WP_TABLE_PREFIX`  | WordPress table prefix         | `wp_`                            |
| `WP_DEBUG`         | WordPress debug mode           | `false`                          |

### 4. Deploy

#### Automatic Deployment (Recommended)

Push to main branch or trigger workflow manually:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

#### Manual Deployment

```bash
cd ansible
ansible-playbook playbooks/deploy.yml -i inventory/hosts.yml
```

## 🔧 Configuration

### Ansible Inventory

Edit `ansible/inventory/hosts.yml`:

```yaml
all:
    children:
        wordpress:
            hosts:
                production:
                    ansible_host: YOUR_VPS_IP
                    ansible_user: root
            vars:
                domain_name: yourdomain.com
                acme_email: admin@yourdomain.com
                # ... other vars
```

### Custom Docker Compose

The stack includes:

-   **Traefik**: Reverse proxy with automatic SSL
-   **WordPress**: PHP-FPM with optimized settings
-   **Nginx**: Web server optimized for WordPress
-   **MariaDB**: Database with performance tuning

### Security Features

-   UFW firewall configuration
-   Security headers via Traefik
-   File upload restrictions
-   Database isolation
-   SSL/TLS termination

## 📊 Monitoring

### Health Checks

-   **Application**: `https://yourdomain.com/health`
-   **Traefik Dashboard**: `https://traefik.yourdomain.com`

### Log Access

```bash
# Application logs
docker-compose logs -f wordpress

# Database logs
docker-compose logs -f mariadb

# Traefik logs
docker-compose logs -f traefik
```

## 🔄 Updates & Maintenance

### Updating WordPress

The deployment will automatically pull the latest WordPress image. To update:

```bash
# Via GitHub Actions
git commit --allow-empty -m "Trigger deployment"
git push origin main

# Via Ansible
ansible-playbook playbooks/deploy.yml -i inventory/hosts.yml
```

### Backup

Database backups can be automated via cron:

```bash
# Backup script (run on VPS)
docker exec wordpress-db mysqldump -u root -p$DB_ROOT_PASSWORD $DB_NAME > backup_$(date +%Y%m%d).sql
```

### SSL Certificate Renewal

Traefik automatically renews Let's Encrypt certificates.

## 🛠️ Development

### Local Development

```bash
# Copy environment template
cp env.template .env

# Edit with local values
vim .env

# Start services
docker-compose up -d

# Access site
open http://localhost
```

### Project Structure

```
├── docker-compose.yml          # Main Docker services
├── traefik/                    # Reverse proxy config
├── nginx/                      # Web server config
├── ansible/                    # Deployment automation
├── .github/workflows/          # CI/CD pipeline
├── uploads.ini                 # PHP configuration
└── env.template               # Environment template
```

## 🚨 Troubleshooting

### Common Issues

1. **SSL Certificate Issues**

    ```bash
    # Check Traefik logs
    docker-compose logs traefik

    # Verify DNS is pointing to server
    dig yourdomain.com
    ```

2. **Database Connection Issues**

    ```bash
    # Check database status
    docker-compose logs mariadb

    # Verify credentials in .env
    cat .env
    ```

3. **WordPress Installation**
    - Navigate to `https://yourdomain.com`
    - Follow WordPress setup wizard
    - Use database credentials from `.env`

### Support

For deployment issues:

1. Check GitHub Actions logs
2. Review Ansible output
3. Verify all secrets are configured
4. Ensure DNS propagation is complete

## 📜 License

This project is open source and available under the [MIT License](LICENSE).

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test deployment
5. Submit a pull request

---

**Built with ❤️ for production WordPress deployments**
