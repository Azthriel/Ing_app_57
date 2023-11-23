import requests
from requests.exceptions import ConnectionError
from requests.exceptions import Timeout

nickname = ""
snHeader = 0
initialnumber = 0
finalnumber = 0
newDevices = True

attempts_number = 10

device_list = []
reg_device_list = []

def register():

    milista = []  # to gs

    for devs in range(len(device_list)):
        print("LOADING DEVICE: " + str(device_list[devs]))
        milista.append(device_list[devs])

def diagnosis_v2():
    
    milista = []  # to gs
    
    for devs in range(len(device_list)):

        url = 'http://RB_IOT_' + str(device_list[devs]) + ':8080/DIAGNOSIS_OK'
        print(url)

        ############

        for attempts in range(attempts_number):

            print('attempt (' + str(attempts + 1) + '): ', end='')

            try:
                response = requests.get(
                    url=url, allow_redirects=False, timeout=3)
            except ConnectionError:
                print('fail')

                if(attempts == int(attempts_number) - 1): # last attempt
                    milista.append('CONNECTION_ERROR')
            except Timeout:
                print('fail')
                if(attempts == int(attempts_number) - 1): # last attempt
                    milista.append('CONNECTION_TIMED_OUT')
            else:
                if response.status_code == 200:
                    if str(response.content.strip()).find('DIAGNOSIS_OK') != -1:
                        ##
                        sv = str(response.content)
                        sv = sv[sv.find('(') + 1: sv.find(')')]
                        ##
                        print('success -> sv: ' + sv)
                        milista.append('OK -> sv: ' + sv)
                        break
                    else:
                        print('fail')
                        if(attempts == int(attempts_number) - 1): # last attempt
                            milista.append('WRONG_RESPONSE')
                else:
                    print('fail')
                    if(attempts == int(attempts_number) - 1): # last attempt
                        milista.append('WRONG_STATUS_CODE')

    print('\n\nDIAGNOSIS -------------------------------------------------\n')
    for devs in range(len(device_list)):
        print(device_list[devs] + '  ->  ' + milista[devs])
    print('\nDEVICE NUMBER: ----------------- ' + str(len(device_list)) + '\n')
    print('-----------------------------------------------------------\n\n')

def diagnosis_ch4_v2():
    milista = []  # to gs
    
    for devs in range(len(device_list)):

        url = 'http://RB_IOT_' + str(device_list[devs]) + ':8080/DIAGNOSIS_CH4'
        print(url)

        ############

        for attempts in range(attempts_number):

            print('attempt (' + str(attempts + 1) + '): ', end='')

            try:
                response = requests.get(
                    url=url, allow_redirects=False, timeout=3)
            except ConnectionError:
                print('fail')

                if(attempts == int(attempts_number) - 1): # last attempt
                    milista.append('CONNECTION_ERROR')
            except Timeout:
                print('fail')
                if(attempts == int(attempts_number) - 1): # last attempt
                    milista.append('CONNECTION_TIMED_OUT')
            else:
                if response.status_code == 200:
                    if str(response.content.strip()).find('DIAGNOSIS_CH4') != -1:
                        
                        ##
                        payload = str(response.content)
                        encoded = str(
                            payload[payload.find('(') + 1: payload.find(')')])

                        low, high = map(int, encoded.split(":"))
                        ppmch4max = (high << 8) | low

                        print('success -> ppmch4max: ' + str(ppmch4max))
                        ##
                        
                        milista.append('OK -> ppmch4max: ' + str(ppmch4max))
                        break
                    else:
                        print('fail')
                        if(attempts == int(attempts_number) - 1): # last attempt
                            milista.append('WRONG_RESPONSE')
                else:
                    print('fail')
                    if(attempts == int(attempts_number) - 1): # last attempt
                        milista.append('WRONG_STATUS_CODE')

    print('\n\nDIAGNOSIS_CH4 -------------------------------------------------\n')
    for devs in range(len(device_list)):
        print(device_list[devs] + '  ->  ' + milista[devs])
    print('\nDEVICE NUMBER: ----------------- ' + str(len(device_list)) + '\n')
    print('-----------------------------------------------------------\n\n')

