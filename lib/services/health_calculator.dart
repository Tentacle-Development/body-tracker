class HealthCalculator {
  /// Calculate BMI (Body Mass Index)
  /// Formula: weight (kg) / height (m)²
  static double? calculateBMI({
    required double? weightKg,
    required double? heightCm,
  }) {
    if (weightKg == null || heightCm == null) return null;
    if (weightKg <= 0 || heightCm <= 0) return null;
    
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Get BMI category
  static BMICategory getBMICategory(double bmi) {
    if (bmi < 16) return BMICategory.severeThinness;
    if (bmi < 17) return BMICategory.moderateThinness;
    if (bmi < 18.5) return BMICategory.mildThinness;
    if (bmi < 25) return BMICategory.normal;
    if (bmi < 30) return BMICategory.overweight;
    if (bmi < 35) return BMICategory.obeseClassI;
    if (bmi < 40) return BMICategory.obeseClassII;
    return BMICategory.obeseClassIII;
  }

  /// Calculate Waist-to-Hip Ratio
  static double? calculateWHR({
    required double? waistCm,
    required double? hipsCm,
  }) {
    if (waistCm == null || hipsCm == null) return null;
    if (waistCm <= 0 || hipsCm <= 0) return null;
    
    return waistCm / hipsCm;
  }

  /// Get WHR risk category
  static WHRCategory getWHRCategory(double whr, String gender) {
    if (gender == 'Male') {
      if (whr < 0.9) return WHRCategory.low;
      if (whr < 1.0) return WHRCategory.moderate;
      return WHRCategory.high;
    } else {
      if (whr < 0.8) return WHRCategory.low;
      if (whr < 0.85) return WHRCategory.moderate;
      return WHRCategory.high;
    }
  }

  /// Calculate Body Fat Percentage using US Navy method
  /// For males: 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450
  /// For females: 495 / (1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)) - 450
  static double? calculateBodyFatPercentage({
    required String gender,
    required double? heightCm,
    required double? neckCm,
    required double? waistCm,
    double? hipsCm,
  }) {
    if (heightCm == null || neckCm == null || waistCm == null) return null;
    if (heightCm <= 0 || neckCm <= 0 || waistCm <= 0) return null;
    
    if (gender == 'Male') {
      if (waistCm <= neckCm) return null;
      final logWaistNeck = _log10(waistCm - neckCm);
      final logHeight = _log10(heightCm);
      final bodyFat = 495 / (1.0324 - 0.19077 * logWaistNeck + 0.15456 * logHeight) - 450;
      return bodyFat.clamp(3, 60);
    } else {
      if (hipsCm == null || hipsCm <= 0) return null;
      if (waistCm + hipsCm <= neckCm) return null;
      final logSum = _log10(waistCm + hipsCm - neckCm);
      final logHeight = _log10(heightCm);
      final bodyFat = 495 / (1.29579 - 0.35004 * logSum + 0.22100 * logHeight) - 450;
      return bodyFat.clamp(10, 60);
    }
  }

  /// Get body fat category
  static BodyFatCategory getBodyFatCategory(double bodyFat, String gender) {
    if (gender == 'Male') {
      if (bodyFat < 6) return BodyFatCategory.essential;
      if (bodyFat < 14) return BodyFatCategory.athlete;
      if (bodyFat < 18) return BodyFatCategory.fitness;
      if (bodyFat < 25) return BodyFatCategory.average;
      return BodyFatCategory.obese;
    } else {
      if (bodyFat < 14) return BodyFatCategory.essential;
      if (bodyFat < 21) return BodyFatCategory.athlete;
      if (bodyFat < 25) return BodyFatCategory.fitness;
      if (bodyFat < 32) return BodyFatCategory.average;
      return BodyFatCategory.obese;
    }
  }

  /// Calculate Waist-to-Height Ratio
  static double? calculateWtHR({
    required double? waistCm,
    required double? heightCm,
  }) {
    if (waistCm == null || heightCm == null) return null;
    if (waistCm <= 0 || heightCm <= 0) return null;
    
    return waistCm / heightCm;
  }

  /// Get Waist-to-Height ratio category
  static WtHRCategory getWtHRCategory(double wthr) {
    if (wthr < 0.4) return WtHRCategory.underweight;
    if (wthr < 0.5) return WtHRCategory.healthy;
    if (wthr < 0.6) return WtHRCategory.overweight;
    return WtHRCategory.obese;
  }

  /// Calculate Ideal Weight using multiple formulas
  static IdealWeight? calculateIdealWeight({
    required double? heightCm,
    required String gender,
  }) {
    if (heightCm == null || heightCm <= 0) return null;
    
    final heightInches = heightCm / 2.54;
    final heightOver5Ft = heightInches - 60;
    
    double robinson, miller, devine, hamwi;
    
    if (gender == 'Male') {
      robinson = 52 + 1.9 * heightOver5Ft;
      miller = 56.2 + 1.41 * heightOver5Ft;
      devine = 50 + 2.3 * heightOver5Ft;
      hamwi = 48 + 2.7 * heightOver5Ft;
    } else {
      robinson = 49 + 1.7 * heightOver5Ft;
      miller = 53.1 + 1.36 * heightOver5Ft;
      devine = 45.5 + 2.3 * heightOver5Ft;
      hamwi = 45.5 + 2.2 * heightOver5Ft;
    }
    
    return IdealWeight(
      robinson: robinson,
      miller: miller,
      devine: devine,
      hamwi: hamwi,
      average: (robinson + miller + devine + hamwi) / 4,
    );
  }

  static double _log10(double x) {
    return 0.434294481903252 * _ln(x);
  }

  static double _ln(double x) {
    if (x <= 0) return double.nan;
    
    double result = 0;
    double term = (x - 1) / (x + 1);
    double termSquared = term * term;
    double currentTerm = term;
    
    for (int i = 1; i < 100; i += 2) {
      result += currentTerm / i;
      currentTerm *= termSquared;
    }
    
    return 2 * result;
  }
}

enum BMICategory {
  severeThinness('Severe Thinness', 'Very underweight - health risk', 0xFFE53935),
  moderateThinness('Moderate Thinness', 'Underweight - health concern', 0xFFFF7043),
  mildThinness('Mild Thinness', 'Slightly underweight', 0xFFFFB74D),
  normal('Normal', 'Healthy weight range', 0xFF4CAF50),
  overweight('Overweight', 'Above healthy range', 0xFFFFB74D),
  obeseClassI('Obese Class I', 'Moderate obesity', 0xFFFF7043),
  obeseClassII('Obese Class II', 'Severe obesity', 0xFFE53935),
  obeseClassIII('Obese Class III', 'Very severe obesity', 0xFFB71C1C);

  final String label;
  final String description;
  final int colorValue;

  const BMICategory(this.label, this.description, this.colorValue);
}

enum WHRCategory {
  low('Low Risk', 'Healthy distribution', 0xFF4CAF50),
  moderate('Moderate Risk', 'Some health concern', 0xFFFFB74D),
  high('High Risk', 'Increased health risk', 0xFFE53935);

  final String label;
  final String description;
  final int colorValue;

  const WHRCategory(this.label, this.description, this.colorValue);
}

enum BodyFatCategory {
  essential('Essential Fat', 'Minimum for survival', 0xFFE53935),
  athlete('Athlete', 'Athletic level', 0xFF2196F3),
  fitness('Fitness', 'Fit and healthy', 0xFF4CAF50),
  average('Average', 'Acceptable range', 0xFFFFB74D),
  obese('Obese', 'Above healthy range', 0xFFE53935);

  final String label;
  final String description;
  final int colorValue;

  const BodyFatCategory(this.label, this.description, this.colorValue);
}

enum WtHRCategory {
  underweight('Underweight', 'Below healthy range', 0xFFFFB74D),
  healthy('Healthy', 'Optimal range', 0xFF4CAF50),
  overweight('Overweight', 'Above healthy range', 0xFFFFB74D),
  obese('Obese', 'High health risk', 0xFFE53935);

  final String label;
  final String description;
  final int colorValue;

  const WtHRCategory(this.label, this.description, this.colorValue);
}

class IdealWeight {
  final double robinson;
  final double miller;
  final double devine;
  final double hamwi;
  final double average;

  const IdealWeight({
    required this.robinson,
    required this.miller,
    required this.devine,
    required this.hamwi,
    required this.average,
  });
}
