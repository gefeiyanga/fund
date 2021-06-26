import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fundapp/common/funs.dart';
import 'package:fundapp/model/searchResult.dart';
import 'package:fundapp/model/ownerFund.dart';
import 'package:flutter/services.dart';

class Api {
  // 在网络请求过程中可能需要使用当前context信息，比如在请求失败时
  // 打开一个新路由，而打开新路由需要context信息

  Api([this.context]) {
    _options = Options(extra: {
      "context": context,
      "followRedirects": false,
      "validateStatus": (status) { return status < 500; }
    });
  }

  BuildContext context;
  Options _options;

  static Dio dio = new Dio(BaseOptions(
    baseUrl: '',
  ));

  static void init() {
  }

  // 基金搜索接口
  Future<List<Data>> searchFund(key) async {

    try {
      int now = DateTime.now().millisecondsSinceEpoch;
      var r = await dio.get(
        'http://fundsuggest.eastmoney.com/FundSearch/api/FundSearchAPI.ashx?callback=&m=1&key=$key&_=$now',
      );
      var result = searchResultItemFromJson(r.toString());
      if (result!=null&&result.errCode==0) {

        return result.datas;
      } else {
        showToast('SOMETHING ERROR!');
        return [];
      }
    } catch (e) {
      print('e: $e}');
    }
  }

  // 持有基金列表
  Future<OwnerFund> getFundDetail(code) async {

    try {
      int now = DateTime.now().millisecondsSinceEpoch;
      var r = await dio.get(
        'http://fundgz.1234567.com.cn/js/$code.js?rt=$now',
      );
      if(RegExp(r"jsonpgz\((.+)\)").hasMatch(r.toString())) {
        var result = RegExp(r"jsonpgz\((.+)\)").firstMatch(r.toString())[1];
        return ownerFundFromJson(result);
      } else {
        showToast('SOMETHING ERROR!');
      }
    } catch (e) {
      print('e: $e}');
    }
  }


}































