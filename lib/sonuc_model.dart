class SonucModel {
  final String model;
  final double ortalama;
  final Map<String, int> sinavSonuclari;

  SonucModel({
    required this.model,
    required this.ortalama,
    required this.sinavSonuclari,
  });

  factory SonucModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> sinavSonuclari = {};
    json.forEach((key, value) {
      if (key != "model" && key != "ortalama") {
        sinavSonuclari[key] = value as int;
      }
    });
    return SonucModel(
      model: json['model'],
      ortalama: json['ortalama'],
      sinavSonuclari: sinavSonuclari,
    );
  }
}
