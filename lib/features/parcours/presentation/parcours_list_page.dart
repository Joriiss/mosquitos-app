import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../map/presentation/map_page.dart';
import 'new_cartography_page.dart';
import '../domain/parcours.dart';
import '../../../services/api_service.dart';

class ParcoursListPage extends StatefulWidget {
  const ParcoursListPage({super.key});

  @override
  State<ParcoursListPage> createState() => _ParcoursListPageState();
}

class _ParcoursListPageState extends State<ParcoursListPage> {
  List<Parcours> parcoursList = [];
  bool loading = true;

  final Set<String> _selectedParcoursIds = <String>{};
  bool get _selectionMode => _selectedParcoursIds.isNotEmpty;

  void _toggleSelected(String parcoursId) {
    setState(() {
      if (_selectedParcoursIds.contains(parcoursId)) {
        _selectedParcoursIds.remove(parcoursId);
      } else {
        _selectedParcoursIds.add(parcoursId);
      }
    });
  }

  Future<void> _deleteSelectedParcours() async {
    if (_selectedParcoursIds.isEmpty) return;

    final count = _selectedParcoursIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer les cartographies ?'),
          content: Text(
            'Cette action supprimera $count cartographie${count > 1 ? "s" : ""} et les données associées.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final ids = _selectedParcoursIds.toList();
    setState(() => loading = true);
    try {
      for (final id in ids) {
        await ApiService.deleteParcours(id);
      }
      _selectedParcoursIds.clear();
      await loadParcours();
    } catch (_) {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadParcours();
  }

  Future<void> loadParcours() async {
    try {
      final data = await ApiService.getParcours();

      setState(() {
        parcoursList = data.map((e) => Parcours.fromJson(e)).toList();
        loading = false;
      });
    } catch (_) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: _selectionMode
            ? [
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete, color: AppColors.accentRed),
                  onPressed: _deleteSelectedParcours,
                ),
              ]
            : null,
        title: const Text(
          'Vos cartographies existantes',
          style: TextStyle(
            fontFamily: 'Gabarito',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
        centerTitle: false,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemBuilder: (context, index) {
                      final parcours = parcoursList[index];
                      return _ParcoursCard(
                        parcours: parcours,
                        isSelected: _selectedParcoursIds.contains(parcours.id),
                        onTap: () {
                          if (_selectionMode) {
                            _toggleSelected(parcours.id);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MapPage(
                                  parcoursId: parcours.id,
                                ),
                              ),
                            );
                          }
                        },
                        onLongPress: () => _toggleSelected(parcours.id),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: parcoursList.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final controller = TextEditingController();

                        final name = await showDialog<String>(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return Dialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Nouvelle cartographie',
                                      style: TextStyle(
                                        fontFamily: 'Gabarito',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: controller,
                                      autofocus: true,
                                      style: const TextStyle(
                                        fontFamily: 'Gabarito',
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Nom de la cartographie',
                                        labelText: 'Nom de la cartographie',
                                        labelStyle: const TextStyle(
                                          fontFamily: 'Gabarito',
                                          fontSize: 14,
                                          color: AppColors.textGrey,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: AppColors.primaryBlue,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(null),
                                          child: const Text(
                                            'Annuler',
                                            style: TextStyle(
                                              fontFamily: 'Gabarito',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textGrey,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryBlue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                          ),
                                          onPressed: () {
                                            final text = controller.text.trim();
                                            if (text.isEmpty) return;
                                            Navigator.of(context).pop(text);
                                          },
                                          child: const Text(
                                            'Créer la cartographie',
                                            style: TextStyle(
                                              fontFamily: 'Gabarito',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );

                        if (name == null || name.trim().isEmpty) return;

                        final created = await ApiService.createParcours(name);
                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NewCartographyPage(
                              name: created['name'],
                              parcoursId: created['id'].toString(),
                            ),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Nouvelle cartographie',
                            style: TextStyle(
                              fontFamily: 'Gabarito',
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Image(
                            image: AssetImage('assets/icons/plus-icon.png'),
                            height: 22,
                            width: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ParcoursCard extends StatelessWidget {
  final Parcours parcours;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ParcoursCard({
    required this.parcours,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final treated = parcours.treatedPoints;
    final total = parcours.totalPoints;
    final progress = total == 0 ? 0.0 : treated / total;

    return Ink(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.accentRed
              : AppColors.primaryBlue.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parcours.name,
                    style: const TextStyle(
                      fontFamily: 'Gabarito',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Créé le ${_formatDate(parcours.createdAt)}',
                    style: const TextStyle(
                      fontFamily: 'Gabarito',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (parcours.distanceKm != null) ...[
                        const Icon(Icons.route,
                            size: 16, color: AppColors.primaryBlue),
                        const SizedBox(width: 4),
                        Text(
                          '${parcours.distanceKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontFamily: 'Gabarito',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Duration hidden here (requested).
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                AppColors.primaryBlue.withOpacity(0.08),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accentRed,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$treated / $total',
                        style: const TextStyle(
                          fontFamily: 'Gabarito',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = (date.year % 100).toString().padLeft(2, '0');
  return '$d/$m/$y';
}
