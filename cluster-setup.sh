#!/bin/bash

echo "=== Настройка HA кластера RabbitMQ ==="

# Останавливаем и удаляем старые контейнеры
echo "Очистка старых контейнеров..."
docker stop rmq01 rmq02 2>/dev/null
docker rm rmq01 rmq02 2>/dev/null

# Создаем сеть Docker
docker network create rabbitmq-network 2>/dev/null || echo "Сеть уже существует"

# Узел 1 - используем другой порт
echo "Запуск первого узла (rmq01)..."
docker run -d \
  --name rmq01 \
  --hostname rmq01 \
  --network rabbitmq-network \
  -p 15673:15672 \
  -p 5673:5672 \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS=admin \
  -e RABBITMQ_ERLANG_COOKIE="SECRETCOOKIE123" \
  rabbitmq:3.12-management

# Ждем запуска первого узла
echo "Ожидание запуска первого узла (20 секунд)..."
sleep 20

# Узел 2
echo "Запуск второго узла (rmq02)..."
docker run -d \
  --name rmq02 \
  --hostname rmq02 \
  --network rabbitmq-network \
  -p 15674:15672 \
  -p 5674:5672 \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS=admin \
  -e RABBITMQ_ERLANG_COOKIE="SECRETCOOKIE123" \
  rabbitmq:3.12-management

# Ждем запуска второго узла
echo "Ожидание запуска второго узла (15 секунд)..."
sleep 15

# Получаем IP адрес первого узла в сети Docker
RABBIT1_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' rmq01)
echo "IP адрес rmq01: $RABBIT1_IP"

# Настройка кластера
echo "Настройка кластера..."
docker exec rmq02 rabbitmqctl stop_app
docker exec rmq02 rabbitmqctl reset
docker exec rmq02 rabbitmqctl join_cluster rabbit@rmq01
docker exec rmq02 rabbitmqctl start_app

# Ждем синхронизации
sleep 10

# HA политика
echo "Создание HA политики..."
docker exec rmq01 rabbitmqctl set_policy ha-all "^" '{"ha-mode":"all", "ha-sync-mode":"automatic"}'

echo ""
echo "=== Кластер готов! ==="
echo "Узел 1: http://localhost:15673 (rmq01)"
echo "Узел 2: http://localhost:15674 (rmq02)"
echo "Логин: admin"
echo "Пароль: admin"
echo ""
echo "Проверка кластера на узле 1:"
docker exec rmq01 rabbitmqctl cluster_status
echo ""
echo "Проверка кластера на узле 2:"
docker exec rmq02 rabbitmqctl cluster_status
