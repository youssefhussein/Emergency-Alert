import 'dart:convert';

class ReverseGeocode {
    Geocoding geocoding;
    String type;
    List<Feature> features;
    List<double> bbox;

    ReverseGeocode({
        required this.geocoding,
        required this.type,
        required this.features,
        required this.bbox,
    });

    factory ReverseGeocode.fromRawJson(String str) => ReverseGeocode.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory ReverseGeocode.fromJson(Map<String, dynamic> json) => ReverseGeocode(
        geocoding: Geocoding.fromJson(json["geocoding"]),
        type: json["type"],
        features: List<Feature>.from(json["features"].map((x) => Feature.fromJson(x))),
        bbox: List<double>.from(json["bbox"].map((x) => x?.toDouble())),
    );

    Map<String, dynamic> toJson() => {
        "geocoding": geocoding.toJson(),
        "type": type,
        "features": List<dynamic>.from(features.map((x) => x.toJson())),
        "bbox": List<dynamic>.from(bbox.map((x) => x)),
    };
}

class Feature {
    FeatureType type;
    Geometry geometry;
    Properties properties;
    List<double>? bbox;

    Feature({
        required this.type,
        required this.geometry,
        required this.properties,
        this.bbox,
    });

    factory Feature.fromRawJson(String str) => Feature.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory Feature.fromJson(Map<String, dynamic> json) => Feature(
        type: featureTypeValues.map[json["type"]]!,
        geometry: Geometry.fromJson(json["geometry"]),
        properties: Properties.fromJson(json["properties"]),
        bbox: json["bbox"] == null ? [] : List<double>.from(json["bbox"]!.map((x) => x?.toDouble())),
    );

    Map<String, dynamic> toJson() => {
        "type": featureTypeValues.reverse[type],
        "geometry": geometry.toJson(),
        "properties": properties.toJson(),
        "bbox": bbox == null ? [] : List<dynamic>.from(bbox!.map((x) => x)),
    };
}

class Geometry {
    GeometryType type;
    List<double> coordinates;

    Geometry({
        required this.type,
        required this.coordinates,
    });

    factory Geometry.fromRawJson(String str) => Geometry.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory Geometry.fromJson(Map<String, dynamic> json) => Geometry(
        type: geometryTypeValues.map[json["type"]]!,
        coordinates: List<double>.from(json["coordinates"].map((x) => x?.toDouble())),
    );

    Map<String, dynamic> toJson() => {
        "type": geometryTypeValues.reverse[type],
        "coordinates": List<dynamic>.from(coordinates.map((x) => x)),
    };
}

enum GeometryType {
    POINT
}

final geometryTypeValues = EnumValues({
    "Point": GeometryType.POINT
});

class Properties {
    String id;
    String gid;
    Layer layer;
    Source source;
    String sourceId;
    CountryCode countryCode;
    String name;
    double confidence;
    double distance;
    Accuracy accuracy;
    Country country;
    CountryGid countryGid;
    CountryA countryA;
    Region region;
    RegionGid regionGid;
    RegionA regionA;
    Continent continent;
    ContinentGid continentGid;
    String label;
    String? street;
    Addendum? addendum;

    Properties({
        required this.id,
        required this.gid,
        required this.layer,
        required this.source,
        required this.sourceId,
        required this.countryCode,
        required this.name,
        required this.confidence,
        required this.distance,
        required this.accuracy,
        required this.country,
        required this.countryGid,
        required this.countryA,
        required this.region,
        required this.regionGid,
        required this.regionA,
        required this.continent,
        required this.continentGid,
        required this.label,
        this.street,
        this.addendum,
    });

