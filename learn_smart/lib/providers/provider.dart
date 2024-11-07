import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../view_models/auth_view_model.dart';
import '../models/datastore.dart';

class AppProviders {
  static List<SingleChildWidget> providers() {
    return [
      // AuthViewModel provides the User and manages authentication state
      ChangeNotifierProvider(create: (_) => AuthViewModel()),

      // DataStoreProvider that handles all data storage and management
      ChangeNotifierProxyProvider<AuthViewModel, DataStore>(
        create: (_) => DataStore(),
        update: (context, auth, dataStore) {
          dataStore?.updateToken(auth.user.token);
          return dataStore ?? DataStore();
        },
      ),
    ];
  }
}
