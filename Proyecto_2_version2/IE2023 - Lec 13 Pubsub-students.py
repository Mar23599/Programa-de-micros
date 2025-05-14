# Import standard python modules.
import sys
import time
import serial

# This example uses the MQTTClient instead of the REST client
from Adafruit_IO import MQTTClient
from Adafruit_IO import Client, Feed

# Configuración de comunicación serial con Arduino
ARDUINO_PORT = 'COM3'  # Cambiar al puerto correcto (COM3, COM4, /dev/ttyACM0, etc.)
ARDUINO_BAUDRATE = 9600  # Debe coincidir con la velocidad configurada en Arduino

try:
    arduino = serial.Serial(ARDUINO_PORT, ARDUINO_BAUDRATE, timeout=1)
    time.sleep(2)  # Esperar a que se establezca la conexión
    print(f"Conexión establecida con Arduino en {ARDUINO_PORT}")
except serial.SerialException as e:
    print(f"Error al conectar con Arduino: {e}")
    sys.exit(1)

# holds the count for the feed
run_count = 0

# Set to your Adafruit IO username and key.
ADAFRUIT_IO_USERNAME = "Mar23599"
ADAFRUIT_IO_KEY = "aio_RXPm314Emly7tcg2QsMeyxWDKkbr"

# Set to the ID of the feed to subscribe to for updates.
FEED_ID_EEPROM = 'EPROM_control'
FEED_ID_S1 = 'Servo1_TX'
FEED_ID_S2 = 'Servo2_TX'
FEED_ID_S3 = 'Servo3_TX'
FEED_ID_S4 = 'Servo4_TX'
FEED_ID_CONFIRM = 'CONFIRM_F'

def connected(client):
    """Connected function will be called when the client is connected to
    Adafruit IO.This is a good place to subscribe to feed changes."""
    print('Subscribing to Feeds: EEPROM, Servo1-4')
    client.subscribe(FEED_ID_EEPROM)
    client.subscribe(FEED_ID_S1)
    client.subscribe(FEED_ID_S2)
    client.subscribe(FEED_ID_S3)
    client.subscribe(FEED_ID_S4)
    print('Waiting for feed data...')

def disconnected(client):
    """Disconnected function will be called when the client disconnects."""
    print('Desconectado de Adafruit IO!')
    arduino.close()  # Cerrar conexión serial al salir
    sys.exit(1)

def message(client, feed_id, payload):
    """Message function will be called when a subscribed feed has a new value."""
    print(f'Feed {feed_id} received new value: {payload}')
    
    # Determinar el comando para Arduino según el feed
    if feed_id == FEED_ID_EEPROM:
        arduino_cmd = f"EP:{payload}\n"
        confirm_msg = f"EP:{payload}"
    elif feed_id == FEED_ID_S1:
        arduino_cmd = f"S1:{payload}\n"
        confirm_msg = f"S1:{payload}"
    elif feed_id == FEED_ID_S2:
        arduino_cmd = f"S2:{payload}\n"
        confirm_msg = f"S2:{payload}"
    elif feed_id == FEED_ID_S3:
        arduino_cmd = f"S3:{payload}\n"
        confirm_msg = f"S3:{payload}"
    elif feed_id == FEED_ID_S4:
        arduino_cmd = f"S4:{payload}\n"
        confirm_msg = f"S4:{payload}"
    else:
        print(f"Feed no reconocido: {feed_id}")
        return
    
    try:
        # Enviar comando a Arduino
        arduino.write(arduino_cmd.encode('utf-8'))
        print(f"Enviado a Arduino: {arduino_cmd.strip()}")
        
        # Opcional: Leer respuesta de Arduino (si envía alguna)
        if arduino.in_waiting:
            response = arduino.readline().decode('utf-8').strip()
            print(f"Respuesta de Arduino: {response}")
        
        # Enviar confirmación a Adafruit IO
        client.publish(FEED_ID_CONFIRM, confirm_msg)
        print(f"Confirmación enviada: {confirm_msg}")
        
    except serial.SerialException as e:
        print(f"Error de comunicación con Arduino: {e}")
        client.disconnect()

# Create an MQTT client instance.
client = MQTTClient(ADAFRUIT_IO_USERNAME, ADAFRUIT_IO_KEY)

# Setup the callback functions defined above.
client.on_connect = connected
client.on_disconnect = disconnected
client.on_message = message

# Connect to the Adafruit IO server.
client.connect()

# The first option is to run a thread in the background so you can continue
# doing things in your program.
client.loop_background()

print("Sistema iniciado. Esperando datos...")
print("Presiona Ctrl+C para salir")

try:
    while True:
        # Puedes añadir aquí otras tareas si es necesario
        time.sleep(1)
except KeyboardInterrupt:
    print("\nCerrando conexiones...")
    arduino.close()
    client.disconnect()
    sys.exit(0)