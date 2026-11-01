import 'dart:convert';

const defaultBroadcast = '255.255.255.255';

class Device {
  const Device({
    required this.name,
    required this.mac,
    this.broadcast = defaultBroadcast,
  });

  final String name;
  final String mac;
  final String broadcast;

  Map<String, dynamic> toJson() =>
      {'name': name, 'mac': mac, 'broadcast': broadcast};

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        name: json['name'] as String,
        mac: json['mac'] as String,
        broadcast: json['broadcast'] as String? ?? defaultBroadcast,
      );
}

String encodeDevices(List<Device> devices) =>
    jsonEncode(devices.map((d) => d.toJson()).toList());

List<Device> decodeDevices(String source) => (jsonDecode(source) as List)
    .map((e) => Device.fromJson(e as Map<String, dynamic>))
    .toList();