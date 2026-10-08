import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/repository/accounts_repository_impl.dart';
import '../../../domain/repository/accounts_repository.dart';

part 'accounts_providers.g.dart';

@Riverpod(keepAlive: true)
AccountsRepository accountsRepository(Ref ref) => AccountsRepositoryImpl();
