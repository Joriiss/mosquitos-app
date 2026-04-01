import 'package:flutter/material.dart';
import 'package:mosquitos_app/features/point_history.dart';
import 'package:mosquitos_app/models/intervention_model.dart';
import 'package:mosquitos_app/models/point_model.dart';
import 'package:mosquitos_app/theme/app_colors.dart';


class PointModal extends StatefulWidget {
  final bool isEdit;
  final Point? point;
  final List<Intervention> interventions;

  static const List<String> fixedTags = [
    "Avaloir avec de l'eau",
    "Avaloir sans eau",
    "Avaloir encombré",
    "Trappe EDF",
  ];

  const PointModal({
    super.key,
    required this.isEdit,
    this.point,
     this.interventions = const [],
  });

  @override
  State<PointModal> createState() => _PointModalState();
}

class _PointModalState extends State<PointModal> {
  late TextEditingController nameController;
  late TextEditingController commentController;
  bool isTreated = false;
  Set<String> selectedTags = {};

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.point?.name ?? '');
    commentController = TextEditingController(text: widget.point?.comment ?? '');
    isTreated = widget.point?.isTreated ?? false;
    if (widget.point?.label.name != null) {
      selectedTags.add(widget.point!.label.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Gabarito',
              bodyColor: AppColors.primaryBlue,
              displayColor: AppColors.primaryBlue,
            ),
      ),
      child: Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 16),
                if (widget.isEdit) _photoPreview(),
                const SizedBox(height: 16),
                _nameField(),
                const SizedBox(height: 16),
                _tagsSection(),
                const SizedBox(height: 16),
                if (widget.isEdit) _dateInfo(),
                _treatedSwitch(),
                const SizedBox(height: 16),
                _commentField(),
                const SizedBox(height: 16),
                if (!widget.isEdit) _photoPicker(),
                if (widget.isEdit) _historyButton(),
                const SizedBox(height: 16),
                _submitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.isEdit ? "Point #${widget.point?.id}" : "Ajouter un point",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        )
      ],
    );
  }

  Widget _nameField() {
    return TextField(
      controller: nameController,
      enabled: !widget.isEdit,
      style: const TextStyle(color: AppColors.primaryBlue),
      decoration: InputDecoration(
        labelText: "Nom",
        labelStyle: const TextStyle(color: AppColors.primaryBlue),
        border:  OutlineInputBorder( 
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
    );
  }

  Widget _tagsSection() {
    return Wrap(
      spacing: 8,
      children: PointModal.fixedTags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return ChoiceChip(
          label: Text(tag),
          selected: isSelected,
          selectedColor: AppColors.primaryBlue,
          backgroundColor: AppColors.white,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.white : Colors.black,
            fontFamily: 'Gabarito',
          ),
          checkmarkColor: AppColors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (val) {
            setState(() {
              if (val) {
                selectedTags.add(tag);
              } else {
                selectedTags.remove(tag);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _treatedSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Point déjà traité ?", style: TextStyle(color: AppColors.primaryBlue)),
        Switch(
          value: isTreated,
          trackOutlineColor:WidgetStateProperty.resolveWith<Color>((states) {
            return AppColors.white;
          }),
          thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
            return AppColors.white;
          }),
          trackColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryBlue;
            }
            return Colors.grey.shade300;
          }),
          onChanged: (val) {
            setState(() {
              isTreated = val;
            });
          },
        ),
      ],
    );
  }

  Widget _dateInfo() {
    final date = widget.point?.lastTreatmentDate != null
        ? "${widget.point!.lastTreatmentDate!.day.toString().padLeft(2, '0')}/"
          "${widget.point!.lastTreatmentDate!.month.toString().padLeft(2, '0')}/"
          "${widget.point!.lastTreatmentDate!.year}"
        : "Aucune date";
    return Text(
      "Dernier traitement : $date",
      style: const TextStyle(color: Colors.grey),
    );
  
  }

  Widget _photoPicker() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(color: AppColors.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          // TODO: intégrer image_picker
        },
        icon: const Icon(Icons.upload, color: AppColors.primaryBlue),
        label: const Text(
          "Ajouter une photo",
          style: TextStyle(
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _photoPreview() {
    return ClipRRect(
       
      borderRadius: BorderRadius.circular(8),
      child: widget.point?.photoUrl != null
          ? Image.network(
              widget.point!.photoUrl!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : Image.network(
              "https://via.placeholder.com/300",
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _commentField() {
    return TextField(
      controller: commentController,
      maxLines: 4,
      style: const TextStyle(color: AppColors.primaryBlue),
      decoration: InputDecoration(
        labelText: "Commentaires",
        labelStyle: const TextStyle(color: AppColors.primaryBlue),
        border:  OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
      
    );
  }

    Widget _historyButton() {
    return SizedBox(
        width: double.infinity,
        child:  OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(color: AppColors.primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      onPressed: () {
         final fakePoint = widget.point ??
            Point(
              id: "123",
              name: "Point de test",
              latitude: 0,
              longitude: 0,
              comment: "Commentaire de test",
              label: Label(id: "1", name: "Avaloir avec de l'eau"),
              isTreated: true,
              lastTreatmentDate: DateTime.now().subtract(const Duration(days: 5)),
            );

      final fakeInterventions = widget.interventions.isNotEmpty
          ? widget.interventions
          : [
              Intervention(
                id: "1",
                interventionType: "treated",
                comment: "Avec de l'eau",
                performedBy: "Lucas",
                performedAt: DateTime.now(),
              ),
              Intervention(
                id: "2",
                interventionType: "added",
                comment: "Avaloir encombré",
                performedBy: "John",
                performedAt: DateTime.now().subtract(const Duration(days: 10)),
              ),
              Intervention(
                id: "2",
                interventionType: "added",
                comment: "Avaloir encombré",
                performedBy: "John",
                performedAt: DateTime.now().subtract(const Duration(days: 10)),
              ),
              Intervention(
                id: "2",
                interventionType: "added",
                comment: "Avaloir encombré",
                performedBy: "John",
                performedAt: DateTime.now().subtract(const Duration(days: 10)),
              ),
              Intervention(
                id: "2",
                interventionType: "added",
                comment: "Avaloir encombré",
                performedBy: "John",
                performedAt: DateTime.now().subtract(const Duration(days: 10)),
              ),
            ];
        showDialog(
          context: context,
          builder: (_) => PointHistoryDialog(
            point: widget.point?? fakePoint,
            interventions: fakeInterventions,
          ),
        );
      },
      icon: const Icon(Icons.history),
      label: const Text("Voir l’historique" , 
        style: TextStyle(
            color: AppColors.primaryBlue,
          ),
        ),
      ),
    );
  }


  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
           shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        ),
       
        onPressed: () {
          // TODO: implémenter la logique de sauvegarde
          Navigator.pop(context);
        },
        child: Text(widget.isEdit ? "Enregistrer" : "Ajouter"),
      ),
    );
  }
}
