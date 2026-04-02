import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mosquitos_app/features/point_history.dart';
import 'package:mosquitos_app/models/intervention_model.dart';
import 'package:mosquitos_app/models/point_model.dart';
import 'package:mosquitos_app/theme/app_colors.dart';
import 'package:mosquitos_app/services/api_service.dart';

/// [Navigator.pop] value from [PointModal] when the point was deleted on the server.
const String kPointModalDeleted = 'point_modal_deleted';

class PointModal extends StatefulWidget {
  final bool isEdit;
  final Point? point;
  final List<Intervention> interventions;

  final double latitude;
  final double longitude;
  final String? parcoursId;
  final String? defaultName;
 

  const PointModal({
    super.key,
    required this.isEdit,
    this.point,
    this.interventions = const [],
    required this.latitude,
    required this.longitude,
    this.parcoursId,
    this.defaultName,
  });

  @override
  State<PointModal> createState() => _PointModalState();
}

class _PointModalState extends State<PointModal> {
  late TextEditingController nameController;
  late TextEditingController commentController;

  
  bool isTreated = false;
  bool isSubmitting = false;
  bool _isDeleting = false;

  Set<String> selectedTags = {};
  List<File> _selectedImages = [];
  bool _isUploading = false;
  
  
  List<Label> apiLabels = [];
  String? selectedLabelId;
Future<void> _pickImage() async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.primaryBlue),
            title: const Text("Choisir depuis la galerie"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.primaryBlue),
            title: const Text("Prendre une photo"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    ),
  );

  if (source == null) return; // l'utilisateur a fermé sans choisir

  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source, // ← galerie ou caméra selon le choix
    imageQuality: 80,
  );
  if (picked != null) {
    
    setState(() => _selectedImages.add(File(picked.path)));
   
  }
}
 @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.point?.name ?? widget.defaultName ?? '',
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

  Label? get _selectedLabel {
    if (selectedLabelId == null) return null;
    for (final l in apiLabels) {
      if (l.id == selectedLabelId) return l;
    }
    return null;
  }

  /// Show "Point déjà traité ?" only when the label can be treated.
  bool get _showTreatedSwitch => _selectedLabel?.isTreatable ?? true;

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

        final sel =
            labels.where((l) => l.id == selectedLabelId).toList();
        if (sel.isNotEmpty && !sel.first.isTreatable) {
          isTreated = false;
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                 const SizedBox(height: 16),
                _nameField(),
                const SizedBox(height: 16),
                 _photoPreview(),
                 const SizedBox(height: 16),
                 _photoPicker(),
                const SizedBox(height: 16),
                _tagsSection(),
                const SizedBox(height: 16),
                if (widget.isEdit) _dateInfo(),
                _treatedSwitch(),
                const SizedBox(height: 16),
                _commentField(),
                const SizedBox(height: 16),
                
                if (widget.isEdit) _historyButton(),
                if (widget.isEdit) ...[
                  const SizedBox(height: 16),
                  _deleteButton(),
                ],
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
        Expanded(
          child: Text(
            widget.isEdit
                ? (widget.point?.name ?? 'Point')
                : "Ajouter un point",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
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
      style: const TextStyle(color: AppColors.primaryBlue),
      decoration: InputDecoration(
        labelText: "Nom",
        labelStyle: const TextStyle(color: AppColors.primaryBlue),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _tagsSection() {
    final tags = apiLabels;
    if (apiLabels.isEmpty) {
      return const Text('Aucune étiquette disponible');
    }
    return Wrap(
      spacing: 8,
      children: tags.map((tag) {
        final isSelected = selectedLabelId == tag.id;

        return ChoiceChip(
          label: Text(tag.name),
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
            if (!val) return;

            setState(() {
              selectedLabelId = tag.id;
              selectedTags = {tag.name};
              if (!tag.isTreatable) {
                isTreated = false;
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _treatedSwitch() {
    if (!_showTreatedSwitch) {
      return const SizedBox.shrink();
    }
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
      style: const TextStyle(color: Colors.black),
    );
  
  }

Widget _photoPicker() {
  return Column(
    children: [
      if (_selectedImages.isNotEmpty)
  SizedBox(
    height: 150,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _selectedImages.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_selectedImages[i], height: 150, width: 150, fit: BoxFit.cover),
      ),
    ),
  ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(  style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(color: AppColors.primaryBlue, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
          onPressed: _isUploading ? null : _pickImage,
          icon: _isUploading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload, color: AppColors.primaryBlue),
          label: Text(_isUploading ? "Upload en cours..." : "Ajouter une photo",style: TextStyle(
            color: AppColors.primaryBlue,
          ),),
        ),
      ),
    ],
  );
}

Widget _photoPreview() {
  final photos = widget.point?.photos ?? [];
  if (photos.isEmpty) return const SizedBox.shrink();

  return SizedBox(
    height: 150,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: photos.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            photos[index],
            height: 150,
            width: 150,
            fit: BoxFit.cover,
          ),
        );
      },
    ),
  );
}
  Widget _commentField() {
    return TextField(
      controller: commentController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: "Commentaires",
         labelStyle: const TextStyle(color: AppColors.primaryBlue),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: AppColors.white,
      ),
    );
  }

  Future<void> _confirmAndDeletePoint() async {
    final id = widget.point?.id;
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce point ?'),
        content: const Text(
          'Cette action est définitive. Le point sera retiré de la cartographie.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ApiService.deletePoint(id);
      if (!mounted) return;
      Navigator.of(context).pop(kPointModalDeleted);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de supprimer le point')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Widget _deleteButton() {
    if (widget.point?.id == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          side: BorderSide(color: Colors.red.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: (isSubmitting || _isDeleting) ? null : _confirmAndDeletePoint,
        icon: _isDeleting
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.red.shade700,
                ),
              )
            : Icon(Icons.delete_outline, color: Colors.red.shade700),
        label: Text(
          _isDeleting ? 'Suppression…' : 'Supprimer le point',
          style: TextStyle(
            color: Colors.red.shade700,
            fontFamily: 'Gabarito',
            fontWeight: FontWeight.w500,
          ),
        ),
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
         

      showDialog(
          context: context,
          builder: (_) => PointHistoryDialog(
            point: widget.point!,
            interventions: widget.interventions,
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
        onPressed: (isSubmitting || _isDeleting)
            ? null
            : () async {
                if (selectedLabelId == null ||
                    nameController.text.trim().isEmpty) {
                  return;
                }

                setState(() {
                  isSubmitting = true;
                });

                try {
                  String pointId='';
                    
                   
                  if (widget.isEdit) {
                    final id = widget.point?.id;
                    if (id == null) {
                      if (mounted) Navigator.pop(context, false);
                      return;
                    }
                   final updated = await ApiService.updatePoint(
                      pointId: id,
                      name: nameController.text.trim(),
                      description: commentController.text.trim(),
                      latitude: widget.latitude,
                      longitude: widget.longitude,
                      labelId: selectedLabelId!,
                      comment: commentController.text.trim(),
                      isTreated: _showTreatedSwitch ? isTreated : false,
                    );
                    pointId = updated['id'];
                  } else {
                    final created = await ApiService.createPoint(
                      name: nameController.text.trim(),
                      description: commentController.text.trim(),
                      latitude: widget.latitude,
                      longitude: widget.longitude,
                      labelId: selectedLabelId!,
                      comment: commentController.text.trim(),
                      isTreated: _showTreatedSwitch ? isTreated : false,
                    );
                    pointId = created['id'];
                   
                  }
 
                    
                    if (_selectedImages.isNotEmpty) {
                    await ApiService.uploadPointPhotos(
                      pointId: pointId,
                      images: _selectedImages,
                    );
                    }

                    if (widget.parcoursId != null) {
                      await ApiService.addPointToParcours(
                        parcoursId: widget.parcoursId!,
                        pointId: pointId,
                      );
                    }

                    if (!mounted) return;

                    Navigator.pop(context, true);
                  
                } catch (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.isEdit
                            ? "Erreur lors de l'enregistrement"
                            : "Erreur lors de l'ajout",
                      ),
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
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isEdit ? "Enregistrer" : "Ajouter",
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gabarito',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.isEdit)
              Image(
                image: AssetImage('assets/icons/edit.png'),
                height: 22,
                width: 22,
              )
            else
              Image(
                image: AssetImage('assets/icons/plus-icon.png'),
                height: 22,
                width: 22,
              ),
          ],
        ),
      ),
    );
  }
}
