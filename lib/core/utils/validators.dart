class Validators {
  Validators._();

  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName wajib diisi';
    return null;
  }

  static String? email(String? value) {
    final required = Validators.required(value, fieldName: 'Email');
    if (required != null) return required;
    final regex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(value!.trim())) return 'Email tidak valid';
    return null;
  }

  static String? phone(String? value) {
    final required = Validators.required(value, fieldName: 'Nomor telepon');
    if (required != null) return required;
    final regex = RegExp(r'^(\+62|62|0)8[1-9][0-9]{6,11}$');
    if (!regex.hasMatch(value!.replaceAll(' ', '').replaceAll('-', ''))) {
      return 'Nomor telepon tidak valid';
    }
    return null;
  }

  static String? password(String? value) {
    final required = Validators.required(value, fieldName: 'Kata sandi');
    if (required != null) return required;
    if (value!.length < 8) return 'Minimal 8 karakter';
    return null;
  }

  static String? positiveNumber(String? value, {String fieldName = 'Nilai'}) {
    final required = Validators.required(value, fieldName: fieldName);
    if (required != null) return required;
    final parsed = double.tryParse(value!.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return '$fieldName harus lebih dari 0';
    return null;
  }
}
