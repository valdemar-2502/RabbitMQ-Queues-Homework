#!/usr/bin/env python3
import pika
import sys


credentials = pika.PlainCredentials('admin', 'admin')
parameters = pika.ConnectionParameters('localhost', 5672, '/', credentials)

try:
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    
   
    channel.queue_declare(queue='hello')
    
    
    message = ' '.join(sys.argv[1:]) or "Hello World!"
    channel.basic_publish(exchange='', routing_key='hello', body=message)
    print(f" [x] Sent '{message}'")
    
    connection.close()
    print(" [✓] Сообщение успешно отправлено")
    
except Exception as e:
    print(f" [✗] Ошибка: {e}")
