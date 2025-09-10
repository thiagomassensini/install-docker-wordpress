#!/bin/bash

# ========================================
# Script de Instalação Docker + WordPress
# Autor: Thiago Motta
# ========================================

DB_ROOT_PASSWORD="senha_root_123"
DB_NAME="wordpress_db"
DB_USER="wp_admin"
DB_PASSWORD="senha_wp_456"
WP_CONTAINER_NAME="meu_wordpress"
DB_CONTAINER_NAME="mysql_wordpress"

# Instalar dependências
sudo apt install ca-certificates curl gnupg lsb-release -y -qq

# Configurar repositório Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y -qq

# Configurar usuário
sudo usermod -aG docker $USER

# Criar diretório do projeto
mkdir -p ~/wordpress-docker
cd ~/wordpress-docker

# Criar docker-compose.yml (usando EOF sem aspas para expandir variáveis)
cat << EOF > docker-compose.yml
version: '3.8'

services:
  db:
    image: mysql:5.7
    container_name: $DB_CONTAINER_NAME
    restart: unless-stopped
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: $DB_ROOT_PASSWORD
      MYSQL_DATABASE: $DB_NAME
      MYSQL_USER: $DB_USER
      MYSQL_PASSWORD: $DB_PASSWORD
    networks:
      - wordpress_network

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    container_name: $WP_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: $DB_USER
      WORDPRESS_DB_PASSWORD: $DB_PASSWORD
      WORDPRESS_DB_NAME: $DB_NAME
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - wordpress_network

volumes:
  db_data:
  wordpress_data:

networks:
  wordpress_network:
    driver: bridge
EOF

# Subir containers com sudo (para garantir permissões)
sudo docker compose up -d

# Aguardar inicialização
sleep 15

# Mostrar status
sudo docker compose ps

echo ""
echo "Instalação concluída!"
echo "Acesse: http://localhost"
echo "Diretório: ~/wordpress-docker"
