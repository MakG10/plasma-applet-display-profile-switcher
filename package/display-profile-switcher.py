#!/usr/bin/env python

import base64
import dbus
import pickle
from pprint import pprint
import sys

def main(argv):
    try:
        action = sys.argv[1]
    except IndexError:
        action = 'save'

    bus = dbus.SessionBus()
    obj = bus.get_object('org.kde.KScreen', '/backend')

    if action == 'save':
        displaysConfig = dbus_to_python(obj.getConfig())
        config = base64.b64encode(pickle.dumps(displaysConfig)).decode().replace("\n", "")

        print(config)
    else:
        try:
            encodedConfig = sys.argv[2]
        except IndexError:
            print("Expected base64-encoded config as 2nd argument.")
            exit(1)

        displaysConfig = pickle.loads(base64.b64decode(encodedConfig))
        obj.setConfig(python_to_dbus(displaysConfig))

# Unfortunetly we need those conversions, because for some reason after pickling D-Bus complains about types (int being a dbus.Array)
# Snippet source: https://stackoverflow.com/questions/11486443/dbus-python-how-to-get-response-with-native-types
def python_to_dbus(data):
    '''
        convert python data types to dbus data types
    '''
    if isinstance(data, str):
        data = dbus.String(data)
    elif isinstance(data, bool):
        # python bools are also ints, order is important !
        data = dbus.Boolean(data)
    elif isinstance(data, int):
        data = dbus.Int64(data)
    elif isinstance(data, float):
        data = dbus.Double(data)
    elif isinstance(data, list):
        data = dbus.Array([python_to_dbus(value) for value in data], signature='v')
    elif isinstance(data, dict):
        data = dbus.Dictionary(data, signature='sv')
        for key in data.keys():
            data[key] = python_to_dbus(data[key])
    return data


def dbus_to_python(data):
    '''
        convert dbus data types to python native data types
    '''
    if isinstance(data, dbus.String):
        data = str(data)
    elif isinstance(data, dbus.Boolean):
        data = bool(data)
    elif isinstance(data, dbus.Int64):
        data = int(data)
    elif isinstance(data, dbus.Double):
        data = float(data)
    elif isinstance(data, dbus.Array):
        data = [dbus_to_python(value) for value in data]
    elif isinstance(data, dbus.Dictionary):
        new_data = dict()
        for key in data.keys():
            new_data[key] = dbus_to_python(data[key])
        data = new_data
    return data

if __name__ == "__main__":
    main(sys.argv)
    