def diagnosis_co_v2():

    milista = []  # to gs
    
    for devs in range(len(device_list)):

        url = 'http://RB_IOT_' + str(device_list[devs]) + ':8080/DIAGNOSIS_CO'
        print(url)

        ############

        for attempts in range(attempts_number):

            print('attempt (' + str(attempts + 1) + '): ', end='')

            try:
                response = requests.get(
                    url=url, allow_redirects=False, timeout=3)
            except ConnectionError:
                print('fail')

                if(attempts == int(attempts_number) - 1): # last attempt
                    milista.append('CONNECTION_ERROR')
            except Timeout:
                print('fail')
                if(attempts == int(attempts_number) - 1): # last attempt
                    milista.append('CONNECTION_TIMED_OUT')
            else:
                if response.status_code == 200:
                    if str(response.content.strip()).find('DIAGNOSIS_CO') != -1:
                        
                        ##
                        payload = str(response.content)
                        encoded = str(
                            payload[payload.find('(') + 1: payload.find(')')])

                        low, high = map(int, encoded.split(":"))
                        ppmcomax = (high << 8) | low

                        print('success -> ppmcomax: ' + str(ppmcomax))
                        ##
                        
                        milista.append('OK -> ppmcomax: ' + str(ppmcomax))
                        break
                    else:
                        print('fail')
                        if(attempts == int(attempts_number) - 1): # last attempt
                            milista.append('WRONG_RESPONSE')
                else:
                    print('fail')
                    if(attempts == int(attempts_number) - 1): # last attempt
                        milista.append('WRONG_STATUS_CODE')

    print('\n\nDIAGNOSIS_CO -------------------------------------------------\n')
    for devs in range(len(device_list)):
        print(device_list[devs] + '  ->  ' + milista[devs])
    print('\nDEVICE NUMBER: ----------------- ' + str(len(device_list)) + '\n')
    print('-----------------------------------------------------------\n\n')

def regulation_v2():

    regp = int(input("Enter the regulation point: "))
    temp = int(input("Enter the regulation bank temperature: "))

    milista = []  # to gs
    
    for devs in range(len(device_list)):

        url = 'http://RB_IOT_' + str(device_list[devs]) + ':8080/REGP_' + str(regp) + '_(' + str(temp) + ')'
        print(url)

        ############

        for attempts in range(attempts_number):

            print('attempt (' + str(attempts + 1) + '): ', end='')

            try:
                response = requests.get(
                    url=url, allow_redirects=False, timeout=3)
            except ConnectionError:
                print('fail')

                if(attempts == int(attempts_number) - 1): # last attempt
                    milista.append('CONNECTION_ERROR')
            except Timeout:
                print('fail')
                if(attempts == int(attempts_number) - 1): # last attempt
                    milista.append('CONNECTION_TIMED_OUT')
            else:
                if response.status_code == 200:
                    if str(response.content.strip()).find('PAYLOAD') != -1:
                        payload = str(response.content)

                        start = payload.find('PAYLOAD(') + 8
                        end = payload.find(')', start)

                        payload = payload[start:end].split(':')
                        
                        encoded_list = [int(num) for num in payload]

                        #
                        ectemp = encoded_list[0]
                        rs = encoded_list[1]
                        #

                        print('success -> ectemp(' + str(ectemp) + ')' + '  ---  rs -> (' + str(rs) + ')')
                        milista.append('OK -> ectemp(' + str(ectemp) + ')' + '  ---  rs -> (' + str(rs) + ')')
                        break
                    else:
                        print('fail')
                        if(attempts == int(attempts_number) - 1): # last attempt
                            milista.append('WRONG_RESPONSE')
                else:
                    print('fail')
                    if(attempts == int(attempts_number) - 1): # last attempt
                        milista.append('WRONG_STATUS_CODE')

    print('\n\REGP (' + str(regp) + ') -------------------------------------------------\n')
    for devs in range(len(device_list)):
        print(device_list[devs] + '  ->  ' + milista[devs])
    print('\nDEVICE NUMBER: ----------------- ' + str(len(device_list)) + '\n')
    print('-----------------------------------------------------------\n\n')

