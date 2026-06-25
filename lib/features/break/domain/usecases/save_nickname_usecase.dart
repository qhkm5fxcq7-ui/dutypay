import '../constants/break_constants.dart';
import '../models/break_identity.dart';
import '../repositories/break_identity_repository.dart';

class SaveNicknameUseCase {
  final BreakIdentityRepository repository;

  const SaveNicknameUseCase(this.repository);

  Future<BreakIdentity> execute(String nickname) {
    final cleaned = nickname.trim();

    if (cleaned.length < BreakConstants.minNicknameLength) {
      throw ArgumentError(
        'Il nickname deve avere almeno ${BreakConstants.minNicknameLength} caratteri',
      );
    }

    if (cleaned.length > BreakConstants.maxNicknameLength) {
      throw ArgumentError(
        'Il nickname non può superare ${BreakConstants.maxNicknameLength} caratteri',
      );
    }

    return repository.saveNickname(cleaned);
  }
}
