import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../map/presentation/map_page.dart';
import 'new_cartography_page.dart';
import '../domain/parcours.dart';
import '../../../services/api_service.dart';
import '../../auth/presentation/login_page.dart';

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

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

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
      if (!mounted) return;

      final list = <Parcours>[];
      for (final e in data) {
        if (e is! Map) continue;
        list.add(Parcours.fromJson(Map<String, dynamic>.from(e)));
      }

      setState(() {
        parcoursList = list;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
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
        actions: [
          if (_selectionMode)
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete, color: AppColors.accentRed),
              onPressed: _deleteSelectedParcours,
            ),
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout, color: AppColors.primaryBlue),
            onPressed: _logout,
          ),
        ],
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
                  child: RefreshIndicator(
                    onRefresh: loadParcours,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemBuilder: (context, index) {
                        final parcours = parcoursList[index];
                        return _ParcoursCard(
                          parcours: parcours,
                          isSelected:
                              _selectedParcoursIds.contains(parcours.id),
                          onTap: () async {
                            if (_selectionMode) {
                              _toggleSelected(parcours.id);
                              return;
                            }
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => MapPage(
                                  parcoursId: parcours.id,
                                ),
                              ),
                            );
                            if (mounted) await loadParcours();
                          },
                          onLongPress: () => _toggleSelected(parcours.id),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: parcoursList.length,
                    ),
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
                        final didStop = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => NewCartographyPage(
                              name: created['name'],
                              parcoursId: created['id'].toString(),
                            ),
                          ),
                        );

                        if (!context.mounted) return;
                        if (didStop == true) {
                          await loadParcours();
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Nouvelle cartographie',
                            style: TextStyle(
                              fontFamily: 'Gabarito',
                              fontSize: 15,
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
    final resolved = parcours.resolvedCount;
    final totalPts = parcours.totalPoints;
    final progress = totalPts == 0 ? 0.0 : resolved / totalPts;
    final progressLabel = totalPts == 0 ? '—' : '$resolved / $totalPts';

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    parcours.name,
                    style: const TextStyle(
                      fontFamily: 'Gabarito',
                      fontSize: 17,
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
                  if (totalPts >= 2) ...[
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/length.png',
                          height: 18,
                          width: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _routeDistanceLabel(parcours),
                          style: const TextStyle(
                            fontFamily: 'Gabarito',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Image.asset(
                          'assets/icons/time.png',
                          height: 18,
                          width: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _routeDurationLabel(parcours),
                          style: const TextStyle(
                            fontFamily: 'Gabarito',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                        progressLabel,
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

String _routeDistanceLabel(Parcours p) {
  final km = p.distanceKm;
  if (km != null && km > 0) {
    return '${km.toStringAsFixed(1)} km';
  }
  return '—';
}

String _routeDurationLabel(Parcours p) {
  final m = p.durationMin;
  if (m != null && m > 0) {
    return '$m min';
  }
  return '—';
}
