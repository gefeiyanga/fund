// To parse this JSON data, do
//
//     final crypto = cryptoFromJson(jsonString);

import 'dart:convert';

Crypto cryptoFromJson(String str) => Crypto.fromJson(json.decode(str));

String cryptoToJson(Crypto data) => json.encode(data.toJson());

class Crypto {
  Crypto({
    this.data,
  });

  CryptoData data;

  factory Crypto.fromJson(Map<String, dynamic> json) => Crypto(
        data: CryptoData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "data": data.toJson(),
      };
}

class CryptoData {
  CryptoData({
    this.base,
    this.currency,
    this.amount,
  });

  String base;
  String currency;
  String amount;

  factory CryptoData.fromJson(Map<String, dynamic> json) => CryptoData(
        base: json["base"],
        currency: json["currency"],
        amount: json["amount"],
      );

  Map<String, dynamic> toJson() => {
        "base": base,
        "currency": currency,
        "amount": amount,
      };
}
