import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/widgets/feedback/state_widgets.dart';
import '../../../core/widgets/feedback/status_chip.dart';

class AdminResourcesScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const AdminResourcesScreen({super.key, this.onNavigateToTab});

  @override
  State<AdminResourcesScreen> createState() => _AdminResourcesScreenState();
}

class _AdminResourcesScreenState extends State<AdminResourcesScreen> {
  void _showAddResourceDialog(BuildContext context, MockRepository repo) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final quantityCtrl = TextEditingController(text: '10');
    final unitCtrl = TextEditingController(text: 'units');
    String selectedCategory = 'Medical';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Add Inventory Resource', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Medical', child: Text('Medical Equipment')),
                        DropdownMenuItem(value: 'Fire & Rescue', child: Text('Fire & Rescue Gear')),
                        DropdownMenuItem(value: 'Fuel', child: Text('Fuel Reserves')),
                        DropdownMenuItem(value: 'Personnel', child: Text('Emergency Personnel')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Resource Name',
                        hintText: 'e.g. Oxygen Cylinder 10L',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter resource name' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: quantityCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Initial Quantity',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter valid number' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: unitCtrl,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              hintText: 'e.g. cylinders, liters',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    repo.addResource(
                      name: nameCtrl.text.trim(),
                      category: selectedCategory,
                      quantity: int.parse(quantityCtrl.text.trim()),
                      unit: unitCtrl.text.trim(),
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.statusCompleted,
                        content: Text('Added ${nameCtrl.text.trim()} to resource pool.'),
                      ),
                    );
                  },
                  child: const Text('Add Resource'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = context.watch<MockRepository>();
    final resources = repo.resources;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Resource'),
        onPressed: () => _showAddResourceDialog(context, repo),
      ),
      body: resources.isEmpty
          ? const Center(
              child: EmptyState(
                'No Resources Logged',
                subtitle: 'Add equipment, fuel reserves, or crew assignments to manage inventory.',
                icon: Icons.inventory_2_outlined,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: resources.length,
              itemBuilder: (context, index) {
                final item = resources[index];
                final isAvailable = item.status == 'Available';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isAvailable ? AppColors.primaryTeal : Colors.red).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.category.contains('Medical')
                                ? Icons.medical_services_rounded
                                : item.category.contains('Fire')
                                    ? Icons.fire_extinguisher_rounded
                                    : item.category.contains('Fuel')
                                        ? Icons.local_gas_station_rounded
                                        : Icons.group_rounded,
                            color: isAvailable ? AppColors.primaryTeal : Colors.red,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusChip(status: item.status.toUpperCase()),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.category} · In Stock: ${item.quantity} ${item.unit}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Quick Adjust Quantity Buttons
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                              tooltip: 'Decrement',
                              onPressed: item.quantity > 0
                                  ? () => repo.updateResourceQuantity(item.id, item.quantity - 1)
                                  : null,
                            ),
                            Text(
                              '${item.quantity}',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: AppColors.primaryTeal),
                              tooltip: 'Increment',
                              onPressed: () => repo.updateResourceQuantity(item.id, item.quantity + 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
