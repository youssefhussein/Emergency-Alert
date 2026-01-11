import 'dart:convert';

class ReverseGeocode {
  String? placeId;
  String? licence;
  String? osmType;
  String? osmId;
  String? lat;
  String? lon;
  String? displayName;
  Address? address;
  List<String>? boundingbox;

  ReverseGeocode({
    this.placeId,
    this.licence,
    this.osmType,
    this.osmId,
    this.lat,
    this.lon,
    this.displayName,
    this.address,
    this.boundingbox,
  });

  factory ReverseGeocode.fromRawJson(String str) =>
      ReverseGeocode.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ReverseGeocode.fromJson(Map<String, dynamic> json) => ReverseGeocode(
    placeId: json["place_id"],
    licence: json["licence"],
    osmType: json["osm_type"],
    osmId: json["osm_id"],
    lat: json["lat"],
    lon: json["lon"],
    displayName: json["display_name"],
    address: json["address"] != null ? Address.fromJson(json["address"]) : null,
    boundingbox: json["boundingbox"] != null
        ? List<String>.from(json["boundingbox"].map((x) => x))
        : null,
  );

  Map<String, dynamic> toJson() => {
    "place_id": placeId,
    "licence": licence,
    "osm_type": osmType,
    "osm_id": osmId,
    "lat": lat,
    "lon": lon,
    "display_name": displayName,
    "address": address?.toJson(),
    "boundingbox": boundingbox,
  };
}

class Address {
  String? attraction;
  String? houseNumber;
  String? road;
  String? neighbourhood;
  String? suburb;
  String? county;
  String? city;
  String? state;
  String? postcode;
  String? country;
  String? countryCode;

  Address({
    this.attraction,
    this.houseNumber,
    this.road,
    this.neighbourhood,
    this.suburb,
    this.county,
    this.city,
    this.state,
    this.postcode,
    this.country,
    this.countryCode,
  });

  factory Address.fromRawJson(String str) => Address.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    attraction: json["attraction"],
    houseNumber: json["house_number"],
    road: json["road"],
    neighbourhood: json["neighbourhood"],
    suburb: json["suburb"],
    county: json["county"],
    city: json["city"],
    state: json["state"],
    postcode: json["postcode"],
    country: json["country"],
    countryCode: json["country_code"],
  );

  Map<String, dynamic> toJson() => {
    "attraction": attraction,
    "house_number": houseNumber,
    "road": road,
    "neighbourhood": neighbourhood,
    "suburb": suburb,
    "county": county,
    "city": city,
    "state": state,
    "postcode": postcode,
    "country": country,
    "country_code": countryCode,
  };
}
