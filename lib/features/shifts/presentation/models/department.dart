enum Department {
  repartoMobile,
  polfer,
}

extension DepartmentX on Department {
  String get id {
    switch (this) {
      case Department.repartoMobile:
        return 'reparto_mobile';
      case Department.polfer:
        return 'polfer';
    }
  }

  String get label {
    switch (this) {
      case Department.repartoMobile:
        return 'Reparto Mobile';
      case Department.polfer:
        return 'Polfer';
    }
  }
}