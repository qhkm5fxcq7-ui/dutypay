import '../../domain/models/break_identity.dart';
import '../../domain/repositories/break_identity_repository.dart';
import '../datasources/local_break_identity_datasource.dart';

class BreakIdentityRepositoryImpl implements BreakIdentityRepository {
  final LocalBreakIdentityDatasource datasource;

  const BreakIdentityRepositoryImpl(this.datasource);

  @override
  Future<BreakIdentity> getOrCreateIdentity() {
    return datasource.getOrCreateIdentity();
  }

  @override
  Future<BreakIdentity> saveNickname(String nickname) {
    return datasource.saveNickname(nickname);
  }
}
