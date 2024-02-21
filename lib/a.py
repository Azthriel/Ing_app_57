import paho.mqtt.client as mqtt
import ssl
import time

broker = 'nee8a41e.ala.us-east-1.emqxsl.com'
port = 8883
username = '015773_IOT'
password = '015773_IOT'
ca_cert_route = 'emqx_ca.crt'

sleep_time = 6

##################################

device_list = []
response_list = []
data_dict = {}

def set_sleep_time(new_sleep_time):
    global sleep_time
    sleep_time = new_sleep_time
    print('NEW SLEEP TIME SAVED: ' + str(new_sleep_time))

def make_txt(): # pregunta al usuario si quiere una copia de la data
    inp = input('¿Deseas crear un archivo? (y/n)\n')

    if inp.lower() == 'y':
        name = input('¿Nombre del archivo?\n')
        with open(name + '.txt', 'w') as file:
            for devs, datos in sorted(data_dict.items(), key=lambda x: x[0][-2:]):
                file.write(f"{devs}: {datos}\n")
        print(f"Archivo {name}.txt creado.")
    else:
        print("No se creará archivo.")

    data_dict.clear()  # Limpiar el diccionario

def register(): # esta al recontra pedo

    for devs in range(len(device_list)):
        print("LOADING DEVICE: " + str(device_list[devs]))
        #client.subscribe(topic='015773_IOT/' + str(device_list[devs]), qos=0)

def diagnosis():

    data_dict.clear() # start with a new fresh dict
    client.publish(topic='015773_RB', payload='DIAGNOSIS_OK', qos=1)

    print('SLEEPING TO RECEIVE DATA')
    time.sleep(sleep_time)

    print('READING THE DATA: ')

    for devs in device_list:
        if devs in data_dict:
            None
        else:
            data_dict[devs] = 'fail' # fills the numbers not found

    # DATOS DE RETORNO -> d_ok:ssid:ip:sv

    # Función para obtener los últimos dos caracteres de una cadena
    def split(clave):
        return clave[-2:]
    for devs in sorted(data_dict, key=split):
        print(f"DEVICE: ({devs}, {data_dict[devs]})")

    make_txt()

    print('DIAGNOSIS DONE\n')

def regulation():

    ####

    rp = input('regpoint to do: ')
    temp = input('temperature: ')

    ####

    data_dict.clear() # start with a new fresh dict
    client.publish(topic='015773_RB', payload='REGPOINT_' + str(rp) + '_(' + str(temp) + ')', qos=1)

    print('SLEEPING TO RECEIVE DATA')
    time.sleep(sleep_time)

    print('READING THE DATA: ')

    for devs in device_list:
        if devs in data_dict:
            None
        else:
            data_dict[devs] = 'fail' # fills the numbers not found

    # DATOS DE RETORNO -> rp_ok:ectemp:rs

    # Función para obtener los últimos dos caracteres de una cadena
    def split(clave):
        return clave[-2:]
    for devs in sorted(data_dict, key=split):
        print(f"DEVICE: ({devs}, {data_dict[devs]})")

    make_txt()

    print('REGPOINT DONE\n')

def reg_done():

    data_dict.clear() # start with a new fresh dict
    client.publish(topic='015773_RB', payload='REG_DONE', qos=1)

    print('SLEEPING TO RECEIVE DATA')
    time.sleep(sleep_time)

    print('READING THE DATA: ')

    for devs in device_list:
        if devs in data_dict:
            None
        else:
            data_dict[devs] = 'fail' # fills the numbers not found

    # DATOS DE RETORNO -> rd_ok:rsch4_al:rsco_al

    # Función para obtener los últimos dos caracteres de una cadena
    def split(clave):
        return clave[-2:]
    for devs in sorted(data_dict, key=split):
        print(f"DEVICE: ({devs}, {data_dict[devs]})")

    make_txt()

    print('REG_DONE DONE\n')

##------------------------------##
    
def diagnosis_gas():

    data_dict.clear() # start with a new fresh dict
    client.publish(topic='015773_RB', payload='DIAGNOSIS_CH4', qos=1)

    print('SLEEPING TO RECEIVE DATA')
    time.sleep(sleep_time)

    print('READING THE DATA: ')

    for devs in device_list:
        if devs in data_dict:
            None
        else:
            data_dict[devs] = 'fail' # fills the numbers not found

    # DATOS DE RETORNO -> dg_ok:ppmch4:rsch4:actual_temp

    # Función para obtener los últimos dos caracteres de una cadena
    def split(clave):
        return clave[-2:]
    for devs in sorted(data_dict, key=split):
        print(f"DEVICE: ({devs}, {data_dict[devs]})")

    make_txt()

    print('DIAGNOSIS_CH4 DONE\n')

