import 'dart:js_interop';

// ===== Places AutocompleteSuggestion (New API) =====

@JS('google.maps.places.AutocompleteSuggestion')
extension type JsAutocompleteSuggestion._(JSObject _) implements JSObject {
  @JS('fetchAutocompleteSuggestions')
  external static JSPromise<JsSuggestionsResponse>
      fetchAutocompleteSuggestions(JSObject request);
}

@JS()
extension type JsSuggestionsResponse._(JSObject _) implements JSObject {
  external JSArray<JsSuggestion> get suggestions;
}

@JS()
extension type JsSuggestion._(JSObject _) implements JSObject {
  external JsPlacePrediction get placePrediction;
}

@JS()
extension type JsPlacePrediction._(JSObject _) implements JSObject {
  external String get placeId;
  external JsFormattableText get text;
}

@JS()
extension type JsFormattableText._(JSObject _) implements JSObject {
  external String get text;
  external JSArray<JsStringRange> get matches;
}

@JS()
extension type JsStringRange._(JSObject _) implements JSObject {
  external int? get offset;
  external int? get length;
}

// ===== Geocoder =====

@JS('google.maps.Geocoder')
extension type JsGeocoder._(JSObject _) implements JSObject {
  external JsGeocoder();
  external JSPromise<JsGeocoderResponse> geocode(JSObject request);
}

@JS()
extension type JsGeocoderResponse._(JSObject _) implements JSObject {
  external JSArray<JsGeocoderResult> get results;
}

@JS()
extension type JsGeocoderResult._(JSObject _) implements JSObject {
  @JS('formatted_address')
  external String get formattedAddress;
  external JsGeometry get geometry;
  @JS('place_id')
  external String? get placeId;
  @JS('address_components')
  external JSArray<JsAddressComponent>? get addressComponents;
}

@JS()
extension type JsAddressComponent._(JSObject _) implements JSObject {
  @JS('long_name')
  external String get longName;
  @JS('short_name')
  external String get shortName;
  external JSArray<JSString> get types;
}

@JS()
extension type JsGeometry._(JSObject _) implements JSObject {
  external JsLatLng get location;
}

@JS()
extension type JsLatLng._(JSObject _) implements JSObject {
  external double lat();
  external double lng();
}

// ===== Directions =====

@JS('google.maps.DirectionsService')
extension type JsDirectionsSvc._(JSObject _) implements JSObject {
  external JsDirectionsSvc();
  external JSPromise<JsDirectionsResult> route(JSObject request);
}

@JS()
extension type JsDirectionsResult._(JSObject _) implements JSObject {
  external JSArray<JsDirectionsRoute> get routes;
}

@JS()
extension type JsDirectionsRoute._(JSObject _) implements JSObject {
  @JS('overview_path')
  external JSArray<JsLatLng> get overviewPath;
}
