import '../models/break_identity.dart';
import '../repositories/break_identity_repository.dart';

class GetLocalIdentityUseCase {
  final BreakIdentityRepository repository;

  const GetLocalIdentityUseCase(this.repository);

  Future<BreakIdentity> execute() {
    return repository.getOrCreateIdentity();
  }
}
