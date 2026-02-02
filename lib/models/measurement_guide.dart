import 'package:flutter/material.dart';

class MeasurementGuide {
  final String type;
  final String title;
  final String description;
  final String instruction;
  final IconData icon;
  final Color color;
  final String unit;
  final double minValue;
  final double maxValue;

  const MeasurementGuide({
    required this.type,
    required this.title,
    required this.description,
    required this.instruction,
    required this.icon,
    required this.color,
    required this.unit,
    required this.minValue,
    required this.maxValue,
  });

  static const List<MeasurementGuide> guides = [
    MeasurementGuide(
      type: 'height',
      title: 'Height',
      description: 'Your total body height',
      instruction: 'Stand straight against a wall without shoes. Look straight ahead. Measure from the floor to the top of your head.',
      icon: Icons.height,
      color: Color(0xFF4CAF50),
      unit: 'cm',
      minValue: 100,
      maxValue: 250,
    ),
    MeasurementGuide(
      type: 'weight',
      title: 'Weight',
      description: 'Your body weight',
      instruction: 'Weigh yourself in the morning before eating, wearing minimal clothing. Use a flat, hard surface for your scale.',
      icon: Icons.monitor_weight_outlined,
      color: Color(0xFF2196F3),
      unit: 'kg',
      minValue: 30,
      maxValue: 300,
    ),
    MeasurementGuide(
      type: 'neck',
      title: 'Neck',
      description: 'Circumference of your neck',
      instruction: 'Measure around the base of your neck, just below the Adam\'s apple. Keep the tape level and snug but not tight.',
      icon: Icons.accessibility_new,
      color: Color(0xFF9C27B0),
      unit: 'cm',
      minValue: 25,
      maxValue: 60,
    ),
    MeasurementGuide(
      type: 'shoulders',
      title: 'Shoulders',
      description: 'Width across your shoulders',
      instruction: 'Measure across the back from one shoulder edge to the other, at the widest point where your arms connect.',
      icon: Icons.open_with,
      color: Color(0xFF00BCD4),
      unit: 'cm',
      minValue: 30,
      maxValue: 70,
    ),
    MeasurementGuide(
      type: 'chest',
      title: 'Chest',
      description: 'Circumference around your chest',
      instruction: 'Measure around the fullest part of your chest, keeping the tape parallel to the floor. Breathe normally.',
      icon: Icons.straighten,
      color: Color(0xFFFF5722),
      unit: 'cm',
      minValue: 60,
      maxValue: 160,
    ),
    MeasurementGuide(
      type: 'waist',
      title: 'Waist',
      description: 'Circumference of your waist',
      instruction: 'Measure around your natural waistline, at the narrowest part of your torso (usually just above the belly button).',
      icon: Icons.radio_button_unchecked,
      color: Color(0xFFFF9800),
      unit: 'cm',
      minValue: 50,
      maxValue: 160,
    ),
    MeasurementGuide(
      type: 'hips',
      title: 'Hips',
      description: 'Circumference around your hips',
      instruction: 'Measure around the fullest part of your hips and buttocks, keeping the tape parallel to the floor.',
      icon: Icons.circle_outlined,
      color: Color(0xFFE91E63),
      unit: 'cm',
      minValue: 60,
      maxValue: 180,
    ),
    MeasurementGuide(
      type: 'biceps',
      title: 'Biceps',
      description: 'Circumference of your upper arm',
      instruction: 'Measure around the thickest part of your upper arm (bicep) while your arm is relaxed at your side.',
      icon: Icons.fitness_center,
      color: Color(0xFF673AB7),
      unit: 'cm',
      minValue: 15,
      maxValue: 60,
    ),
    MeasurementGuide(
      type: 'forearm',
      title: 'Forearm',
      description: 'Circumference of your forearm',
      instruction: 'Measure around the thickest part of your forearm, below the elbow.',
      icon: Icons.back_hand_outlined,
      color: Color(0xFF3F51B5),
      unit: 'cm',
      minValue: 15,
      maxValue: 45,
    ),
    MeasurementGuide(
      type: 'thigh',
      title: 'Thigh',
      description: 'Circumference of your upper leg',
      instruction: 'Measure around the thickest part of your thigh, just below your buttocks.',
      icon: Icons.airline_seat_legroom_normal,
      color: Color(0xFF795548),
      unit: 'cm',
      minValue: 30,
      maxValue: 90,
    ),
    MeasurementGuide(
      type: 'calf',
      title: 'Calf',
      description: 'Circumference of your lower leg',
      instruction: 'Measure around the thickest part of your calf muscle.',
      icon: Icons.directions_walk,
      color: Color(0xFF607D8B),
      unit: 'cm',
      minValue: 20,
      maxValue: 60,
    ),
  ];

  static MeasurementGuide? getGuide(String type) {
    try {
      return guides.firstWhere((g) => g.type == type);
    } catch (_) {
      return null;
    }
  }
}
