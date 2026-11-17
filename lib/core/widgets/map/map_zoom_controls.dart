import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../constants/app_colors.dart';

class MapZoomControls extends StatelessWidget {
  final MapController mapController;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;

  const MapZoomControls({
    super.key,
    required this.mapController,
    this.alignment = Alignment.topRight,
    this.padding = const EdgeInsets.only(top: 80, right: 16),
  });

  void _zoomIn() {
    try {
      final camera = mapController.camera;
      final newZoom = (camera.zoom + 1.0).clamp(3.0, 19.0);
      mapController.move(camera.center, newZoom);
    } catch (_) {}
  }

  void _zoomOut() {
    try {
      final camera = mapController.camera;
      final newZoom = (camera.zoom - 1.0).clamp(3.0, 19.0);
      mapController.move(camera.center, newZoom);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final iconColor = isDark ? Colors.white : AppColors.lightTextNavy;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(10),
          color: bgColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                onTap: _zoomIn,
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: Icon(Icons.add_rounded, size: 22, color: iconColor),
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
                onTap: _zoomOut,
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: Icon(
                      Icons.remove_rounded,
                      size: 22,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