    factory Properties.fromRawJson(String str) => Properties.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory Properties.fromJson(Map<String, dynamic> json) => Properties(
        id: json["id"],
        gid: json["gid"],
        layer: layerValues.map[json["layer"]]!,
        source: sourceValues.map[json["source"]]!,
        sourceId: json["source_id"],
        countryCode: countryCodeValues.map[json["country_code"]]!,
        name: json["name"],
        confidence: json["confidence"]?.toDouble(),
        distance: json["distance"]?.toDouble(),
        accuracy: accuracyValues.map[json["accuracy"]]!,
        country: countryValues.map[json["country"]]!,
        countryGid: countryGidValues.map[json["country_gid"]]!,
        countryA: countryAValues.map[json["country_a"]]!,
        region: regionValues.map[json["region"]]!,
        regionGid: regionGidValues.map[json["region_gid"]]!,
        regionA: regionAValues.map[json["region_a"]]!,
        continent: continentValues.map[json["continent"]]!,
        continentGid: continentGidValues.map[json["continent_gid"]]!,
        label: json["label"],
        street: json["street"],
        addendum: json["addendum"] == null ? null : Addendum.fromJson(json["addendum"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "gid": gid,
        "layer": layerValues.reverse[layer],
        "source": sourceValues.reverse[source],
        "source_id": sourceId,
        "country_code": countryCodeValues.reverse[countryCode],
        "name": name,
        "confidence": confidence,
        "distance": distance,
        "accuracy": accuracyValues.reverse[accuracy],
        "country": countryValues.reverse[country],
        "country_gid": countryGidValues.reverse[countryGid],
        "country_a": countryAValues.reverse[countryA],
        "region": regionValues.reverse[region],
        "region_gid": regionGidValues.reverse[regionGid],
        "region_a": regionAValues.reverse[regionA],
        "continent": continentValues.reverse[continent],
        "continent_gid": continentGidValues.reverse[continentGid],
        "label": label,
        "street": street,
        "addendum": addendum?.toJson(),
    };
}

enum Accuracy {
    CENTROID,
    POINT
}

final accuracyValues = EnumValues({
    "centroid": Accuracy.CENTROID,
    "point": Accuracy.POINT
});

class Addendum {
    Geonames geonames;

    Addendum({
        required this.geonames,
    });

    factory Addendum.fromRawJson(String str) => Addendum.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory Addendum.fromJson(Map<String, dynamic> json) => Addendum(
        geonames: Geonames.fromJson(json["geonames"]),
    );

    Map<String, dynamic> toJson() => {
        "geonames": geonames.toJson(),
    };
}

class Geonames {
    String featureCode;

    Geonames({
        required this.featureCode,
    });

    factory Geonames.fromRawJson(String str) => Geonames.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory Geonames.fromJson(Map<String, dynamic> json) => Geonames(
        featureCode: json["feature_code"],
    );

    Map<String, dynamic> toJson() => {
        "feature_code": featureCode,
    };
}

enum Continent {
    AFRICA
}

final continentValues = EnumValues({
    "Africa": Continent.AFRICA
});

enum ContinentGid {
    WHOSONFIRST_CONTINENT_102191573
}

final continentGidValues = EnumValues({
    "whosonfirst:continent:102191573": ContinentGid.WHOSONFIRST_CONTINENT_102191573
});

enum Country {
    EGYPT
}

final countryValues = EnumValues({
    "Egypt": Country.EGYPT
});

enum CountryA {
    EGY
}

final countryAValues = EnumValues({
    "EGY": CountryA.EGY
});

enum CountryCode {
    EG
}

final countryCodeValues = EnumValues({
    "EG": CountryCode.EG
});

enum CountryGid {
    WHOSONFIRST_COUNTRY_85632581
}

final countryGidValues = EnumValues({
    "whosonfirst:country:85632581": CountryGid.WHOSONFIRST_COUNTRY_85632581
});

enum Layer {
    STREET,
    VENUE
}

final layerValues = EnumValues({
    "street": Layer.STREET,
    "venue": Layer.VENUE
});

enum Region {
    CAIRO
}

final regionValues = EnumValues({
    "Cairo": Region.CAIRO
});

enum RegionA {
    QH
}

final regionAValues = EnumValues({
    "QH": RegionA.QH
});

enum RegionGid {
    WHOSONFIRST_REGION_85670999
}

final regionGidValues = EnumValues({
    "whosonfirst:region:85670999": RegionGid.WHOSONFIRST_REGION_85670999
});

enum Source {
    GEONAMES,
    OPENSTREETMAP
}

final sourceValues = EnumValues({
    "geonames": Source.GEONAMES,
    "openstreetmap": Source.OPENSTREETMAP
});

enum FeatureType {
    FEATURE
}

final featureTypeValues = EnumValues({
    "Feature": FeatureType.FEATURE
});

class Geocoding {
    String version;
    String attribution;
    Query query;
    Engine engine;
    int timestamp;

    Geocoding({
        required this.version,
        required this.attribution,
        required this.query,
        required this.engine,
        required this.timestamp,
    });

    factory Geocoding.fromRawJson(String str) => Geocoding.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory Geocoding.fromJson(Map<String, dynamic> json) => Geocoding(
        version: json["version"],
        attribution: json["attribution"],
        query: Query.fromJson(json["query"]),
        engine: Engine.fromJson(json["engine"]),
        timestamp: json["timestamp"],
    );

    Map<String, dynamic> toJson() => {
        "version": version,
        "attribution": attribution,
        "query": query.toJson(),
        "engine": engine.toJson(),
        "timestamp": timestamp,
    };
}

class Engine {
    String name;
    String author;
    String version;

    Engine({
        required this.name,
        required this.author,
        required this.version,
    });

    factory Engine.fromRawJson(String str) => Engine.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory Engine.fromJson(Map<String, dynamic> json) => Engine(
        name: json["name"],
        author: json["author"],
        version: json["version"],
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "author": author,
        "version": version,
    };
}

class Query {
    int size;
    bool private;
    double pointLat;
    double pointLon;
    double boundaryCircleLat;
    double boundaryCircleLon;
    Lang lang;
    int querySize;

    Query({
        required this.size,
        required this.private,
        required this.pointLat,
        required this.pointLon,
        required this.boundaryCircleLat,
        required this.boundaryCircleLon,
        required this.lang,
        required this.querySize,
    });

    factory Query.fromRawJson(String str) => Query.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory Query.fromJson(Map<String, dynamic> json) => Query(
        size: json["size"],
        private: json["private"],
        pointLat: json["point.lat"]?.toDouble(),
        pointLon: json["point.lon"]?.toDouble(),
        boundaryCircleLat: json["boundary.circle.lat"]?.toDouble(),
        boundaryCircleLon: json["boundary.circle.lon"]?.toDouble(),
        lang: Lang.fromJson(json["lang"]),
        querySize: json["querySize"],
    );

    Map<String, dynamic> toJson() => {
        "size": size,
        "private": private,
        "point.lat": pointLat,
        "point.lon": pointLon,
        "boundary.circle.lat": boundaryCircleLat,
        "boundary.circle.lon": boundaryCircleLon,
        "lang": lang.toJson(),
        "querySize": querySize,
    };
}

class Lang {
    String name;
    String iso6391;
    String iso6393;
    String via;
    bool defaulted;

    Lang({
        required this.name,
        required this.iso6391,
        required this.iso6393,
        required this.via,
        required this.defaulted,
    });

    factory Lang.fromRawJson(String str) => Lang.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory Lang.fromJson(Map<String, dynamic> json) => Lang(
        name: json["name"],
        iso6391: json["iso6391"],
        iso6393: json["iso6393"],
        via: json["via"],
        defaulted: json["defaulted"],
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "iso6391": iso6391,
        "iso6393": iso6393,
        "via": via,
        "defaulted": defaulted,
    };
}

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
            reverseMap = map.map((k, v) => MapEntry(v, k));
            return reverseMap;
    }
}
