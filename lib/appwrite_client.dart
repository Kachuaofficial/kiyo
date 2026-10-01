import 'package:appwrite/appwrite.dart';

final client = Client()
  .setEndpoint('https://fra.cloud.appwrite.io/v1')
  .setProject('6abd21030012f7cad291');

final account = Account(client);
final databases = Databases(client);
final tablesDB = TablesDB(client);
final storage = Storage(client);
