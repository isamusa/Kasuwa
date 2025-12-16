import 'dart:async';
import 'package:app_links/app_links.dart';

// --- Define the types of navigation events our app can handle ---
abstract class NavigationEvent {}

class ProductNavigationEvent extends NavigationEvent {
  final int productId;
  ProductNavigationEvent(this.productId);
}

class ShopNavigationEvent extends NavigationEvent {
  final String shopSlug;
  ShopNavigationEvent(this.shopSlug);
}

// --- The Service ---
class DeepLinkService {
  final _appLinks = AppLinks();

  // A stream controller to broadcast navigation events to the rest of the app.
  final StreamController<NavigationEvent> _navEventsController =
      StreamController<NavigationEvent>.broadcast();

  // A public stream that the UI can listen to.
  Stream<NavigationEvent> get navigationEvents => _navEventsController.stream;

  // This method is for links that come in while the app is running.
  void init() {
    _appLinks.uriLinkStream.listen((uri) {
      print('Received deep link while running: $uri');
      _parseAndDispatch(uri);
    });
  }

  // This method is for the link that opened the app from a cold state.
  Future<NavigationEvent?> getInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        print('Initial deep link found: $initialUri');
        return _parseUri(initialUri);
      }
    } catch (e) {
      print('Failed to get initial deep link: $e');
    }
    return null;
  }

  NavigationEvent? _parseUri(Uri uri) {
    if (uri.scheme != 'kasuwa') return null;

    if (uri.host == 'product' && uri.pathSegments.isNotEmpty) {
      final productId = int.tryParse(uri.pathSegments.first);
      if (productId != null) {
        return ProductNavigationEvent(productId);
      }
    } else if (uri.host == 'shop' && uri.pathSegments.isNotEmpty) {
      final shopSlug = uri.pathSegments.first;
      return ShopNavigationEvent(shopSlug);
    }
    return null;
  }

  void _parseAndDispatch(Uri uri) {
    final event = _parseUri(uri);
    if (event != null) {
      _navEventsController.add(event);
    }
  }

  void dispose() {
    _navEventsController.close();
  }
}
