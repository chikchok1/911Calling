import 'package:flutter/material.dart';

class EmergencyType {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String description;
  final List<String> steps;
  final String? textGuide;
  final String? audioGuide;
  final String? videoGuide;
  final List<String>? ttsSteps;

  EmergencyType({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.description,
    required this.steps,
    this.textGuide,
    this.audioGuide,
    this.videoGuide,
    this.ttsSteps,
  });
}
