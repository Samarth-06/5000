// DEPRECATED: This service has been replaced by Sat2FarmApiService.
// Kept as a stub for backward compatibility. All API calls now go through
// sat2farm_api_service.dart using https://badal023-testapi.hf.space/

class AgroApiService {
  Future<String?> createPolygon({
    required String name,
    required double lat,
    required double lng,
  }) async {
    return null; // Now handled by Sat2FarmApiService.addPolygon()
  }

  Future<Map<String, dynamic>?> fetchNdvi(String polygonId) async {
    return null; // Now handled by Sat2FarmApiService.getVegetationData()
  }
}
