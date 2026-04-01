import 'package:flutter/material.dart';
import 'package:mosquitos_app/models/point_model.dart';
import 'package:mosquitos_app/models/intervention_model.dart';
import 'package:mosquitos_app/theme/app_colors.dart';

class PointHistoryDialog extends StatelessWidget {
  final Point point;
  final List<Intervention> interventions;

  const PointHistoryDialog({
    super.key,
    required this.point,
    required this.interventions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Historique de ${point.name}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold ,color: AppColors.primaryBlue),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.primaryBlue),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...interventions.map((i) => _item(i)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(Intervention i) {
    final date = "${i.performedAt.day.toString().padLeft(2, '0')}/"
        "${i.performedAt.month.toString().padLeft(2, '0')}/"
        "${i.performedAt.year}";

    String title;
    switch (i.interventionType) {
      case 'treated':
        title = 'Traité le $date';
        break;
      case 'added':
        title = 'Ajouté le $date';
        break;
      default:
        title = '${i.interventionType} le $date';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
          if (i.performedBy != null) Text("Par ${i.performedBy}"),
          const SizedBox(height: 6),
          if (i.comment.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(i.comment, style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