def reg_done():
    milista = []  # to gs
    
    for devs in range(len(device_list)):

        url = 'http://RB_IOT_' + str(device_list[devs]) + ':8080/REG_DONE'
        print(url)

        ############

        for attempts in range(attempts_number):

            print('attempt (' + str(attempts + 1) + '): ', end='')

            try:
                response = requests.get(
                    url=url, allow_redirects=False, timeout=3)
            except ConnectionError:
                print('fail')

                if(attempts == int(attempts_number) - 1): # last attempt
                    milista.append('CONNECTION_ERROR')
            except Timeout:
                print('fail')
                if(attempts == int(attempts_number) - 1): # last attempt
                    milista.append('CONNECTION_TIMED_OUT')
            else:
                if response.status_code == 200:
                    if str(response.content.strip()).find('REG_DONE_OK') != -1:

                        print('success')
                        milista.append('OK')
                        break
                    else:
                        print('fail')
                        if(attempts == int(attempts_number) - 1): # last attempt
                            milista.append('WRONG_RESPONSE')
                else:
                    print('fail')
                    if(attempts == int(attempts_number) - 1): # last attempt
                        milista.append('WRONG_STATUS_CODE')

    print('\n\REG_DONE -------------------------------------------------\n')
    for devs in range(len(device_list)):
        print(device_list[devs] + '  ->  ' + milista[devs])
    print('\nDEVICE NUMBER: ----------------- ' + str(len(device_list)) + '\n')
    print('-----------------------------------------------------------\n\n')

def pic_update():
    milista = []  # to gs

    for devs in range(len(device_list)):

        url = 'http://RB_IOT_' + \
            str(device_list[devs]) + \
            ':8080/PIC_UPDATE(https://github.com/CrisDores/57_IOT_PUBLIC/raw/main/57_ota_factory_fw/firmware.hex)'

        print(url)

        retry = False

        try:
            response = requests.get(
                url=url, allow_redirects=False, timeout=3)
        except ConnectionError:
            retry = True

        except Timeout:
            retry = True
        else:
            if response.status_code == 200:
                if str(response.content.strip()).find('PIC_UPDATE_OK') != -1:
                    milista.append('OK')
                else:
                    retry = True
            else:
                retry = True

        if retry == True:

            print('retry!')

            try:
                response = requests.get(
                    url=url, allow_redirects=False, timeout=3)
            except ConnectionError:
                milista.append('CONNECTION_ERROR')

            except Timeout:
                milista.append('CONNECTION_TIMED_OUT')
            else:
                if response.status_code == 200:
                    if str(response.content.strip()).find('PIC_UPDATE_OK') != -1:
                        milista.append('OK')
                    else:
                        milista.append('WRONG_RESPONSE')
                else:
                    milista.append('WRONG_STATUS_CODE')

        #################################################################################

    # url = "https://script.google.com/macros/s/AKfycbxZuEBeomsTvrataOexpjMLqUY88kQLFl-LVM6lBudVjoKk0DT9It1c4LCh-f_F8gHyig/exec"

    # statusJson = json.dumps(milista)
    # data = {
    #     "status": statusJson,
    #     "nickname": nickname,
    # }

    # requests.get(url, params=data)

def esp_update_v2():
    
    milista = []  # to gs
    
    for devs in range(len(device_list)):

        url = 'http://RB_IOT_' + \
            str(device_list[devs]) + \
            ':8080/ESP_UPDATE(https://github.com/CrisDores/57_IOT_PUBLIC/raw/main/57_ota_factory_fw/firmware.bin)'
        print(url)

        ############

        for attempts in range(attempts_number):

            print('attempt (' + str(attempts + 1) + '): ', end='')

            try:
                response = requests.get(
                    url=url, allow_redirects=False, timeout=3)
            except ConnectionError:
                print('fail')

                if(attempts == int(attempts_number) - 1): # last attempt
                    milista.append('CONNECTION_ERROR')
            except Timeout:
                print('fail')
                if(attempts == int(attempts_number) - 1): # last attempt
                    milista.append('CONNECTION_TIMED_OUT')
            else:
                if response.status_code == 200:
                    if str(response.content.strip()).find('ESP_UPDATE_OK') != -1:
                        print('success')
                        milista.append('OK')
                        break
                    else:
                        print('fail')
                        if(attempts == int(attempts_number) - 1): # last attempt
                            milista.append('WRONG_RESPONSE')
                else:
                    print('fail')
                    if(attempts == int(attempts_number) - 1): # last attempt
                        milista.append('WRONG_STATUS_CODE')

    print('\n\nESP_UPDATE -------------------------------------------------\n')
    for devs in range(len(device_list)):
        print(device_list[devs] + '  ->  ' + milista[devs])
    print('\nDEVICE NUMBER: ----------------- ' + str(len(device_list)) + '\n')
    print('-----------------------------------------------------------\n\n')


