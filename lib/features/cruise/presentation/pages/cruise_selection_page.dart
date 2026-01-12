import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/services/cruise_api_service.dart';
import '../providers/cruise_provider.dart';

/// Page for selecting a cruise from API or entering manually
class CruiseSelectionPage extends ConsumerStatefulWidget {
  const CruiseSelectionPage({super.key});

  @override
  ConsumerState<CruiseSelectionPage> createState() => _CruiseSelectionPageState();
}

class _CruiseSelectionPageState extends ConsumerState<CruiseSelectionPage> {
  int _currentStep = 0;
  PortDto? _selectedPort;
  DateTime? _startDate;
  DateTime? _endDate;
  CruiseSearchResultDto? _selectedCruise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Cruise'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: _buildControls,
        steps: [
          _buildPortStep(),
          _buildDateStep(),
          _buildCruiseStep(),
        ],
      ),
    );
  }

  Step _buildPortStep() {
    final portsAsync = ref.watch(departurePortsProvider);
    return Step(
      title: const Text('Departure Port'),
      subtitle: _selectedPort != null ? Text(_selectedPort!.name) : null,
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: portsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildManualEntryPrompt('Could not load ports'),
        data: (ports) {
          if (ports.isEmpty) {
            return _buildManualEntryPrompt('No ports available');
          }
          return Column(
            children: [
              DropdownButtonFormField<PortDto>(
                value: _selectedPort,
                decoration: const InputDecoration(
                  labelText: 'Select departure port',
                  border: OutlineInputBorder(),
                ),
                items: ports.map((port) {
                  return DropdownMenuItem(
                    value: port,
                    child: Text(port.name),
                  );
                }).toList(),
                onChanged: (port) => setState(() => _selectedPort = port),
              ),
            ],
          );
        },
      ),
    );
  }

  Step _buildDateStep() {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Step(
      title: const Text('Travel Dates'),
      subtitle: _startDate != null
          ? Text('${dateFormat.format(_startDate!)} - ${_endDate != null ? dateFormat.format(_endDate!) : "..."}')
          : null,
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          ListTile(
            title: Text(_startDate != null ? dateFormat.format(_startDate!) : 'Select start date'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(isStart: true),
          ),
          ListTile(
            title: Text(_endDate != null ? dateFormat.format(_endDate!) : 'Select end date'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(isStart: false),
          ),
        ],
      ),
    );
  }

  Step _buildCruiseStep() {
    final resultsAsync = ref.watch(cruiseSearchResultsProvider);
    return Step(
      title: const Text('Select Cruise'),
      subtitle: _selectedCruise != null ? Text(_selectedCruise!.shipName) : null,
      isActive: _currentStep >= 2,
      state: _selectedCruise != null ? StepState.complete : StepState.indexed,
      content: resultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildManualEntryPrompt('Could not search cruises'),
        data: (cruises) {
          if (cruises.isEmpty) {
            return _buildManualEntryPrompt('No cruises found for selected dates');
          }
          return Column(
            children: cruises.map((cruise) {
              final isSelected = _selectedCruise?.id == cruise.id;
              return Card(
                color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                child: ListTile(
                  title: Text(cruise.shipName),
                  subtitle: Text('${cruise.cruiseLine} • ${cruise.durationNights} nights'),
                  trailing: Text(DateFormat('MMM d').format(cruise.startDate)),
                  selected: isSelected,
                  onTap: () => setState(() => _selectedCruise = cruise),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildManualEntryPrompt(String message) {
    return Column(
      children: [
        Text(message),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _goToManualEntry,
          icon: const Icon(Icons.edit),
          label: const Text('Enter manually'),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: details.onStepCancel,
              child: const Text('Back'),
            ),
          const Spacer(),
          FilledButton(
            onPressed: _canContinue() ? details.onStepContinue : null,
            child: Text(_currentStep == 2 ? 'Confirm' : 'Next'),
          ),
        ],
      ),
    );
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _selectedPort != null;
      case 1:
        return _startDate != null;
      case 2:
        return _selectedCruise != null;
      default:
        return false;
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0 && _selectedPort != null) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // Update search params and move to cruise selection
      ref.read(cruiseSearchParamsProvider.notifier).state = CruiseSearchParams(
        departurePortId: _selectedPort?.id,
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2 && _selectedCruise != null) {
      _confirmSelection();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
      firstDate: isStart ? now : (_startDate ?? now),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _confirmSelection() {
    if (_selectedCruise == null) return;

    final cruise = _selectedCruise!.toCruise();
    ref.read(cruiseNotifierProvider.notifier).saveCruise(cruise);
    ref.read(cruiseNotifierProvider.notifier).setActiveCruise(cruise);

    Navigator.of(context).pop(cruise);
  }

  void _goToManualEntry() {
    // TODO: Navigate to manual cruise entry page
    Navigator.of(context).pushReplacementNamed('/cruise/manual');
  }
}

