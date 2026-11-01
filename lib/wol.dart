import 'dart:io';
import 'dart:typed_data';

Uint8List buildMagicPacket(String mac) {
  final bytes = mac
      .split(RegExp(r'[:-]'))
      .map((h) => int.parse(h, radix: 16))
      .toList();

  if (bytes.length != 6) {
    throw FormatException('Invalid MAC address', mac);
  }

  return Uint8List.fromList([
    ...List.filled(6, 0xFF),
    for (var i = 0; i < 16; i++) ...bytes,
  ]);
}

Future<void> sendMagicPacket(
  String mac, {
  String broadcast = '255.255.255.255',
  int port = 9,
}) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  try {
    socket.broadcastEnabled = true;
    socket.send(buildMagicPacket(mac), InternetAddress(broadcast), port);
  } finally {
    socket.close();
  }
}