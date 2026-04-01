import 'package:flutter/material.dart';
import 'package:mosquitos_app/features/point_history.dart';
import 'package:mosquitos_app/models/intervention_model.dart';
import 'package:mosquitos_app/models/point_model.dart';
import 'package:mosquitos_app/theme/app_colors.dart';
import 'package:mosquitos_app/services/api_service.dart';

class PointModal extends StatefulWidget {
  final bool isEdit;
  final Point? point;
  final List<Intervention> interventions;

  final double latitude;
  final double longitude;
  final String? parcoursId;

  const PointModal({
    super.key,
    required this.isEdit,
    this.point,
    this.interventions = const [],
    required this.latitude,
    required this.longitude,
    this.parcoursId,
  });

  @override
  State<PointModal> createState() => _PointModalState();
}

class _PointModalState extends State<PointModal> {
  late TextEditingController nameController;
  late TextEditingController commentController;

  bool isTreated = false;
  bool isSubmitting = false;

  Set<String> selectedTags = {};

  List<Label> apiLabels = [];
  String? selectedLabelId;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.point?.name ?? '',
    );

    commentController = TextEditingController(
      text: widget.point?.comment ?? '',
    );

    isTreated = widget.point?.isTreated ?? false;

    if (widget.point?.label.name != null) {
      selectedTags.add(widget.point!.label.name);
      selectedLabelId = widget.point!.label.id;
    }

    _loadLabels();
  }

  Future<void> _loadLabels() async {
    try {
      final data = await ApiService.getLabels();

      final labels = data.map<Label>((e) => Label.fromJson(e)).toList();

      if (!mounted) return;

      setState(() {
        apiLabels = labels;

        if (labels.isNotEmpty && selectedLabelId == null) {
          selectedLabelId = labels.first.id;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
      ),
      child: Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
      decoration: InputDecoration(
        labelText: "Nom",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _tagsSection() {
    final tags = apiLabels;
    if (apiLabels.isEmpty) {
      return const Text('Aucun label disponible');
    }
    return Wrap(
      spacing: 8,
      children: tags.map((tag) {
        final isSelected = selectedLabelId == tag.id;

        return ChoiceChip(
          label: Text(tag.name),
          selected: isSelected,
          onSelected: (val) {
            if (!val) return;

            setState(() {
              selectedLabelId = tag.id;
              selectedTags = {tag.name};
            });
          },
        );
      }).toList(),
    );
  }

  Widget _treatedSwitch() {
    return SwitchListTile(
      title: const Text("Point déjà traité ?"),
      value: isTreated,
      onChanged: (val) {
        setState(() {
          isTreated = val;
        });
      },
    );
  }

  Widget _dateInfo() {
    return const Text("Dernier traitement");
  }

  Widget _photoPicker() {
    return OutlinedButton(
      onPressed: () {},
      child: const Text("Ajouter une photo"),
    );
  }

  Widget _photoPreview() {
    return const SizedBox(height: 120);
  }

  Widget _commentField() {
    return TextField(
      controller: commentController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: "Commentaires",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _historyButton() {
    return OutlinedButton(
      onPressed: () {},
      child: const Text("Voir l’historique"),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSubmitting
            ? null
            : () async {
                if (widget.isEdit) {
                  Navigator.pop(context);
                  return;
                }

                if (selectedLabelId == null ||
                    nameController.text.trim().isEmpty) {
                  return;
                }

                setState(() {
                  isSubmitting = true;
                });

                try {
                  final created = await ApiService.createPoint(
                    name: nameController.text.trim(),
                    description: commentController.text.trim(),
                    latitude: widget.latitude,
                    longitude: widget.longitude,
                    labelId: selectedLabelId!,
                    comment: commentController.text.trim(),
                    isTreated: isTreated,
                  );

                  if (widget.parcoursId != null) {
                    await ApiService.addPointToParcours(
                      parcoursId: widget.parcoursId!,
                      pointId: created['id'],
                    );
                  }

                  if (!mounted) return;

                  Navigator.pop(context, true);
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Erreur lors de l'ajout"),
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      isSubmitting = false;
                    });
                  }
                }
              },
        child: isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Ajouter"),
      ),
    );
  }
}
