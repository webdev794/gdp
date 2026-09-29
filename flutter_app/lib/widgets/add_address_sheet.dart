import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/address_model.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class AddAddressSheet extends StatefulWidget {
  final String initialAddressLine;
  final String city;
  final String state;
  final String zipCode;
  final double latitude;
  final double longitude;
  final Function(AddressModel) onAddressSaved;

  const AddAddressSheet({
    super.key,
    required this.initialAddressLine,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
    required this.onAddressSaved,
  });

  @override
  State<AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _flatNoController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  String _selectedTag = 'Home'; // 'Home', 'Work', 'Other'

  @override
  void dispose() {
    _flatNoController.dispose();
    _floorController.dispose();
    _buildingController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _submitSaveAddress() {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.heavyImpact();

    String flatText = _flatNoController.text.trim();
    String floorText = _floorController.text.trim();
    String buildingText = _buildingController.text.trim();
    String landmarkText = _landmarkController.text.trim();

    String fullFlatInfo = flatText;
    if (floorText.isNotEmpty) {
      fullFlatInfo += ' ($floorText)';
    }

    String labelTitle = buildingText.isNotEmpty ? buildingText : widget.initialAddressLine.split(',').first.trim();

    AddressModel newAddress = AddressModel(
      id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
      label: labelTitle,
      fullAddress: widget.initialAddressLine,
      city: widget.city,
      state: widget.state,
      zipCode: widget.zipCode,
      latitude: widget.latitude,
      longitude: widget.longitude,
      flatNo: fullFlatInfo,
      floor: floorText,
      buildingName: buildingText,
      landmark: landmarkText,
      tag: _selectedTag,
    );

    LocationService.addAddress(newAddress);
    widget.onAddressSaved(newAddress);
    Navigator.pop(context); // Close sheet
  }

  @override
  Widget build(BuildContext context) {
    double distKm = LocationService.calculateDistanceKm(
      widget.latitude,
      widget.longitude,
      LocationService.storeLat,
      LocationService.storeLng,
    );
    bool isDeliverable = LocationService.isDeliverable(distKm);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Header Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(Icons.maps_home_work, color: AppTheme.emeraldPrimary, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Enter Complete Address Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // Location Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.sageLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.emeraldPrimary.withAlpha(76)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.emeraldPrimary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialAddressLine,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.slateDark),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${distKm.toStringAsFixed(1)} KM from store • ${isDeliverable ? '⚡ Deliverable' : '🚫 Out of service zone'}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Save Address Tag Selector (Home 🏠, Work 💼, Other 📍)
              const Text(
                'Save Address As',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slateDark),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildTagChip('Home', '🏠 Home'),
                  _buildTagChip('Work', '💼 Work'),
                  _buildTagChip('Other', '📍 Other'),
                ],
              ),
              const SizedBox(height: 16),

              // Flat / House No & Floor Input
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _flatNoController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      decoration: const InputDecoration(
                        labelText: 'House / Flat No. *',
                        hintText: 'e.g. Flat 402, House 12',
                        prefixIcon: Icon(Icons.home_outlined, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _floorController,
                      decoration: const InputDecoration(
                        labelText: 'Floor (Opt.)',
                        hintText: 'e.g. 4th Floor',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Building / Apartment / Society Name Input
              TextFormField(
                controller: _buildingController,
                decoration: const InputDecoration(
                  labelText: 'Building / Apartment / Society Name (Opt.)',
                  hintText: 'e.g. Parsvnath Greens, Tower B',
                  prefixIcon: Icon(Icons.business_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 12),

              // Landmark & Delivery Instructions
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(
                  labelText: 'Nearby Landmark / Delivery Note (Opt.)',
                  hintText: 'e.g. Opp. City Park / Leave at Gate',
                  prefixIcon: Icon(Icons.explore_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 20),

              // Save Address Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitSaveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDeliverable ? AppTheme.emeraldPrimary : AppTheme.errorRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isDeliverable ? 'SAVE & CONFIRM ADDRESS ➔' : 'SAVE ADDRESS (outside delivery area)',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(String tagValue, String labelText) {
    bool isSelected = _selectedTag == tagValue;
    return ChoiceChip(
      label: Text(labelText),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          HapticFeedback.selectionClick();
          setState(() => _selectedTag = tagValue);
        }
      },
      selectedColor: AppTheme.sageLight,
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: isSelected ? AppTheme.emeraldPrimary : Colors.transparent,
        width: 1.5,
      ),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
        color: isSelected ? AppTheme.emeraldPrimary : AppTheme.slateDark,
        fontSize: 12.5,
      ),
    );
  }
}