def diagnosis_co():

    data_dict.clear() # start with a new fresh dict
    client.publish(topic='015773_RB', payload='DIAGNOSIS_CO', qos=1)

    print('SLEEPING TO RECEIVE DATA')
    time.sleep(sleep_time)

    print('READING THE DATA: ')

    for devs in device_list:
        if devs in data_dict:
            None
        else:
            data_dict[devs] = 'fail' # fills the numbers not found

    # DATOS DE RETORNO -> dc_ok:ppmco:rsco:actual_temp

    # Función para obtener los últimos dos caracteres de una cadena
    def split(clave):
        return clave[-2:]
    for devs in sorted(data_dict, key=split):
        print(f"DEVICE: ({devs}, {data_dict[devs]})")

    make_txt()

    print('DIAGNOSIS_CO DONE\n')

def esp_update():

    url = 'https://github.com/CrisDores/57_IOT_PUBLIC/raw/main/57_ota_factory_fw/firmware.bin'

    data_dict.clear() # start with a new fresh dict
    client.publish(topic='015773_RB', payload='ESP_UPDATE(' + str(url) + ')', qos=1)

    print('SLEEPING TO RECEIVE DATA')
    time.sleep(sleep_time)

    print('READING THE DATA: ')

    for devs in device_list:
        if devs in data_dict:
            None
        else:
            data_dict[devs] = 'fail' # fills the numbers not found

    # DATOS DE RETORNO -> eu_ok:ssid:ip

    # Función para obtener los últimos dos caracteres de una cadena
    def split(clave):
        return clave[-2:]
    for devs in sorted(data_dict, key=split):
        print(f"DEVICE: ({devs}, {data_dict[devs]})")

    make_txt()

    print('ESP_UPDATE DONE\n')

##################################

def on_connect(client, userdata, flags, rc):
    print("Conectado con código de resultado " + str(rc) + '\n\n')
    client.subscribe(topic='015773_IOT/+', qos=1)

def on_message(client, userdata, msg):
    print('MESSAGE ARRIVED')

    # Extraer el número de serie del topic
    topic_parts = msg.topic.split('/')
    if len(topic_parts) > 1:
        serial_number = topic_parts[1]

    payload_str = msg.payload.decode()  # Decodificar el payload de bytes a string
    data_parts = payload_str.split(':')  # Dividir el payload por ':'

    data_dict[serial_number] = data_parts

def my_loop():

    if(client.is_connected()):
        print('bienvenido a regbank2')
        inp = input('(n)new_devices // (m)make_register // (d)diagnosis // (r)regulation\n(dg)diagnosis_gas // (dc)diagnosis_co // (rd)reg_done\n(eu)esp_update // (pu)pic_update\n(nt)new_sleep_time\n')

        if(inp == 'n' or inp == 'N'):
            snHeader = int(input("Enter the header: "))
            initialnumber = int(input("Enter the initial value: "))
            finalnumber = int(input("Enter the final value: "))

            for devs in range(initialnumber, finalnumber + 1):
                if devs < 10:
                    device_list.append(str(snHeader) + '0' + str(devs))
                else:
                    device_list.append(str(snHeader) + str(devs))
        elif(inp.lower() == 'm'):
            print('RUNNING REGISTER')
            register()
        elif(inp.lower() == 'd'):
            print('RUNNING DIAGNOSIS')
            diagnosis()
        elif(inp.lower() == 'r'):
            print('RUNNING REGPOINT')
            regulation()
        elif(inp.lower() == 'rd'):
            print("RUNNING REGDONE")
            reg_done()
        elif(inp.lower() == 'dg'):
            print('RUNNING DIAGNOSIS_CH4')
            diagnosis_gas()
        elif(inp.lower() == 'dc'):
            print('RUNNING DIAGNOSIS_CO')
            diagnosis_co()
        elif(inp.lower() == 'eu'):
            print('RUNNING ESP_UPDATE')
            esp_update()
        elif(inp.lower() == 'nt'):
            set_sleep_time(int(input('insert new time: \n')))


if _name_ == '_main_':

    client = mqtt.Client()

    client.username_pw_set(username, password)
    client.tls_set(ca_certs=ca_cert_route, tls_version=ssl.PROTOCOL_TLS)

    client.on_connect = on_connect
    client.on_message = on_message

    # Conectar al broker
    client.connect(host=broker, port=port, keepalive=60)
    client.loop_start()

    while(True):
        my_loop()