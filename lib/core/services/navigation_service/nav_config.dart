import 'package:get/get.dart';

abstract class NavigationService {
  Future<T?> navigateTo<T>(String routeName, {Object? arguments});
  Future<void> navigateAndReplace(String routeName, {Object? arguments});
  Future<void> navigateAndReplaceAll(String routeName, {Object? arguments});
  Future<void> navigateAndOffAll(
    String destinationRoute,
    conditionRoute, {
    Object? arguments,
  });
  void goBack<T>({T? result});
  Future<void> goBackUntil(String routeName);
}

class GetxNavigationService implements NavigationService {
  @override
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) async {
    return await Get.toNamed<T>(routeName, arguments: arguments);
  }

  @override
  Future<void> navigateAndReplace(String routeName, {Object? arguments}) async {
    await Get.offNamed(routeName, arguments: arguments);
  }

  @override
  Future<void> navigateAndReplaceAll(
    String routeName, {
    Object? arguments,
  }) async {
    await Get.offAllNamed(routeName, arguments: arguments);
  }

  @override
  void goBack<T>({T? result}) {
    Get.back<T>(result: result);
  }

  @override
  Future<void> goBackUntil(String routeName) async {
    Get.until((route) => route.settings.name == routeName);
  }

  @override
  Future<void> navigateAndOffAll(
    String destinationRoute,
    conditionalRoute, {
    Object? arguments,
  }) async {
    await Get.offNamedUntil(
      destinationRoute,
      (route) => route.settings.name == conditionalRoute,
      arguments: arguments,
    );
  }
}
