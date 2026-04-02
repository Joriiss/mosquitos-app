import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  Set<String> selectedTags = {};

  File? _selectedImage;
  bool _isUploading = false;
  String? _photoUrl;
  
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
    setState(() => _selectedImage = File(picked.path));
    await _uploadImage(_selectedImage!);
  }
}
Future<void> _uploadImage(File image) async {
  setState(() => _isUploading = true);
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://ton-api.com/api/points/upload-photo/'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('photo', image.path),
    );
    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);
    // json['photo_url'] → l'URL retournée par Django
    setState(() => _photoUrl = json['photo_url']);
  } finally {
    setState(() => _isUploading = false);
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
    return const Text("Dernier traitement");
  }

Widget _photoPicker() {
  return Column(
    children: [
      if (_selectedImage != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(_selectedImage!, height: 150, fit: BoxFit.cover),
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
   if (widget.point?.photoUrl == null || widget.point!.photoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
       
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        widget.point!.photoUrl!,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover, )
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
        onPressed: isSubmitting
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
                  if (widget.isEdit) {
                    final id = widget.point?.id;
                    if (id == null) {
                      if (mounted) Navigator.pop(context, false);
                      return;
                    }
                    await ApiService.updatePoint(
                      pointId: id,
                      name: nameController.text.trim(),
                      description: commentController.text.trim(),
                      latitude: widget.latitude,
                      longitude: widget.longitude,
                      labelId: selectedLabelId!,
                      comment: commentController.text.trim(),
                      isTreated: _showTreatedSwitch ? isTreated : false,
                    );
                    if (!mounted) return;
                    Navigator.pop(context, true);
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

                    if (widget.parcoursId != null) {
                      await ApiService.addPointToParcours(
                        parcoursId: widget.parcoursId!,
                        pointId: created['id'],
                      );
                    }

                    if (!mounted) return;

                    Navigator.pop(context, true);
                  }
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
