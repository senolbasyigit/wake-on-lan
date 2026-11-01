import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device.dart';
import 'wol.dart';

void main() => runApp(const WolApp());

class WolApp extends StatelessWidget {
  const WolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wake on LAN',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const DeviceListPage(),
    );
  }
}

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  static const _storageKey = 'devices';

  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && mounted) {
      setState(() => _devices = decodeDevices(raw));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, encodeDevices(_devices));
  }

  Future<void> _wake(Device device) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await sendMagicPacket(device.mac, broadcast: device.broadcast);
      messenger.showSnackBar(
        SnackBar(content: Text('Packet sent to ${device.name}')),
      );
    } on FormatException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Invalid MAC address')),
      );
    } on SocketException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not send packet')),
      );
    }
  }

  Future<void> _add() async {
    final device = await showDialog<Device>(
      context: context,
      builder: (_) => const _AddDeviceDialog(),
    );
    if (device == null) return;
    setState(() => _devices = [..._devices, device]);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wake on LAN')),
      body: _devices.isEmpty
          ? const Center(child: Text('No devices yet'))
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, i) {
                final device = _devices[i];
                return Dismissible(
                  key: ValueKey('${device.mac}-$i'),
                  background: Container(color: Colors.red),
                  onDismissed: (_) {
                    setState(() => _devices.removeAt(i));
                    _save();
                  },
                  child: ListTile(
                    title: Text(device.name),
                    subtitle: Text(device.mac),
                    trailing: IconButton(
                      icon: const Icon(Icons.power_settings_new),
                      onPressed: () => _wake(device),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddDeviceDialog extends StatefulWidget {
  const _AddDeviceDialog();

  @override
  State<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<_AddDeviceDialog> {
  final _broadcast = TextEditingController(text: defaultBroadcast);
  final _name = TextEditingController();
  final _mac = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _mac.dispose();
    _broadcast.dispose();
    super.dispose();
  }

  void _submit() {
  final name = _name.text.trim();
  final mac = _mac.text.trim();
  final broadcast = _broadcast.text.trim();

  if (name.isEmpty) {
    setState(() => _error = 'Enter a name');
    return;
  }
  try {
    buildMagicPacket(mac);
  } on FormatException {
    setState(() => _error = 'Invalid MAC address');
    return;
  }
  if (InternetAddress.tryParse(broadcast) == null) {
    setState(() => _error = 'Invalid broadcast address');
    return;
  }
  Navigator.pop(
    context,
    Device(name: name, mac: mac, broadcast: broadcast),
  );
}

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add device'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _mac,
            decoration: const InputDecoration(
              labelText: 'MAC address',
              hintText: 'AA:BB:CC:DD:EE:FF',
            ),
          ),
          TextField(
            controller: _broadcast,
            decoration: const InputDecoration(labelText: 'Broadcast address'),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}