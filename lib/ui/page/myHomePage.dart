import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fundapp/common/funs.dart';
import 'package:fundapp/model/ownerFund.dart';
import 'package:fundapp/ui/widget/searchBar.dart';
import 'package:fundapp/common/api.dart';
import 'package:fundapp/model/searchResult.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool isShowSearchList = false;
  List<Data> searchResultList;
  List lastFundCodeList;
  List<OwnerFund> ownerFundList;
  List<String> ownerFundData;
  int otherHeight = 0;
  TextEditingController _netValueController = new TextEditingController();
  TextEditingController _shareController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      int height = 52 + MediaQueryData.fromWindow(window).padding.top.toInt() + kToolbarHeight.toInt();
      setState(() {
        otherHeight = height;
      });
    });
    update(true);
    if((DateTime.now().hour > 9 || DateTime.now().hour == 9 && DateTime.now().minute>=30) && DateTime.now().hour <=14) {
      Timer countdownTimer =  new Timer.periodic(new Duration(seconds: 5), (timer) {
        update(true);
      });
    }
  }

  // true--initState  false--other
  update (isInit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(isInit) {
      setState(() {
        lastFundCodeList = prefs.getStringList('fundCodeList')??[];
      });
      setState(() {
        ownerFundData = prefs.getStringList('ownerFundData')??[];
      });
    }
    List<OwnerFund> tempArr = [];
    await Future.forEach(lastFundCodeList, (code) async {
      var result = await Api().getFundDetail(code);
      tempArr.add(result);
    });
    setState(() {
      ownerFundList = tempArr;
    });
  }

  toggleSearchList (text) {
    if(text.length > 0 && isShowSearchList == false) {
      setState(() {
        isShowSearchList = true;
      });
    } else if((text.length == 0 || text==null) && isShowSearchList == true) {
      setState(() {
        isShowSearchList = false;
      });
    }
  }

  search (searchValue) async {
    List<Data> data = await Api().searchFund(searchValue.toString());
    setState(() {
      searchResultList = data;
    });
  }

  addOwner (code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> oldFundCodeList = prefs.getStringList('fundCodeList')??[];
    if(!oldFundCodeList.contains(code.toString())) {
      oldFundCodeList.add(code.toString());
      prefs.setStringList('fundCodeList', oldFundCodeList);
      setState(() {
        lastFundCodeList = prefs.getStringList('fundCodeList')??[];
      });
      update(false);
    }
  }

  toggleOwner (code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> oldFundCodeList = prefs.getStringList('fundCodeList')??[];
    if(oldFundCodeList.contains(code.toString())) {
      oldFundCodeList.remove(code.toString());
      prefs.setStringList('fundCodeList', oldFundCodeList);
      setState(() {
        lastFundCodeList = prefs.getStringList('fundCodeList')??[];
      });
      update(false);
    }
  }

  deleteAllOwner () async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('fundCodeList', []);
    prefs.setStringList('ownerFundData', []);
    update(true);
  }

  ShowNetValueAndShareModal (BuildContext context, code) async {
    // set up the button
    Widget cancelButton = FlatButton(
      child: Text("取消"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget okButton = FlatButton(
      child: Text("确认"),
      onPressed: () async {
        if(_netValueController.text==null||_netValueController.text.trim().toString().length==0
        ||_shareController.text==null||_shareController.text.trim().toString().length==0) {
          return showToast('请先填写当前净值和持有份额');
        }
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> oldOwnerFundDataList = prefs.getStringList('ownerFundData')??[];
        bool flag = true;
        for (int i=0; i<oldOwnerFundDataList.length; i++) {
          if(code.toString() == oldOwnerFundDataList[i].split('-~-')[0]) {
            flag = false;
            oldOwnerFundDataList[i] = code.toString() + '-~-' + _netValueController.text + '-~-' + _shareController.text;
            break;
          }
        }
        if(flag) {
          String objData = code.toString() + '-~-' + _netValueController.text + '-~-' + _shareController.text;
          oldOwnerFundDataList.add(objData);
        }
        prefs.setStringList('ownerFundData', oldOwnerFundDataList);
//        print(prefs.getStringList('ownerFundData'));
        setState(() {
          ownerFundData = prefs.getStringList('ownerFundData');
        });
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("持有"),
      content: Container(
        height: 140,
        width: 280,
        child:Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _netValueController,
                inputFormatters: [
                  // 只能输入数字
                  WhitelistingTextInputFormatter(RegExp(
                      "[.]|[0-9]")),
                ],
                decoration: InputDecoration(
                  labelText: '当前净值',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0x19000000)),
                  ),
                ),
                  // 校验用户名（不能为空）
              ),
              TextFormField(
                controller: _shareController,
                inputFormatters: [
                  // 只能输入数字
                  WhitelistingTextInputFormatter(RegExp(
                      "[.]|[0-9]")),
                ],
                decoration: InputDecoration(
                  labelText: '持有份额',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0x19000000)),
                  ),
                ),
              ),
            ],
          ),
        ),

      ),
      actions: [
        cancelButton,
        okButton,
      ],
    );


    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> oldOwnerFundDataList = prefs.getStringList('ownerFundData')??[];
    bool flag = true;
    oldOwnerFundDataList.forEach((e) {
//      print(code);
//      print(e);
//      print(e.split('-~-')[0]);
      if(code.toString() == e.split('-~-')[0]) {
        _netValueController.text = e.split('-~-')[1];
        _shareController.text = e.split('-~-')[2];
        flag = false;
      }
    });
    if(flag) {
      _netValueController.text = '';
      _shareController.text = '';
    }
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

    costGains (OwnerFund item) {

      double shareCount = 0.0;
      ownerFundData.forEach((e) {
        if(item.fundcode.toString() == e.split('-~-')[0]) {
          shareCount = double.parse(e.split('-~-')[2]);
        }
      });
      return ((double.parse(item.dwjz) - double.parse(item.dwjz) / (1 + double.parse(item.gszzl) * 0.01)) * shareCount).toStringAsFixed(2);
    }

  costItemAllGains (OwnerFund item) {

    double netValue = 0.0;
    double shareCount = 0.0;
    ownerFundData.forEach((e) {
      if(item.fundcode.toString() == e.split('-~-')[0]) {
        netValue = double.parse(e.split('-~-')[1]);
        shareCount = double.parse(e.split('-~-')[2]);
      }
    });
    bool flag = false;
    try {
      int yy = int.parse(item.gztime.substring(0, 10).split('-')[0]);
      int mm = int.parse(item.gztime.substring(0, 10).split('-')[1]);
      int dd = int.parse(item.gztime.substring(0, 10).split('-')[2]);
      var thatDay = DateTime(yy, mm, dd, 24, 00, 00);
//      print('item.dwjz: ${DateTime(yy, mm, dd, 24, 00, 00)}');
//      print(DateTime.now().isAfter(thatDay));
      flag = DateTime.now().isAfter(thatDay);
    } catch (e) {
      print(e);
    }

    return flag ? ((double.parse(item.gsz) - netValue) * shareCount).toStringAsFixed(2) : ((double.parse(item.dwjz) - netValue) * shareCount).toStringAsFixed(2);
  }

  calculateMoney(OwnerFund item) {
    double shareCount = 0.0;
    bool flag = false;
    ownerFundData.forEach((e) {
      if(item.fundcode.toString() == e.split('-~-')[0]) {
        shareCount = double.parse(e.split('-~-')[2]);
      }
    });
    try {
      int yy = int.parse(item.gztime.substring(0, 10).split('-')[0]);
      int mm = int.parse(item.gztime.substring(0, 10).split('-')[1]);
      int dd = int.parse(item.gztime.substring(0, 10).split('-')[2]);
      var thatDay = DateTime(yy, mm, dd, 24, 00, 00);
//      print('item.dwjz: ${DateTime(yy, mm, dd, 24, 00, 00)}');
//      print(DateTime.now().isAfter(thatDay));
      flag = DateTime.now().isAfter(thatDay);
    } catch (e) {
      print(e);
    }
    String sum = flag ? (double.parse(item.gsz) * shareCount).toStringAsFixed(2) : (double.parse(item.dwjz) * shareCount).toStringAsFixed(2);
    return sum;
  }

  @override
  Widget build(BuildContext context) {
//    print('lastFundCodeList: $lastFundCodeList');
//    print('ownerFundList: $ownerFundList');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
          ),
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              SearchBar(toggleSearchList, search),
              Container(
                margin: EdgeInsets.only(top: 52),
                padding: EdgeInsets.only(top: 8,left: 14, right: 14),
                height: MediaQuery.of(context).size.height-otherHeight,
                child: ownerFundList!=null&&ownerFundList.length>0 ? ListView.separated(
                  separatorBuilder: (BuildContext context, int index) {
                    return Divider(
                      height: 6,
                      color: Colors.black12,
                    );
                  },
                  itemCount: ownerFundList.length+1,
                  itemBuilder: (context, index) {
                    return index<ownerFundList.length ?
                      InkWell(
                        onTap: ()=>ShowNetValueAndShareModal(context, ownerFundList[index]!=null ? ownerFundList[index].fundcode : '--'),
                        child: Container(
                          padding: EdgeInsets.only(top: 2, bottom: 2),
                          height: 104,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width-37-70,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            child: Text(ownerFundList[index]!=null ? ownerFundList[index].name : '未知',
                                              style: TextStyle(color: Colors.black, fontSize: 14),),
                                          ),
                                          Container(
                                            child: Text(ownerFundList[index]!=null ? ownerFundList[index].fundcode : '未知',
                                              style: TextStyle(color: Colors.black, fontSize: 14),),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width-37-70,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            child: Text('估算净值',
                                              style: TextStyle(color: Colors.black, fontSize: 14),),
                                          ),
                                          Container(
                                            child: Text(ownerFundList[index]!=null ? '${ownerFundList[index].gszzl.toString()}% (${double.parse(ownerFundList[index].gsz).toStringAsFixed(1)})' : '未知',
                                              style: TextStyle(color: Colors.black, fontSize: 14),),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width-37-70,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            child: Text('预估收益',
                                              style: TextStyle(color: Colors.black, fontSize: 14),),
                                          ),
                                          Container(
                                            child: Text(ownerFundList[index]!=null ? costGains(ownerFundList[index]) : '未知',
                                              style: TextStyle(color: Colors.black, fontSize: 14),),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width-37-70,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            child: Text('累计收益',
                                              style: TextStyle(color: Colors.black, fontSize: 14),),
                                          ),
                                          Container(
                                            child: Text(ownerFundList[index]!=null ? costItemAllGains(ownerFundList[index]) : '未知',
                                              style: TextStyle(color: Colors.black, fontSize: 14),),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width-37-70,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            child: Text('持有金额',
                                              style: TextStyle(color: Colors.black, fontSize: 14),),
                                          ),
                                          Container(
                                            child: Text(ownerFundList[index]!=null ? calculateMoney(ownerFundList[index]) : '未知',
                                              style: TextStyle(color: Colors.black, fontSize: 14),),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: ()=>toggleOwner(ownerFundList[index].fundcode),
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 60,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(8), ),
                                      gradient: LinearGradient(
                                          colors: [
                                            Colors.orange,
                                            Color(0xFFfc5531),
                                          ],
                                          begin: Alignment.bottomLeft,
                                          end: Alignment.topRight)),
                                  child: Text('已持有', style: TextStyle(color: Colors.white, fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                        )
                      )
                    : InkWell(
                        onTap: deleteAllOwner,
                        child: Container(
                          alignment: Alignment.center,
                          margin: EdgeInsets.only(top: 24),
                          height: 56,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(8), ),
                              gradient: LinearGradient(
                                  colors: [
                                    Colors.orange,
                                    Color(0xFFfc5531),
                                  ],
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight)),
                          child: Text('清除所有', style: TextStyle(color: Colors.white, fontSize: 18),),
                        ),
                      );

                  },
                ) :
                Center(
                  child: Text('你还没有添加持有的🐔嗷！'),
                )
              ),
              Positioned(
                top: 52,
                left: 0,
                right: 0,
                child: isShowSearchList ? Container(
                  height: 160,
                  color: Colors.deepOrange,
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.only(left: 18.5, right: 18.5),
                  child: searchResultList!=null&&searchResultList.length>0 ? ListView.separated(
                      itemCount: searchResultList.length,
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider(
                          height: 6,
                          color: Color(0xFFEEEEEE),
                        );
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          padding: EdgeInsets.only(top: 2, bottom: 2),
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width-37-60,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            child: Text(searchResultList[index].name,
                                              style: TextStyle(color: Colors.white, fontSize: 14),),
                                          ),
                                          Container(
                                            child: Text(searchResultList[index].fundBaseInfo.dwjz.toString(),
                                              style: TextStyle(color: Colors.white, fontSize: 14),),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width-37-60,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            child: Text(searchResultList[index].code,
                                              style: TextStyle(color: Colors.white, fontSize: 14),),
                                          ),
                                          Container(
                                            child: Text('单位净值',
                                              style: TextStyle(color: Colors.white, fontSize: 14),),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                alignment: Alignment.center,
                                child: lastFundCodeList!=null&&lastFundCodeList.contains(searchResultList[index].code.toString()) ?
                                Text('已持有', style: TextStyle(color: Colors.white, fontSize: 14)):
                                IconButton(
                                  onPressed: ()=>addOwner(searchResultList[index].code),
                                  icon: Icon(Icons.add, size: 24, color: Colors.white,),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                  ) :
                  Center(
                    child: Text('没有搜到相关的🐔嗷！', style: TextStyle(color: Colors.white, fontSize: 14),),
                  ),
                ) : Text(''),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