def wipe():

    url = 'https://script.google.com/macros/s/AKfycbyLuB-1LCUuQ2AWAhCb2ZE_FVWrdObKyLWtl6SAdsxiwC-lneDk-jlPSHUhS4U2RRRq/exec'

    requests.post(url=url)


def specificWipe(column):
    url = 'https://script.google.com/macros/s/AKfycbyLuB-1LCUuQ2AWAhCb2ZE_FVWrdObKyLWtl6SAdsxiwC-lneDk-jlPSHUhS4U2RRRq/exec'

    data = {
        'column': column
    }

    requests.get(url, params=data)


if __name__ == '__main__':
    print('WELCOME')

    nickname = str(input("Please, enter a nickname: "))

    while (True):

        if newDevices == True:

            snHeader = int(input("Enter the header: "))
            initialnumber = int(input("Enter the initial value: "))
            finalnumber = int(input("Enter the final value: "))

            for devs in range(initialnumber, finalnumber + 1):
                if devs < 10:
                    device_list.append(str(snHeader) + '0' + str(devs))
                    reg_device_list.append(str(snHeader) + '0' + str(devs))
                else:
                    device_list.append(str(snHeader) + str(devs))
                    reg_device_list.append(str(snHeader) + str(devs))

            newDevices = False

        print('"M" for Register/"D" for Diagnosis/"R" for regulation')
        print('"W" for Wipe sheet/"N" for new devices/"K" for kill program')
        inp = input()

        if inp == 'M' or inp == 'm':
            print('RUNNING REGISTER')
            register()
        elif inp == 'D' or inp == 'd':
            print('RUNNING DIAGNOSIS')
            diagnosis_v2()
        elif inp == 'dg' or inp == 'DG':
            print('RUNNING GAS DIAGNOSIS')
            diagnosis_ch4_v2()
        elif inp == 'dc' or inp == 'DC':
            print('RUNNING CO DIAGNOSIS')
            diagnosis_co_v2()
        elif inp == 'pu' or inp == 'PU':
            print('RUNNING PIC UPDATE')
            pic_update()
        elif inp == 'eu' or inp == 'EU':
            print('RUNNING ESP UPDATE')
            esp_update_v2()
        elif inp == 'R' or inp == 'r':
            print('RUNNING REGULATION')
            regulation_v2()
        elif inp == 'RD' or inp == 'rd':
            reg_done()
        elif inp == 'W' or inp == 'w':
            print('WHAT COLUMN DO YOU WANNA WIPE?')
            print('"M" for Register/"D" for Diagnosis/"R" for regulation')
            print('Press anything else to wipe the entire sheet')
            ctd = input("ENTER THE COLUMN TO WIPE: ")
            if ctd == 'm' or ctd == 'M':
                print('WIPING REGISTER')
                specificWipe(1)
            elif ctd == 'd' or ctd == 'D':
                print('WIPING DIAGNOSIS')
                specificWipe(2)
            elif ctd == 'r' or ctd == 'R':
                print('Which one?')
                rp = int(input('Select the RP 1-10: '))
                print('WIPING RP' + str(rp))
                if rp == 1:
                    specificWipe(4)
                elif rp == 2:
                    specificWipe(5)
                elif rp == 3:
                    specificWipe(6)
                elif rp == 4:
                    specificWipe(7)
                elif rp == 5:
                    specificWipe(8)
                elif rp == 6:
                    specificWipe(9)
                elif rp == 7:
                    specificWipe(10)
                elif rp == 8:
                    specificWipe(11)
                elif rp == 9:
                    specificWipe(12)
                elif rp == 10:
                    specificWipe(13)
                else:
                    print('Next time. think twice...')
                    break
            else:
                print('WIPING SHEET')
                wipe()
        elif inp == 'N' or inp == 'n':
            print('HELLO AGAIN')
            newDevices = True
        elif inp == 'K' or inp == 'k':
            print('GOODBYE')
            break
        else:
            print('Wrong character, try again')
