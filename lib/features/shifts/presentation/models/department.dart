enum Department {
  repartoMobile,
  polfer,
  questura,
  polstrada,
}

extension DepartmentX on Department {
  String get id {
    switch (this) {
      case Department.repartoMobile:
        return 'reparto_mobile';

      case Department.polfer:
        return 'polfer';

      case Department.questura:
        return 'questura';

      case Department.polstrada:
        return 'polstrada';
    }
  }

  String get label {
    switch (this) {
      case Department.repartoMobile:
        return 'Reparto Mobile';

      case Department.polfer:
        return 'Polfer';

      case Department.questura:
        return 'Questura';

      case Department.polstrada:
        return 'Polizia Stradale';
    }
  }
}