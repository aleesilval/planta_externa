import 'package:flutter/material.dart';

class FormDataManager {
  static final FormDataManager _instance = FormDataManager._internal();
  factory FormDataManager() => _instance;
  FormDataManager._internal();

  // Planilla 1 data
  Map<String, dynamic> planilla1Data = {};
  
  // Planilla 2 data
  Map<String, dynamic> planilla2Data = {};
  
  // Planilla 3 data
  Map<String, dynamic> planilla3Data = {};

  void savePlanilla1Data(Map<String, dynamic> data) {
    planilla1Data = Map.from(data);
  }

  void savePlanilla2Data(Map<String, dynamic> data) {
    planilla2Data = Map.from(data);
  }

  void savePlanilla3Data(Map<String, dynamic> data) {
    planilla3Data = Map.from(data);
  }

  Map<String, dynamic> getPlanilla1Data() => Map.from(planilla1Data);
  Map<String, dynamic> getPlanilla2Data() => Map.from(planilla2Data);
  Map<String, dynamic> getPlanilla3Data() => Map.from(planilla3Data);

  void clearAllData() {
    planilla1Data.clear();
    planilla2Data.clear();
    planilla3Data.clear();
  }
}