import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/datasources/firestore_break_datasource.dart';
import '../data/datasources/local_break_identity_datasource.dart';
import '../data/repositories/break_identity_repository_impl.dart';
import '../data/repositories/firestore_break_room_repository.dart';
import '../data/services/break_code_generator.dart';
import '../domain/usecases/create_break_room_usecase.dart';
import '../domain/usecases/get_local_identity_usecase.dart';
import '../domain/usecases/join_break_room_usecase.dart';
import '../domain/usecases/reset_break_round_usecase.dart';
import '../domain/usecases/save_nickname_usecase.dart';
import '../domain/usecases/set_break_ready_usecase.dart';
import '../domain/usecases/start_break_round_usecase.dart';
import '../domain/usecases/watch_break_participants_usecase.dart';
import '../domain/usecases/watch_break_room_usecase.dart';
import '../infrastructure/firestore_break_paths.dart';

class BreakDependencies {
  BreakDependencies._();

  static final BreakDependencies instance = BreakDependencies._();

  late final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late final FirestoreBreakPaths firestorePaths = FirestoreBreakPaths(
    firestore,
  );

  late final FirestoreBreakDatasource firestoreDatasource =
      FirestoreBreakDatasource(
    firestorePaths,
  );

  late final LocalBreakIdentityDatasource localIdentityDatasource =
      const LocalBreakIdentityDatasource();

  late final BreakIdentityRepositoryImpl identityRepository =
      BreakIdentityRepositoryImpl(
    localIdentityDatasource,
  );

  late final BreakCodeGenerator codeGenerator = BreakCodeGenerator();

  late final FirestoreBreakRoomRepository roomRepository =
      FirestoreBreakRoomRepository(
    datasource: firestoreDatasource,
    identityRepository: identityRepository,
    codeGenerator: codeGenerator,
  );

  late final CreateBreakRoomUseCase createRoomUseCase =
      CreateBreakRoomUseCase(roomRepository);

  late final JoinBreakRoomUseCase joinRoomUseCase =
      JoinBreakRoomUseCase(roomRepository);

  late final WatchBreakRoomUseCase watchRoomUseCase =
      WatchBreakRoomUseCase(roomRepository);

  late final WatchBreakParticipantsUseCase watchParticipantsUseCase =
      WatchBreakParticipantsUseCase(roomRepository);

  late final SetBreakReadyUseCase setReadyUseCase =
      SetBreakReadyUseCase(roomRepository);

  late final StartBreakRoundUseCase startRoundUseCase =
      StartBreakRoundUseCase(roomRepository);

  late final ResetBreakRoundUseCase resetRoundUseCase =
      ResetBreakRoundUseCase(roomRepository);

  late final GetLocalIdentityUseCase getLocalIdentityUseCase =
      GetLocalIdentityUseCase(identityRepository);

  late final SaveNicknameUseCase saveNicknameUseCase =
      SaveNicknameUseCase(identityRepository);
}
