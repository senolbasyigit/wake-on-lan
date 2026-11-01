# wake-on-lan

Small Wake-on-LAN app for Android and Windows, built with Flutter. Save your machines once, wake them with one tap.

## Features

- Save devices with a name, MAC address and broadcast address
- Sends a standard magic packet over UDP
- Works on Android and Windows

## Setup

```
flutter pub get
flutter run
```

Releases:

```
flutter build apk --release
flutter build windows --release
```

## Target machine setup

The app only sends the packet. The machine you want to wake has to be configured for it:

- Enable Wake-on-LAN in the BIOS/UEFI (on ASUS boards: Power On By PCI-E, and ErP Ready disabled)
- Enable magic packet wake in the network adapter settings
- Turn off Fast Startup in Windows
- Connect it with an Ethernet cable; Wi-Fi usually doesn't work

The sending device must be on the same network. If the default broadcast address (`255.255.255.255`) doesn't work, set your subnet's broadcast address (for example `192.168.0.255`) when adding the device.

## License

MIT
