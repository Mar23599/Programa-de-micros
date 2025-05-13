import serial
import time
from Adafruit_IO import MQTTClient

# Configura el nombre de usuario y la key de Adafruit IO
ADAFRUIT_IO_USERNAME = 'Mar23599'
ADAFRUIT_IO_KEY = 'aio_RXPm314Emly7tcg2QsMeyxWDKkbr'

# Define los feeds
FEED_ID_S1 = 'servo1'
FEED_ID_S2 = 'servo2'
FEED_ID_S3 = 'servo3'
FEED_ID_S4 = 'servo4'
FEED_ID_EEPROM = 'EPROM_control'
FEED_ID_CONFIRM = 'CONFIRM_F'

# Crear el objeto cliente de MQTT
client = MQTTClient(ADAFRUIT_IO_USERNAME, ADAFRUIT_IO_KEY)

# Puerto y velocidad de comunicación serial con el Arduino
myArduino = serial.Serial('COM3', 9600)
time.sleep(2)  # Tiempo para que el Arduino reinicie

def connected(client):
    print('Conectado a Adafruit IO')
    client.subscribe(FEED_ID_S1)
    client.subscribe(FEED_ID_S2)
    client.subscribe(FEED_ID_S3)
    client.subscribe(FEED_ID_S4)
    client.subscribe(FEED_ID_EEPROM)

def message(client, feed_id, payload):
    print(f'Feed {feed_id} recibió nuevo valor: {payload}')

    if feed_id == FEED_ID_EEPROM:
        serial_msg = f"EP:{payload}"
    elif feed_id == FEED_ID_S1:
        serial_msg = f"S1:{chr(int(payload))}"
    elif feed_id == FEED_ID_S2:
        serial_msg = f"S2:{chr(int(payload))}"
    elif feed_id == FEED_ID_S3:
        serial_msg = f"S3:{chr(int(payload))}"
    elif feed_id == FEED_ID_S4:
        serial_msg = f"S4:{chr(int(payload))}"
    else:
        print("Feed no reconocido.")
        return

    print(f"Enviando por serial: {serial_msg}")
    myArduino.write(serial_msg.encode())

    # Esperar confirmación
    ack_expected = f"ACK:{serial_msg}"
    ack_received = False
    start_time = time.time()
    while time.time() - start_time < 2:  # 2 segundos para esperar ACK
        if myArduino.in_waiting:
            response = myArduino.readline().decode().strip()
            print(f"Recibido del ATmega: {response}")
            if response == ack_expected:
                ack_received = True
                break

    if ack_received:
        print("✔ Confirmación recibida.")
        client.publish(FEED_ID_CONFIRM, f"✓ {serial_msg}")
    else:
        print("⚠ No se recibió confirmación.")
        client.publish(FEED_ID_CONFIRM, f"X {serial_msg}")

# Asignar las funciones de conexión y mensajes
client.on_connect = connected
client.on_message = message

# Conectarse a Adafruit IO y comenzar el loop
client.connect()
client.loop_blocking()
