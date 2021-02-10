import 'dart:convert';

OwnerFund ownerFundFromJson(String str) => OwnerFund.fromJson(json.decode(str));

class OwnerFund {
  OwnerFund({
    this.fundcode,
    this.name,
    this.jzrq,
    this.dwjz,
    this.gsz,
    this.gszzl,
    this.gztime,
  });

  String fundcode;
  String name;
  DateTime jzrq;
  String dwjz;
  String gsz;
  String gszzl;
  String gztime;

  factory OwnerFund.fromJson(Map<String, dynamic> json) => OwnerFund(
    fundcode: json["fundcode"],
    name: json["name"],
    jzrq: DateTime.parse(json["jzrq"]),
    dwjz: json["dwjz"],
    gsz: json["gsz"],
    gszzl: json["gszzl"],
    gztime: json["gztime"],
  );

  Map<String, dynamic> toJson() => {
    "fundcode": fundcode,
    "name": name,
    "jzrq": "${jzrq.year.toString().padLeft(4, '0')}-${jzrq.month.toString().padLeft(2, '0')}-${jzrq.day.toString().padLeft(2, '0')}",
    "dwjz": dwjz,
    "gsz": gsz,
    "gszzl": gszzl,
    "gztime": gztime,
  };
}
