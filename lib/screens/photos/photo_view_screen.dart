import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/progress_photo.dart';
import '../../services/photo_service.dart';
import '../../providers/app_provider.dart';

class PhotoViewScreen extends StatefulWidget {
  final ProgressPhoto photo;
  final VoidCallback? onDelete;

  const PhotoViewScreen({
    super.key,
    required this.photo,
    this.onDelete,
  });

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  late ProgressPhoto _currentPhoto;

  @override
  void initState() {
    super.initState();
    _currentPhoto = widget.photo;
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              widget.onDelete?.call();
              Navigator.pop(context); // Return to gallery
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _editWeight() async {
    final appProvider = context.read<AppProvider>();
    final unit = appProvider.getLatestMeasurement('weight')?.unit ?? 'kg';
    final controller = TextEditingController(
      text: _currentPhoto.weight?.toStringAsFixed(1) ?? '',
    );

    final newWeight = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Weight'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Weight ($unit)',
            border: const OutlineInputBorder(),
            suffixText: unit,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newWeight != null) {
      final updatedPhoto = _currentPhoto.copyWith(weight: newWeight);
      await PhotoService.instance.updatePhoto(updatedPhoto);
      await appProvider.loadPhotos();
      
      // Also sync to measurements
      await appProvider.syncPhotoWeight(newWeight, _currentPhoto.takenAt);
      
      setState(() {
        _currentPhoto = updatedPhoto;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weight updated!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.scale),
            onPressed: _editWeight,
            tooltip: 'Edit Weight',
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Hero(
              tag: 'photo_${_currentPhoto.id}',
              child: Image.file(
                File(_currentPhoto.imagePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey, size: 64),
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (_currentPhoto.category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _currentPhoto.category!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          DateFormat('EEEE, MMMM d, y').format(_currentPhoto.takenAt),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_currentPhoto.weight != null)
                      Row(
                        children: [
                          const Icon(Icons.scale, color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Weight: ${_currentPhoto.weight} kg',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    if (_currentPhoto.notes != null && _currentPhoto.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _currentPhoto.notes!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
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
