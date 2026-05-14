import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? iconUrl;
  final bool isActive;
  final IconData icon;
  final Color color;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.iconUrl,
    this.isActive = true,
    required this.icon,
    required this.color,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    final slug = json['slug'] as String;
    final visual = _slugVisualMap[slug];
    return ServiceCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: slug,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      icon: visual?.icon ?? Icons.miscellaneous_services,
      color: visual?.color ?? const Color(0xFF757575),
    );
  }

  static IconData iconForSlug(String slug) =>
      _slugVisualMap[slug]?.icon ?? Icons.miscellaneous_services;

  static Color colorForSlug(String slug) =>
      _slugVisualMap[slug]?.color ?? const Color(0xFF757575);
}

class _SlugVisual {
  final IconData icon;
  final Color color;
  const _SlugVisual(this.icon, this.color);
}

const Map<String, _SlugVisual> _slugVisualMap = {
  'electrician': _SlugVisual(Icons.electrical_services, Color(0xFFF9A825)),
  'plumber': _SlugVisual(Icons.plumbing, Color(0xFF1E88E5)),
  'painter': _SlugVisual(Icons.format_paint, Color(0xFFE53935)),
  'cleaner': _SlugVisual(Icons.cleaning_services, Color(0xFF43A047)),
  'furniture_assembler': _SlugVisual(Icons.handyman, Color(0xFF8D6E63)),
  'it_technician': _SlugVisual(Icons.computer, Color(0xFF5E35B1)),
  'gardener': _SlugVisual(Icons.grass, Color(0xFF2E7D32)),
  'mason': _SlugVisual(Icons.construction, Color(0xFFFF8F00)),
  'locksmith': _SlugVisual(Icons.key, Color(0xFF6D4C41)),
  'ac_technician': _SlugVisual(Icons.ac_unit, Color(0xFF00ACC1)),
  'carpenter': _SlugVisual(Icons.carpenter, Color(0xFFD84315)),
  'glazier': _SlugVisual(Icons.window, Color(0xFF039BE5)),
  'welder': _SlugVisual(Icons.hardware, Color(0xFF546E7A)),
  'pest_control': _SlugVisual(Icons.pest_control, Color(0xFF7CB342)),
  'diarista': _SlugVisual(Icons.cleaning_services, Color(0xFF43A047)),
  'motorista': _SlugVisual(Icons.directions_car, Color(0xFF1565C0)),
};
