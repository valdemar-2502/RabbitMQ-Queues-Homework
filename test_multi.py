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
