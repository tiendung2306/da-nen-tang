import 'package:flutter_boilerplate/services/api/api_service.dart'; // Corrected path
import 'package:get_it/get_it.dart';

// Note: UserController might need to be created or updated if it depends on the old ApiService.
// import 'network/api_controller/user_controller.dart'; 

GetIt locator = GetIt.instance;

void setupLocator() {
  // Register the singleton for our correct ApiService
  locator.registerSingleton<ApiService>(ApiService());
  
  // Temporarily commenting out UserController as it might be from an old structure.
  // If you need it, we should review its content to ensure compatibility.
  // locator.registerLazySingleton(() => UserController()); 
}
