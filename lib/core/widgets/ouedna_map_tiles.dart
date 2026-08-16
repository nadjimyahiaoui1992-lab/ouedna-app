import 'package:flutter_map/flutter_map.dart';

/// Shared production-safe tile configuration for all Ouedna maps.
///
/// OSM remains the primary source. A second public OSM raster endpoint is used
/// as a bounded fallback for transient tile failures, while satellite mode
/// falls back to the standard map instead of rendering a blank/gray canvas.
class OuednaMapTiles {
  OuednaMapTiles._();

  static const packageName = 'com.ouedna.app.v2';
  static const _standardUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _standardFallbackUrl =
      'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _satelliteUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const _satelliteFallbackUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static TileLayer standard() => TileLayer(
        urlTemplate: _standardUrl,
        fallbackUrl: _standardFallbackUrl,
        userAgentPackageName: packageName,
        minZoom: 2,
        maxZoom: 19,
        maxNativeZoom: 19,
        keepBuffer: 1,
        panBuffer: 1,
        tileDisplay: const TileDisplay.instantaneous(),
        evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
      );

  static TileLayer satellite() => TileLayer(
        urlTemplate: _satelliteUrl,
        fallbackUrl: _satelliteFallbackUrl,
        userAgentPackageName: packageName,
        minZoom: 2,
        maxZoom: 19,
        maxNativeZoom: 19,
        keepBuffer: 1,
        panBuffer: 1,
        tileDisplay: const TileDisplay.instantaneous(),
        evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
      );
}
