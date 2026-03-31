import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../map/presentation/map_page.dart';
import '../data/dummy_parcours.dart';
import '../domain/parcours.dart';

class ParcoursListPage extends StatelessWidget {
  const ParcoursListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
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
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemBuilder: (context, index) {
                final parcours = dummyParcoursList[index];
                return _ParcoursCard(parcours: parcours);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: dummyParcoursList.length,
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
                onPressed: () {
                  // Plus tard : navigation vers la création de cartographie
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

  const _ParcoursCard({required this.parcours});

  @override
  Widget build(BuildContext context) {
    final treated = parcours.treatedPoints;
    final total = parcours.totalPoints;
    final progress = total == 0 ? 0.0 : treated / total;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MapPage(),
          ),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
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
                  const Icon(Icons.route, size: 16, color: AppColors.primaryBlue),
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
                if (parcours.durationMin != null) ...[
                  const Icon(Icons.access_time, size: 16, color: AppColors.primaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    '${parcours.durationMin} min',
                    style: const TextStyle(
                      fontFamily: 'Gabarito',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
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
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
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
    );
  }
}

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = (date.year % 100).toString().padLeft(2, '0');
  return '$d/$m/$y';
}


