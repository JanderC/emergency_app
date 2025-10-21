class Validators {
  /// Valida que el campo no esté vacío
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Valida que el nombre no contenga números ni caracteres especiales
  static String? name(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    
    // Regex: solo letras, espacios, acentos y ñ
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    
    if (!nameRegex.hasMatch(value.trim())) {
      return '$fieldName no debe contener números ni caracteres especiales';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName debe tener al menos 2 caracteres';
    }
    
    return null;
  }

  /// Valida email
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Correo electrónico es requerido';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingrese un correo electrónico válido';
    }
    
    return null;
  }

  /// Valida cédula (solo números)
  static String? cedula(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Cédula es requerida';
    }
    
    final cedulaRegex = RegExp(r'^\d+$');
    
    if (!cedulaRegex.hasMatch(value.trim())) {
      return 'Cédula debe contener solo números';
    }
    
    if (value.trim().length < 6) {
      return 'Cédula debe tener al menos 6 dígitos';
    }
    
    return null;
  }

  /// Valida dirección
  static String? direccion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Dirección es requerida';
    }
    
    if (value.trim().length < 10) {
      return 'Dirección debe ser más específica (mínimo 10 caracteres)';
    }
    
    return null;
  }

  /// Valida teléfono
  static String? telefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Teléfono es requerido';
    }
    
    // Eliminar espacios y guiones
    final cleanPhone = value.replaceAll(RegExp(r'[\s-]'), '');
    final phoneRegex = RegExp(r'^\d+$');
    
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Teléfono debe contener solo números';
    }
    
    if (cleanPhone.length < 10) {
      return 'Teléfono debe tener al menos 10 dígitos';
    }
    
    return null;
  }

  /// Valida contraseña
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contraseña es requerida';
    }
    
    if (value.length < 6) {
      return 'Contraseña debe tener al menos 6 caracteres';
    }
    
    return null;
  }

  /// Valida confirmación de contraseña
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirmar contraseña es requerido';
    }
    
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    
    return null;
  }

  /// Valida código de bombero
  static String? codigoBombero(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Código de bombero es requerido';
    }
    
    if (value.trim().length < 3) {
      return 'Código debe tener al menos 3 caracteres';
    }
    
    return null;
  }

  /// Valida estación
  static String? estacion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Estación de pertenencia es requerida';
    }
    
    if (value.trim().length < 3) {
      return 'Nombre de estación debe tener al menos 3 caracteres';
    }
    
    return null;
  }
}