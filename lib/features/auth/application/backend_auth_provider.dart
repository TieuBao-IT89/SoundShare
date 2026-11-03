import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_api_service.dart';

final backendCurrentUserProvider =
    StateProvider<AsyncValue<BackendCurrentUser?>>(
      (ref) => const AsyncValue.data(null),
    );
