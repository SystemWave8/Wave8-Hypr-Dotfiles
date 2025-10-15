#!/bin/bash

# Replace this with your device MAC
MAC="9C:C8:E9:04:C2:0E"

if zenity --question --title="Bluetooth" --text="Connect to desk Bluetooth?"; then
    bluetoothctl connect "$MAC"
fi
