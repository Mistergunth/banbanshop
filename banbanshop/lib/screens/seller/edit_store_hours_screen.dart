// lib/screens/seller/edit_store_hours_screen.dart

import 'package:flutter/material.dart';

class EditStoreHoursScreen extends StatefulWidget {
  final Map<String, dynamic> initialHours;

  const EditStoreHoursScreen({super.key, required this.initialHours});

  @override
  State<EditStoreHoursScreen> createState() => _EditStoreHoursScreenState();
}

class _EditStoreHoursScreenState extends State<EditStoreHoursScreen> {
  late Map<String, dynamic> _operatingHours;

  final List<Map<String, String>> _days = [
    {'key': 'mon', 'name': 'วันจันทร์'},
    {'key': 'tue', 'name': 'วันอังคาร'},
    {'key': 'wed', 'name': 'วันพุธ'},
    {'key': 'thu', 'name': 'วันพฤหัสบดี'},
    {'key': 'fri', 'name': 'วันศุกร์'},
    {'key': 'sat', 'name': 'วันเสาร์'},
    {'key': 'sun', 'name': 'วันอาทิตย์'},
  ];

  @override
  void initState() {
    super.initState();
    _operatingHours = Map<String, dynamic>.from(
      widget.initialHours.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, String dayKey, String type) async {
    final String currentTimeStr = _operatingHours[dayKey][type];
    final parts = currentTimeStr.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _operatingHours[dayKey][type] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าเวลาเปิด-ปิด'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF21CBF3)], // Blue to Dark Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white, // White text/icons
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context, _operatingHours);
            },
            color: Colors.white, // White icon
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final dayKey = day['key']!;
          final dayName = day['name']!;
          final schedule = _operatingHours[dayKey]!;
          final bool isOpen = schedule['isOpen'];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 3, // Added elevation
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // Darker text
                      Switch(
                        value: isOpen,
                        onChanged: (value) {
                          setState(() {
                            schedule['isOpen'] = value;
                          });
                        },
                        activeColor: const Color(0xFF0288D1), // Blue active color
                      ),
                    ],
                  ),
                  if (isOpen)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTimePickerButton(context, 'เวลาเปิด', schedule['opens'], () => _selectTime(context, dayKey, 'opens')),
                          const Text('-', style: TextStyle(fontSize: 20, color: Colors.grey)), // Grey text
                          _buildTimePickerButton(context, 'เวลาปิด', schedule['closes'], () => _selectTime(context, dayKey, 'closes')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePickerButton(BuildContext context, String label, String time, VoidCallback onPressed) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey[200], // Light grey background
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            time,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Black text
          ),
        ),
      ],
    );
  }
}
