#!/bin/bash

# ========================================
# Script de Instalação Docker + WordPress + phpMyAdmin (sem compose)
# Autor: Thiago Motta
# ========================================

# Usar variáveis de ambiente ou valores padrão
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-"minha_senha_root_123"}
DB_NAME=${DB_NAME:-"wordpress_db"}
DB_USER=${DB_USER:-"wp_admin"}
DB_PASSWORD=${DB_PASSWORD:-"senha_wp_segura_456"}
WP_CONTAINER_NAME=${WP_CONTAINER_NAME:-"meu_wordpress"}
DB_CONTAINER_NAME=${DB_CONTAINER_NAME:-"mysql_wordpress"}

# Instalar Docker
sudo apt update -y
sudo apt install ca-certificates curl gnupg lsb-release -y -qq

# Configurar repositório Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y -qq

# Configurar usuário
sudo usermod -aG docker $USER

# Criar rede para os containers se comunicarem
sudo docker network create wordpress_network

# Criar volume para o MySQL
sudo docker volume create db_data

# Criar volume para o WordPress
sudo docker volume create wordpress_data

# Executar container MySQL
sudo docker run -d \
  --name $DB_CONTAINER_NAME \
  --network wordpress_network \
  -e MYSQL_ROOT_PASSWORD=$DB_ROOT_PASSWORD \
  -e MYSQL_DATABASE=$DB_NAME \
  -e MYSQL_USER=$DB_USER \
  -e MYSQL_PASSWORD=$DB_PASSWORD \
  -v db_data:/var/lib/mysql \
  --restart unless-stopped \
  mysql:5.7

# Aguardar MySQL inicializar
sleep 15

# Executar container WordPress
sudo docker run -d \
  --name $WP_CONTAINER_NAME \
  --network wordpress_network \
  -e WORDPRESS_DB_HOST=$DB_CONTAINER_NAME:3306 \
  -e WORDPRESS_DB_USER=$DB_USER \
  -e WORDPRESS_DB_PASSWORD=$DB_PASSWORD \
  -e WORDPRESS_DB_NAME=$DB_NAME \
  -v wordpress_data:/var/www/html \
  -p 80:80 \
  --restart unless-stopped \
  wordpress:latest

# Executar container phpMyAdmin
sudo docker run -d \
  --name phpmyadmin \
  --network wordpress_network \
  -e PMA_HOST=$DB_CONTAINER_NAME \
  -e PMA_PORT=3306 \
  -p 8080:80 \
  --restart always \
  phpmyadmin/phpmyadmin

# Mostrar status
echo ""
echo "Containers em execução:"
sudo docker ps

echo ""
echo "Instalação concluída!"
echo "Acesse o WordPress: http://localhost"
echo "Acesse o phpMyAdmin: http://localhost:8080"
echo ""
echo "Credenciais do MySQL:"
echo "Usuário: $DB_USER"
echo "Senha: $DB_PASSWORD"
echo "Database: $DB_NAME"
