import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/progress_photo.dart';

class PhotoCompareScreen extends StatefulWidget {
  final List<ProgressPhoto> photos;

  const PhotoCompareScreen({super.key, required this.photos});

  @override
  State<PhotoCompareScreen> createState() => _PhotoCompareScreenState();
}

class _PhotoCompareScreenState extends State<PhotoCompareScreen> {
  late List<ProgressPhoto> _sortedPhotos;
  int _beforeIndex = 0;
  int _afterIndex = 1;
  double _overlayOpacity = 0.5;
  bool _showOverlay = false;

  final TransformationController _beforeController = TransformationController();
  final TransformationController _afterController = TransformationController();

  @override
  void initState() {
    super.initState();
    _sortedPhotos = List.from(widget.photos)
      ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
    if (_sortedPhotos.length > 1) {
      _beforeIndex = 0;
      _afterIndex = _sortedPhotos.length - 1;
    }
  }

  @override
  void dispose() {
    _beforeController.dispose();
    _afterController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    setState(() {
      _beforeController.value = Matrix4.identity();
      _afterController.value = Matrix4.identity();
    });
  }

  void _selectPhoto(bool isBefore) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isBefore ? 'Select BEFORE Photo' : 'Select AFTER Photo',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _sortedPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = _sortedPhotos[index];
                    final isSelected = isBefore
                        ? index == _beforeIndex
                        : index == _afterIndex;
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, index),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(photo.imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 3,
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                DateFormat('MMM d, y').format(photo.takenAt),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );

    if (selected != null) {
      setState(() {
        if (isBefore) {
          _beforeIndex = selected;
        } else {
          _afterIndex = selected;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final beforePhoto = _sortedPhotos[_beforeIndex];
    final afterPhoto = _sortedPhotos[_afterIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetZoom,
            tooltip: 'Reset Zoom',
          ),
          IconButton(
            icon: Icon(_showOverlay ? Icons.layers : Icons.layers_outlined),
            onPressed: () => setState(() => _showOverlay = !_showOverlay),
            tooltip: 'Toggle Overlay Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _showOverlay
                ? _buildOverlayView(beforePhoto, afterPhoto)
                : _buildSideBySideView(beforePhoto, afterPhoto),
          ),
          if (_showOverlay)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Before'),
                  Expanded(
                    child: Slider(
                      value: _overlayOpacity,
                      onChanged: (value) =>
                          setState(() => _overlayOpacity = value),
                    ),
                  ),
                  const Text('After'),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPhotoSelector(
                      'BEFORE',
                      beforePhoto,
                      () => _selectPhoto(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPhotoSelector(
                      'AFTER',
                      afterPhoto,
                      () => _selectPhoto(false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBySideView(ProgressPhoto before, ProgressPhoto after) {
    return Row(
      children: [
        Expanded(
          child: _buildPhotoPanel(before, 'BEFORE', _beforeController),
        ),
        Container(width: 2, color: Colors.grey[800]),
        Expanded(
          child: _buildPhotoPanel(after, 'AFTER', _afterController),
        ),
      ],
    );
  }

  Widget _buildOverlayView(ProgressPhoto before, ProgressPhoto after) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          transformationController: _beforeController,
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.file(
            File(before.imagePath),
            fit: BoxFit.contain,
          ),
        ),
        Opacity(
          opacity: _overlayOpacity,
          child: InteractiveViewer(
            transformationController: _afterController,
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.file(
              File(after.imagePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPanel(ProgressPhoto photo, String label, TransformationController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          transformationController: controller,
          minScale: 1.0,
          maxScale: 4.0,
          clipBehavior: Clip.hardEdge,
          child: Center(
            child: Image.file(
              File(photo.imagePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (photo.weight != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${photo.weight} kg',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateFormat('MMM d, y').format(photo.takenAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSelector(
    String label,
    ProgressPhoto photo,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(photo.imagePath),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(photo.takenAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.swap_horiz, color: Colors.grey[600], size: 20),
          ],
        ),
      ),
    );
  }
}
