import 'dart:convert';

SearchResultItem searchResultItemFromJson(String str) => SearchResultItem.fromJson(json.decode(str));

class SearchResultItem {
  SearchResultItem({
    this.errCode,
    this.errMsg,
    this.datas,
  });

  int errCode;
  dynamic errMsg;
  List<Data> datas;

  factory SearchResultItem.fromJson(Map<String, dynamic> json) => SearchResultItem(
    errCode: json["ErrCode"],
    errMsg: json["ErrMsg"],
    datas: List<Data>.from(json["Datas"].map((x) => Data.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "ErrCode": errCode,
    "ErrMsg": errMsg,
    "Datas": List<dynamic>.from(datas.map((x) => x.toJson())),
  };
}

class Data {
  Data({
    this.id,
    this.code,
    this.name,
    this.jp,
    this.category,
    this.categorydesc,
    this.stockmarket,
    this.backcode,
    this.matchCount,
    this.fundBaseInfo,
    this.stockHolder,
    this.ztjjInfo,
  });

  String id;
  String code;
  String name;
  String jp;
  int category;
  String categorydesc;
  String stockmarket;
  String backcode;
  int matchCount;
  FundBaseInfo fundBaseInfo;
  String stockHolder;
  List<dynamic> ztjjInfo;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json["_id"],
    code: json["CODE"],
    name: json["NAME"],
    jp: json["JP"],
    category: json["CATEGORY"],
    categorydesc: json["CATEGORYDESC"],
    stockmarket: json["STOCKMARKET"],
    backcode: json["BACKCODE"],
    matchCount: json["MatchCount"],
    fundBaseInfo: FundBaseInfo.fromJson(json["FundBaseInfo"]),
    stockHolder: json["StockHolder"],
    ztjjInfo: List<dynamic>.from(json["ZTJJInfo"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "CODE": code,
    "NAME": name,
    "JP": jp,
    "CATEGORY": category,
    "CATEGORYDESC": categorydesc,
    "STOCKMARKET": stockmarket,
    "BACKCODE": backcode,
    "MatchCount": matchCount,
    "FundBaseInfo": fundBaseInfo.toJson(),
    "StockHolder": stockHolder,
    "ZTJJInfo": List<dynamic>.from(ztjjInfo.map((x) => x)),
  };
}

class FundBaseInfo {
  FundBaseInfo({
    this.id,
    this.dwjz,
    this.fcode,
    this.fsrq,
    this.ftype,
    this.fundtype,
    this.isbuy,
    this.jjgs,
    this.jjgsbid,
    this.jjgsid,
    this.jjjl,
    this.jjjlid,
    this.minsg,
    this.navurl,
    this.othername,
    this.shortname,
  });

  String id;
  double dwjz;
  String fcode;
  DateTime fsrq;
  String ftype;
  String fundtype;
  String isbuy;
  String jjgs;
  dynamic jjgsbid;
  String jjgsid;
  String jjjl;
  String jjjlid;
  dynamic minsg;
  String navurl;
  String othername;
  String shortname;

  factory FundBaseInfo.fromJson(Map<String, dynamic> json) => FundBaseInfo(
    id: json["_id"],
    dwjz: json["DWJZ"].toDouble(),
    fcode: json["FCODE"],
    fsrq: DateTime.parse(json["FSRQ"]),
    ftype: json["FTYPE"],
    fundtype: json["FUNDTYPE"],
    isbuy: json["ISBUY"],
    jjgs: json["JJGS"],
    jjgsbid: json["JJGSBID"],
    jjgsid: json["JJGSID"],
    jjjl: json["JJJL"],
    jjjlid: json["JJJLID"],
    minsg: json["MINSG"],
    navurl: json["NAVURL"],
    othername: json["OTHERNAME"],
    shortname: json["SHORTNAME"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "DWJZ": dwjz,
    "FCODE": fcode,
    "FSRQ": "${fsrq.year.toString().padLeft(4, '0')}-${fsrq.month.toString().padLeft(2, '0')}-${fsrq.day.toString().padLeft(2, '0')}",
    "FTYPE": ftype,
    "FUNDTYPE": fundtype,
    "ISBUY": isbuy,
    "JJGS": jjgs,
    "JJGSBID": jjgsbid,
    "JJGSID": jjgsid,
    "JJJL": jjjl,
    "JJJLID": jjjlid,
    "MINSG": minsg,
    "NAVURL": navurl,
    "OTHERNAME": othername,
    "SHORTNAME": shortname,
  };
}
