#!/bin/bash

echo "=== Настройка окружения для RabbitMQ задания ==="

# 1. Установите RabbitMQ через Docker
echo "Установка RabbitMQ через Docker..."
sudo apt-get update
sudo apt-get install -y docker.io

# Запустите RabbitMQ контейнер
sudo docker run -d \
  --name rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS=admin \
  rabbitmq:3-management

echo "Ожидание запуска RabbitMQ..."
sleep 15

# 2. Создайте виртуальное окружение Python
echo "Создание виртуального окружения Python..."
python3 -m venv rabbitmq-env
source rabbitmq-env/bin/activate

# 3. Установите pika
echo "Установка библиотеки pika..."
pip install pika

# 4. Создайте тестовые скрипты
echo "Создание тестовых скриптов..."

cat > producer.py << 'EOF'
#!/usr/bin/env python3
import pika
import sys

# Параметры подключения
credentials = pika.PlainCredentials('admin', 'admin')
parameters = pika.ConnectionParameters('localhost', 5672, '/', credentials)

try:
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    
    # Создаем очередь
    channel.queue_declare(queue='hello')
    
    # Отправляем сообщение
    message = ' '.join(sys.argv[1:]) or "Hello World!"
    channel.basic_publish(exchange='', routing_key='hello', body=message)
    print(f" [x] Sent '{message}'")
    
    connection.close()
    print(" [✓] Сообщение успешно отправлено")
    
except Exception as e:
    print(f" [✗] Ошибка: {e}")
EOF

cat > consumer.py << 'EOF'
#!/usr/bin/env python3
import pika
import time

# Параметры подключения
credentials = pika.PlainCredentials('admin', 'admin')
parameters = pika.ConnectionParameters('localhost', 5672, '/', credentials)

def callback(ch, method, properties, body):
    print(f" [x] Получено сообщение: {body.decode()}")
    # Имитация обработки
    dots_count = body.count(b'.')
    if dots_count:
        print(f"     Обработка {dots_count} секунд...")
        time.sleep(dots_count)
    print(" [✓] Сообщение обработано")

try:
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    
    channel.queue_declare(queue='hello')
    
    print(' [*] Ожидание сообщений. Для выхода нажмите CTRL+C')
    print(' [*] Подключено к RabbitMQ на localhost:5672')
    
    channel.basic_consume(queue='hello', on_message_callback=callback, auto_ack=True)
    channel.start_consuming()
    
except KeyboardInterrupt:
    print("\n [✓] Потребитель остановлен")
except Exception as e:
    print(f" [✗] Ошибка: {e}")
EOF

cat > test_multi.py << 'EOF'
#!/usr/bin/env python3
import pika
import threading
import time

def producer():
    credentials = pika.PlainCredentials('admin', 'admin')
    parameters = pika.ConnectionParameters('localhost', 5672, '/', credentials)
    
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    
    channel.queue_declare(queue='test_queue')
    
    for i in range(5):
        message = f"Сообщение {i+1} в {time.ctime()}"
        channel.basic_publish(exchange='', routing_key='test_queue', body=message)
        print(f" [P] Отправлено: {message}")
        time.sleep(1)
    
    connection.close()

def consumer():
    credentials = pika.PlainCredentials('admin', 'admin')
    parameters = pika.ConnectionParameters('localhost', 5672, '/', credentials)
    
    def callback(ch, method, properties, body):
        print(f" [C] Получено: {body.decode()}")
    
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    
    channel.queue_declare(queue='test_queue')
    channel.basic_consume(queue='test_queue', on_message_callback=callback, auto_ack=True)
    
    print(" [C] Потребитель запущен...")
    channel.start_consuming()

if __name__ == "__main__":
    # Запуск потребителя в отдельном потоке
    consumer_thread = threading.Thread(target=consumer, daemon=True)
    consumer_thread.start()
    
    # Даем время потребителю запуститься
    time.sleep(2)
    
    # Запуск производителя
    producer()
    
    # Ожидание завершения
    time.sleep(3)
    print("\n [✓] Тест завершен!")
EOF

# 5. Сделайте скрипты исполняемыми
chmod +x producer.py consumer.py test_multi.py

echo ""
echo "=== Настройка завершена! ==="
echo ""
echo "Инструкция:"
echo "1. RabbitMQ доступен по адресу: http://localhost:15672"
echo "   Логин: admin, Пароль: admin"
echo ""
echo "2. Активируйте виртуальное окружение:"
echo "   source rabbitmq-env/bin/activate"
echo ""
echo "3. Тестовые команды:"
echo "   ./producer.py 'Ваше сообщение'"
echo "   ./consumer.py"
echo "   python test_multi.py"
echo ""
echo "4. Для деактивации виртуального окружения: deactivate"
