import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/cruise.dart';
import '../providers/cruise_provider.dart';

/// Page for manually entering cruise information
class ManualCruiseEntryPage extends ConsumerStatefulWidget {
  const ManualCruiseEntryPage({super.key});

  @override
  ConsumerState<ManualCruiseEntryPage> createState() => _ManualCruiseEntryPageState();
}

class _ManualCruiseEntryPageState extends ConsumerState<ManualCruiseEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _cruiseLineController = TextEditingController();
  final _shipNameController = TextEditingController();
  final _departurePortController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _roomTypeController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _cruiseLineController.dispose();
    _shipNameController.dispose();
    _departurePortController.dispose();
    _roomNumberController.dispose();
    _roomTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Cruise Details'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Enter your cruise information manually',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _cruiseLineController,
              decoration: const InputDecoration(
                labelText: 'Cruise Line *',
                hintText: 'e.g., Royal Caribbean, Carnival',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shipNameController,
              decoration: const InputDecoration(
                labelText: 'Ship Name *',
                hintText: 'e.g., Spectrum of the Seas',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _departurePortController,
              decoration: const InputDecoration(
                labelText: 'Departure Port *',
                hintText: 'e.g., Shanghai, Miami',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildDatePickers(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roomNumberController,
              decoration: const InputDecoration(
                labelText: 'Room Number',
                hintText: 'e.g., 12102',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roomTypeController,
              decoration: const InputDecoration(
                labelText: 'Room Type',
                hintText: 'e.g., Balcony, Suite, Interior',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSaving ? null : _saveCruise,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Cruise'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickers() {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Row(
      children: [
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_startDate != null ? dateFormat.format(_startDate!) : 'Start Date *'),
            subtitle: const Text('Departure'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(isStart: true),
          ),
        ),
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_endDate != null ? dateFormat.format(_endDate!) : 'End Date *'),
            subtitle: const Text('Return'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(isStart: false),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

