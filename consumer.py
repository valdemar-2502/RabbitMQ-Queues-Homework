#!/usr/bin/env python3
import pika
import time


credentials = pika.PlainCredentials('admin', 'admin')
parameters = pika.ConnectionParameters('localhost', 5672, '/', credentials)

def callback(ch, method, properties, body):
    print(f" [x] Получено сообщение: {body.decode()}")
   
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
