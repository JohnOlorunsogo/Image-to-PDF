import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:images_to_pdf/core/theme/app_colors.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final List<String> _capturedImages = [];
  bool _isBatchMode = true; // Default to batch mode
  AwesomeFilter _currentFilter = AwesomeFilter.None;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CameraAwesomeBuilder.custom(
        saveConfig: SaveConfig.photo(
          pathBuilder: (sensors) async {
            final Directory extDir = await getTemporaryDirectory();
            final testDir = await Directory(
              '${extDir.path}/camerawesome',
            ).create(recursive: true);
            final String filePath =
                '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
            // Return SingleCaptureRequest for single sensor (back camera)
            return SingleCaptureRequest(filePath, sensors.first);
          },
        ),
        builder: (cameraState, preview) {
          return Stack(
            children: [
              // 1. Top Bar (Flash, Close)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: _buildTopBar(context, cameraState),
              ),

              // 2. Mode Toggle (Single / Batch)
              Positioned(
                top: MediaQuery.of(context).padding.top + 80,
                left: 0,
                right: 0,
                child: Center(child: _buildModeToggle()),
              ),

              // 3. Bottom Controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomControls(context, cameraState),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, CameraState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Close Button
        IconButton(
          onPressed: () {
            if (_capturedImages.isNotEmpty) {
              Navigator.pop(context, _capturedImages);
            } else {
              Navigator.pop(context);
            }
          },
          icon: const Icon(
            IconsaxPlusLinear.close_circle,
            color: Colors.white,
            size: 28,
          ),
        ),

        // Flash Button (Toggle)
        StreamBuilder<SensorConfig>(
          stream: state.sensorConfig$,
          builder: (_, sensorConfigSnapshot) {
            if (!sensorConfigSnapshot.hasData) return const SizedBox.shrink();
            final sensorConfig = sensorConfigSnapshot.data!;
            return StreamBuilder<FlashMode>(
              stream: sensorConfig.flashMode$,
              builder: (_, flashModeSnapshot) {
                final flashMode = flashModeSnapshot.data ?? FlashMode.none;
                return IconButton(
                  onPressed: () {
                    // Cyclic toggle: none -> auto -> on -> always
                    FlashMode next;
                    if (flashMode == FlashMode.none)
                      next = FlashMode.auto;
                    else if (flashMode == FlashMode.auto)
                      next = FlashMode.on;
                    else
                      next = FlashMode.none;
                    sensorConfig.setFlashMode(next);
                  },
                  icon: Icon(
                    _getFlashIcon(flashMode),
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  IconData _getFlashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.none:
        return Icons.flash_off_rounded;
      case FlashMode.on:
        return Icons.flash_on_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
        return Icons.highlight_rounded;
    }
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton('Single', !_isBatchMode),
          _modeButton('Batch', _isBatchMode),
        ],
      ),
    );
  }

  Widget _modeButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _isBatchMode = text == 'Batch');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, CameraState state) {
    return Container(
      padding: const EdgeInsets.only(bottom: 40, top: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter Scroll
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: awesomePresetFiltersList.length,
              itemBuilder: (context, index) {
                final filter = awesomePresetFiltersList[index];
                final isSelected = _currentFilter == filter;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentFilter = filter);
                    state.setFilter(filter);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                            color: Colors
                                .grey[800], // Preview color/image placeholder
                          ),
                          child: Center(
                            child: Text(
                              filter.name[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          filter.name,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery / Preview (Left)
              GestureDetector(
                onTap: () {
                  // Open gallery if implemented, or just return
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    image: _capturedImages.isNotEmpty
                        ? DecorationImage(
                            image: FileImage(File(_capturedImages.last)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _capturedImages.isEmpty
                      ? const Icon(
                          IconsaxPlusLinear.gallery,
                          color: Colors.white,
                          size: 24,
                        )
                      : null,
                ),
              ),

              // Shutter Button (Center)
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await state.when(
                    onPhotoMode: (photoState) async {
                      try {
                        final captureRequest = await photoState.takePhoto();
                        final path = captureRequest.when(
                          single: (single) => single.file!.path,
                          multiple: (multiple) =>
                              multiple.fileBySensor.values.first!.path,
                        );

                        setState(() {
                          _capturedImages.add(path);
                        });

                        if (!_isBatchMode) {
                          if (context.mounted) {
                            Navigator.pop(context, _capturedImages);
                          }
                        }
                      } catch (e) {
                        debugPrint("Error taking photo: $e");
                      }
                    },
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white24,
                  ),
                  child: Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Done Button (Right) - Shows count in Batch mode
              if (_isBatchMode && _capturedImages.isNotEmpty)
                GestureDetector(
                  onTap: () => Navigator.pop(context, _capturedImages),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: Center(
                      child: Text(
                        '${_capturedImages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 48), // Placeholder to balance layout
            ],
          ),
        ],
      ),
    );
  }
}
