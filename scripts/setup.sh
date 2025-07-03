#!/bin/bash

# WordPress Landing Page Setup Script
# This script helps with initial setup and configuration

set -e

echo "🚀 WordPress Landing Page Setup"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check Ansible (optional for local dev)
    if ! command -v ansible &> /dev/null; then
        log_warn "Ansible is not installed. Required for production deployment."
    fi
    
    log_info "Dependencies check completed."
}

setup_environment() {
    log_info "Setting up environment configuration..."
    
    if [ ! -f .env ]; then
        cp env.template .env
        log_info "Created .env file from template"
        log_warn "Please edit .env file with your actual configuration before proceeding"
    else
        log_info ".env file already exists"
    fi
}

generate_passwords() {
    log_info "Generating secure passwords..."
    
    DB_ROOT_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    DB_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    echo ""
    echo "Generated passwords (save these securely):"
    echo "DB_ROOT_PASSWORD=$DB_ROOT_PASS"
    echo "DB_PASSWORD=$DB_PASS"
    echo ""
    
    read -p "Update .env file with these passwords? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sed -i.bak "s/your_strong_root_password_here/$DB_ROOT_PASS/" .env
        sed -i.bak "s/your_strong_db_password_here/$DB_PASS/" .env
        log_info "Updated .env file with generated passwords"
    fi
}

setup_docker_network() {
    log_info "Setting up Docker network..."
    
    if ! docker network ls | grep -q "web"; then
        docker network create web
        log_info "Created 'web' Docker network"
    else
        log_info "'web' Docker network already exists"
    fi
}

validate_env() {
    log_info "Validating environment configuration..."
    
    if [ ! -f .env ]; then
        log_error ".env file not found. Run setup first."
        exit 1
    fi
    
    # Source the .env file
    set -a
    source .env
    set +a
    
    # Check required variables
    required_vars=("DOMAIN" "DB_ROOT_PASSWORD" "DB_PASSWORD" "ACME_EMAIL")
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ] || [ "${!var}" = "your_strong_root_password_here" ] || [ "${!var}" = "your_strong_db_password_here" ] || [ "${!var}" = "yourdomain.com" ]; then
            log_error "Please configure $var in .env file"
            exit 1
        fi
    done
    
    log_info "Environment validation completed"
}

start_services() {
    log_info "Starting WordPress services..."
    
    docker-compose pull
    docker-compose up -d
    
    log_info "Services started successfully!"
    log_info "WordPress will be available at: http://localhost"
    log_info "Traefik dashboard: http://localhost:8080"
    
    # Wait for services
    log_info "Waiting for services to be ready..."
    sleep 10
    
    # Health check
    if curl -f http://localhost/health &> /dev/null; then
        log_info "✅ Health check passed!"
    else
        log_warn "Health check failed. Services may still be starting up."
    fi
}

stop_services() {
    log_info "Stopping WordPress services..."
    docker-compose down
    log_info "Services stopped"
}

show_status() {
    log_info "Service Status:"
    docker-compose ps
}

show_logs() {
    log_info "Showing logs..."
    docker-compose logs -f
}

backup_data() {
    log_info "Creating backup..."
    
    BACKUP_DIR="backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup database
    if docker-compose ps | grep -q wordpress-db; then
        docker-compose exec -T mariadb mysqldump -u root -p"$DB_ROOT_PASSWORD" "$DB_NAME" > "$BACKUP_DIR/database.sql"
        log_info "Database backup created: $BACKUP_DIR/database.sql"
    fi
    
    # Backup WordPress files
    if [ -d "wp_data" ]; then
        tar -czf "$BACKUP_DIR/wordpress_files.tar.gz" wp_data/
        log_info "WordPress files backup created: $BACKUP_DIR/wordpress_files.tar.gz"
    fi
    
    log_info "Backup completed in: $BACKUP_DIR"
}

show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup       - Initial setup (create .env, generate passwords)"
    echo "  start       - Start WordPress services"
    echo "  stop        - Stop WordPress services"
    echo "  restart     - Restart WordPress services"
    echo "  status      - Show service status"
    echo "  logs        - Show service logs"
    echo "  backup      - Create backup of data"
    echo "  clean       - Clean up containers and volumes"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup    # Initial setup"
    echo "  $0 start    # Start services"
    echo "  $0 logs     # View logs"
}

# Main script logic
case "${1:-help}" in
    "setup")
        check_dependencies
        setup_environment
        generate_passwords
        setup_docker_network
        log_info "✅ Setup completed! Edit .env file and run '$0 start' to begin."
        ;;
    "start")
        validate_env
        setup_docker_network
        start_services
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        stop_services
        validate_env
        start_services
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "backup")
        validate_env
        backup_data
        ;;
    "clean")
        log_warn "This will remove all containers and volumes. Data will be lost!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose down -v
            docker system prune -f
            log_info "Cleanup completed"
        fi
        ;;
    "help"|*)
        show_help
        ;;
esac 