import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/services.dart';
import 'package:fundapp/model/ownerFund.dart';
import 'package:fundapp/model/searchResult.dart';
import 'package:fundapp/model/crypto.dart';
import 'package:fundapp/common/funs.dart';
import 'package:fundapp/common/api.dart';
import 'package:fundapp/ui/widget/searchBar.dart';

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
  List<String> cryptoList = ['BTC', 'ETH', 'DOGE'];
  List<String> ownerFundData;
  List<String> ownerCryptoData = ['0.0', '0.0', '0.0'];
  List<bool> _isOpen = [false, false];
  int otherHeight = 0;
  TextEditingController _netValueController = new TextEditingController();
  TextEditingController _shareController = new TextEditingController();
  TextEditingController _cryptoCount = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      int height = 204 +
          MediaQueryData.fromWindow(window).padding.top.toInt() +
          kToolbarHeight.toInt();
      setState(() {
        otherHeight = height;
      });
    });
    update(true);
    if ((DateTime.now().hour > 9 ||
            (DateTime.now().hour == 9 && DateTime.now().minute >= 30)) &&
        DateTime.now().hour <= 14 &&
        DateTime.now().weekday <= 5) {
      Timer.periodic(new Duration(seconds: 5), (timer) {
        update(true);
        if (!((DateTime.now().hour > 9 ||
                (DateTime.now().hour == 9 && DateTime.now().minute >= 30)) &&
            DateTime.now().hour <= 14 &&
            DateTime.now().weekday <= 5)) {
          timer.cancel();
        }
      });
    }
    (() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> oldOwnerCryptoData = prefs.getStringList('ownerCryptoData');
      if (oldOwnerCryptoData == null) {
        prefs.setStringList('ownerCryptoData', ['0.0', '0.0', '0.0']);
      }
      setState(() {
        ownerCryptoData = oldOwnerCryptoData ?? ['0.0', '0.0', '0.0'];
      });
    })();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _netValueController.dispose();
    _shareController.dispose();
    _cryptoCount.dispose();
  }

  Stream<Crypto> getCryptoPrice(index) async* {
    if (index == 0) {
      yield* Stream.periodic(Duration(seconds: 1), (_) {
        return Api().getCryptoPrice(cryptoList[index]);
      }).asyncMap((event) async => await event);
    } else if (index == 1) {
      yield* Stream.periodic(Duration(seconds: 1), (_) {
        return Api().getCryptoPrice(cryptoList[index]);
      }).asyncMap((event) async => await event);
    } else if (index == 2) {
      yield* Stream.periodic(Duration(seconds: 1), (_) {
        return Api().getCryptoPrice(cryptoList[index]);
      }).asyncMap((event) async => await event);
    }
  }

  // true--initState  false--other
  update(isInit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (isInit) {
      setState(() {
        lastFundCodeList = prefs.getStringList('fundCodeList') ?? [];
      });
      setState(() {
        ownerFundData = prefs.getStringList('ownerFundData') ?? [];
      });
    }
    List<OwnerFund> tempArr = [];
    await Future.forEach(lastFundCodeList, (code) async {
      var result = await Api().getFundDetail(code);

      if (result != null) {
        tempArr.add(result);
      } else {
        var arr = lastFundCodeList.where((element) => element != code).toList();
        prefs.setStringList('fundCodeList', arr);
        setState(() {
          lastFundCodeList = arr;
        });
      }
    });
    setState(() {
      ownerFundList = tempArr;
    });
  }

  toggleSearchList(text) {
    if (text.length > 0 && isShowSearchList == false) {
      setState(() {
        isShowSearchList = true;
      });
    } else if ((text.length == 0 || text == null) && isShowSearchList == true) {
      setState(() {
        isShowSearchList = false;
      });
    }
  }

  search(searchValue) async {
    List<Data> data = await Api().searchFund(searchValue.toString());
    setState(() {
      searchResultList = data;
    });
  }

  addOwner(code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> oldFundCodeList = prefs.getStringList('fundCodeList') ?? [];
    if (!oldFundCodeList.contains(code.toString())) {
      oldFundCodeList.add(code.toString());
      prefs.setStringList('fundCodeList', oldFundCodeList);
      setState(() {
        lastFundCodeList = prefs.getStringList('fundCodeList') ?? [];
      });
      update(false);
    }
  }

  toggleOwner(code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> oldFundCodeList = prefs.getStringList('fundCodeList') ?? [];
    if (oldFundCodeList.contains(code.toString())) {
      oldFundCodeList.remove(code.toString());
      prefs.setStringList('fundCodeList', oldFundCodeList);
      setState(() {
        lastFundCodeList = prefs.getStringList('fundCodeList') ?? [];
      });
      update(false);
    }
  }

  deleteAllOwner() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('fundCodeList', []);
    prefs.setStringList('ownerFundData', []);
    update(true);
  }

  showNetValueAndShareModal(BuildContext context, code) async {
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
        if (_netValueController.text == null ||
            _netValueController.text.trim().toString().length == 0 ||
            _shareController.text == null ||
            _shareController.text.trim().toString().length == 0) {
          return showToast('请先填写持仓成本价和持有份额');
        }
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> oldOwnerFundDataList =
            prefs.getStringList('ownerFundData') ?? [];
        bool flag = true;
        for (int i = 0; i < oldOwnerFundDataList.length; i++) {
          if (code.toString() == oldOwnerFundDataList[i].split('-~-')[0]) {
            flag = false;
            oldOwnerFundDataList[i] = code.toString() +
                '-~-' +
                _netValueController.text +
                '-~-' +
                _shareController.text;
            break;
          }
        }
        if (flag) {
          String objData = code.toString() +
              '-~-' +
              _netValueController.text +
              '-~-' +
              _shareController.text;
          oldOwnerFundDataList.add(objData);
        }
        prefs.setStringList('ownerFundData', oldOwnerFundDataList);
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
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _netValueController,
                inputFormatters: [
                  // 只能输入数字
                  WhitelistingTextInputFormatter(RegExp("[.]|[0-9]")),
                ],
                decoration: InputDecoration(
                  labelText: '持仓成本价',
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
                  WhitelistingTextInputFormatter(RegExp("[.]|[0-9]")),
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
    List<String> oldOwnerFundDataList =
        prefs.getStringList('ownerFundData') ?? [];
    bool flag = true;
    oldOwnerFundDataList.forEach((e) {
      if (code.toString() == e.split('-~-')[0]) {
        _netValueController.text = e.split('-~-')[1];
        _shareController.text = e.split('-~-')[2];
        flag = false;
      }
    });
    if (flag) {
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

  showCryptoModal(BuildContext context, int index) async {
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
        if (_cryptoCount.text == null ||
            _cryptoCount.text.trim().toString().length == 0) {
          return showToast('请先填写持有的${cryptoList[index]}数量');
        }
        SharedPreferences prefs = await SharedPreferences.getInstance();

        List<String> oldOwnerCryptoData =
            prefs.getStringList('ownerCryptoData') ?? ['', '', ''];
        oldOwnerCryptoData[index] = _cryptoCount.text;
        prefs.setStringList('ownerCryptoData', oldOwnerCryptoData);
        setState(() {
          ownerCryptoData =
              prefs.getStringList('ownerCryptoData') ?? ['', '', ''];
        });
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(cryptoList[index]),
      content: Container(
        height: 70,
        width: 280,
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _cryptoCount,
                inputFormatters: [
                  // 只能输入数字
                  WhitelistingTextInputFormatter(RegExp("[.]|[0-9]")),
                ],
                decoration: InputDecoration(
                  labelText: '持有数量',
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0x19000000)),
                  ),
                ),
                // 校验用户名（不能为空）
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
    List<String> oldOwnerCryptoData =
        prefs.getStringList('ownerCryptoData') ?? ['', '', ''];
    _cryptoCount.text = oldOwnerCryptoData[index] ?? '';
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  costItemPreGains(OwnerFund item) {
    if (item == null) {
      return '0.00';
    }
    double shareCount = 0.00;
    ownerFundData.forEach((e) {
      if (item?.fundcode.toString() == e.split('-~-')[0]) {
        shareCount = double.parse(e.split('-~-')[2]);
      }
    });
    return ((double.parse(item?.dwjz) -
                double.parse(item?.dwjz) /
                    (1 + double.parse(item?.gszzl) * 0.01)) *
            shareCount)
        .toStringAsFixed(2);
  }

  Future<String> costItemAllGains(OwnerFund item) async {
    double netValue = 0.00;
    double shareCount = 0.00;
    ownerFundData?.forEach((e) {
      if (item.fundcode.toString() == e.split('-~-')[0]) {
        netValue = double.parse(e.split('-~-')[1]);
        shareCount = double.parse(e.split('-~-')[2]);
      }
    });
    bool flag = false;
    try {
      int yy = int.parse(item.gztime.substring(0, 10).split('-')[0]);
      int mm = int.parse(item.gztime.substring(0, 10).split('-')[1]);
      int dd = int.parse(item.gztime.substring(0, 10).split('-')[2]);
      var thatDay = DateTime(yy, mm, dd, 15, 00, 00);
      flag = DateTime.now().isAfter(thatDay);
    } catch (e) {}
    var res;
    if (flag) {
      res = await Api().searchFund(item.fundcode).then((List<Data> value) =>
          (value != null && value.length > 0
              ? value[0].fundBaseInfo.dwjz
              : 0.00));
    }
    return !flag
        ? ((double.parse(item.gsz) - netValue) * shareCount).toStringAsFixed(2)
        : ((res - netValue) * shareCount).toStringAsFixed(2);
  }

  Future<String> calculateMoney(OwnerFund item) async {
    double shareCount = 0.00;
    bool flag = false;
    ownerFundData.forEach((e) {
      if (item.fundcode.toString() == e.split('-~-')[0]) {
        shareCount = double.parse(e.split('-~-')[2]);
      }
    });
    try {
      int yy = int.parse(item.gztime.substring(0, 10).split('-')[0]);
      int mm = int.parse(item.gztime.substring(0, 10).split('-')[1]);
      int dd = int.parse(item.gztime.substring(0, 10).split('-')[2]);
      var thatDay = DateTime(yy, mm, dd, 15, 00, 00);
      flag = DateTime.now().isAfter(thatDay);
    } catch (e) {}
    var res;
    if (flag) {
      res = await Api().searchFund(item.fundcode).then((List<Data> value) =>
          (value != null && value.length > 0
              ? value[0].fundBaseInfo.dwjz
              : 0.00));
    }
    String sum = !flag
        ? (double.parse(item.gsz) * shareCount).toStringAsFixed(2)
        : (res * shareCount).toStringAsFixed(2);
    return sum;
  }

  Future<String> costAllGains() async {
    var sum = 0.00;
    for (var i = 0; ownerFundList != null && i < ownerFundList?.length; i++) {
      sum += double.parse(await costItemAllGains(ownerFundList[i]));
    }
    return sum.toStringAsFixed(2);
  }

  costPreGains() {
    var sum = 0.00;
    for (var i = 0; ownerFundList != null && i < ownerFundList?.length; i++) {
      sum += double.parse(costItemPreGains(ownerFundList[i]));
    }
    return sum.toStringAsFixed(2);
  }

  Future<String> calculateAllMoney() async {
    var sum = 0.00;
    for (var i = 0; ownerFundList != null && i < ownerFundList?.length; i++) {
      sum += double.parse(await calculateMoney(ownerFundList[i]));
    }
    return sum.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // title: Text(widget.title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              SearchBar(toggleSearchList, search),
              Container(
                width: MediaQuery.of(context).size.width,
//                height: 200,
                margin: EdgeInsets.only(top: 84),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(8),
                  ),
//                    gradient: LinearGradient(colors: [
//                      Colors.orange,
//                      Color(0xFFfc5531),
//                    ], begin: Alignment.bottomLeft, end: Alignment.topRight)
                ),
                child: ExpansionPanelList(
                  dividerColor: Colors.white,
                  animationDuration: Duration(milliseconds: 600),
                  expansionCallback: (i, isOpen) =>
                      {setState(() => _isOpen[i] = !isOpen)},
                  children: [
                    ExpansionPanel(
                        canTapOnHeader: true,
                        isExpanded: _isOpen[0],
                        headerBuilder: (context, isOpen) => Container(
                              height: 90,
                              margin:
                                  EdgeInsets.only(left: 14, top: 6, bottom: 6),
                              padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  gradient: LinearGradient(
                                      colors: [
                                        Colors.orange,
                                        Color(0xFFfc5531),
                                      ],
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight)),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        child: Text(
                                          '累计收益：',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ),
                                      Container(
                                        child: FutureBuilder<String>(
                                            future: costAllGains(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Text(
                                                  snapshot?.data,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16),
                                                );
                                              }
                                              return Text(
                                                '--',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16),
                                              );
                                            }),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        child: Text(
                                          '当日预估收益：',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ),
                                      Container(
                                        child: Text(
                                          costPreGains(),
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        child: Text(
                                          '总持仓：',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ),
                                      Container(
                                        child: FutureBuilder<String>(
                                            future: calculateAllMoney(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Text(
                                                  snapshot?.data,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16),
                                                );
                                              }
                                              return Text(
                                                '--',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16),
                                              );
                                            }),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        body: Container(
                            padding:
                                EdgeInsets.only(top: 0, left: 14, right: 14),
                            height: 400,
                            child:
                                ownerFundList != null &&
                                        ownerFundList.length > 0
                                    ? ListView.separated(
                                        separatorBuilder:
                                            (BuildContext context, int index) {
                                          return Divider(
                                            height: 20,
                                            color: Colors.white,
                                          );
                                        },
                                        itemCount:
                                            ownerFundList?.length ?? 0 + 1,
                                        itemBuilder: (context, index) {
                                          return index < ownerFundList?.length
                                              ? InkWell(
                                                  onTap: () =>
                                                      showNetValueAndShareModal(
                                                          context,
                                                          ownerFundList[
                                                                      index] !=
                                                                  null
                                                              ? ownerFundList[
                                                                      index]
                                                                  .fundcode
                                                              : '--'),
                                                  child: Container(
                                                    padding: EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(8),
                                                        ),
                                                        gradient:
                                                            LinearGradient(
                                                                colors: [
                                                              Colors.orange,
                                                              Color(0xFFfc5531),
                                                            ],
                                                                begin: Alignment
                                                                    .bottomLeft,
                                                                end: Alignment
                                                                    .topRight)),
                                                    height: 144,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Container(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width -
                                                                    37 -
                                                                    70,
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Container(
                                                                      child:
                                                                          Text(
                                                                        ownerFundList[index] !=
                                                                                null
                                                                            ? ownerFundList[index].name
                                                                            : '--',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize: 16),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      child:
                                                                          Text(
                                                                        ownerFundList[index] !=
                                                                                null
                                                                            ? ownerFundList[index].fundcode
                                                                            : '--',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize: 16),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Container(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width -
                                                                    37 -
                                                                    70,
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Container(
                                                                      child:
                                                                          Text(
                                                                        '估算净值',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize: 16),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      child:
                                                                          Text(
                                                                        ownerFundList[index] !=
                                                                                null
                                                                            ? '${ownerFundList[index].gszzl.toString()}% (${double.parse(ownerFundList[index].gsz).toStringAsFixed(2)})'
                                                                            : '--',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize: 16),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Container(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width -
                                                                    37 -
                                                                    70,
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Container(
                                                                      child:
                                                                          Text(
                                                                        '预估收益',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize: 16),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      child:
                                                                          Text(
                                                                        ownerFundList[index] !=
                                                                                null
                                                                            ? costItemPreGains(ownerFundList[index]) == '-0.00'
                                                                                ? '0.00'
                                                                                : costItemPreGains(ownerFundList[index])
                                                                            : '--',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize: 16),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Container(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width -
                                                                    37 -
                                                                    70,
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Container(
                                                                      child:
                                                                          Text(
                                                                        '累计收益',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize: 16),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      child: FutureBuilder<
                                                                              String>(
                                                                          future: costItemAllGains(ownerFundList[
                                                                              index]),
                                                                          builder:
                                                                              (context, snapshot) {
                                                                            if (snapshot.hasData) {
                                                                              return Text(
                                                                                snapshot?.data,
                                                                                style: TextStyle(color: Colors.white, fontSize: 16),
                                                                              );
                                                                            }
                                                                            return Text(
                                                                              '--',
                                                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                                                            );
                                                                          }),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Container(
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width -
                                                                    37 -
                                                                    70,
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Container(
                                                                      child:
                                                                          Text(
                                                                        '持有金额',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                            fontSize: 16),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      child: FutureBuilder<
                                                                              String>(
                                                                          future: calculateMoney(ownerFundList[
                                                                              index]),
                                                                          builder:
                                                                              (context, snapshot) {
                                                                            if (snapshot.hasData) {
                                                                              return Text(
                                                                                snapshot?.data,
                                                                                style: TextStyle(color: Colors.white, fontSize: 16),
                                                                              );
                                                                            }
                                                                            return Text(
                                                                              '--',
                                                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                                                            );
                                                                          }),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        InkWell(
                                                          onTap: () =>
                                                              toggleOwner(
                                                                  ownerFundList[
                                                                          index]
                                                                      .fundcode),
                                                          child: Container(
                                                            alignment: Alignment
                                                                .center,
                                                            width: 40,
                                                            height: 40,
                                                            decoration:
                                                                BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .all(
                                                                      Radius.circular(
                                                                          20),
                                                                    ),
                                                                    gradient: LinearGradient(
                                                                        colors: [
                                                                          Colors
                                                                              .orange,
                                                                          Color(
                                                                              0xFFfc5531),
                                                                        ],
                                                                        begin: Alignment
                                                                            .bottomLeft,
                                                                        end: Alignment
                                                                            .topRight)),
                                                            child: Icon(
                                                              Icons.check,
                                                              color:
                                                                  Colors.white,
                                                              size: 30,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ))
                                              : InkWell(
                                                  onTap: deleteAllOwner,
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    margin: EdgeInsets.only(
                                                        top: 20, bottom: 24),
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(8),
                                                        ),
                                                        gradient:
                                                            LinearGradient(
                                                                colors: [
                                                              Colors.orange,
                                                              Color(0xFFfc5531),
                                                            ],
                                                                begin: Alignment
                                                                    .bottomLeft,
                                                                end: Alignment
                                                                    .topRight)),
                                                    child: Text(
                                                      '清除所有',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18),
                                                    ),
                                                  ),
                                                );
                                        },
                                      )
                                    : Center(
                                        child: Text('你还没有添加持有的🐔嗷！'),
                                      ))),
                    ExpansionPanel(
                        canTapOnHeader: true,
                        isExpanded: _isOpen[1],
                        headerBuilder: (context, isOpen) => Container(
                              height: 90,
                              margin:
                                  EdgeInsets.only(left: 14, top: 6, bottom: 6),
                              padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  gradient: LinearGradient(
                                      colors: [
                                        Colors.orange,
                                        Color(0xFFfc5531),
                                      ],
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight)),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        child: Text(
                                          '币总资产：',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ),
                                      Container(
                                          child: Text(
                                        '100W',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      )),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        child: Text(
                                          '当日预估收益：',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ),
                                      Container(
                                        child: Text(
                                          costPreGains(),
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        body: Container(
                            padding:
                                EdgeInsets.only(top: 0, left: 14, right: 14),
                            height: 500,
                            child: cryptoList != null && cryptoList.length > 0
                                ? ListView.separated(
                                    separatorBuilder:
                                        (BuildContext context, int index) {
                                      return Divider(
                                        height: 20,
                                        color: Colors.white,
                                      );
                                    },
                                    shrinkWrap: true,
                                    itemCount: cryptoList?.length,
                                    itemBuilder: (context, index) {
                                      return InkWell(
                                          onTap: () =>
                                              showCryptoModal(context, index),
                                          child: Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(8),
                                                ),
                                                gradient: LinearGradient(
                                                    colors: [
                                                      Colors.orange,
                                                      Color(0xFFfc5531),
                                                    ],
                                                    begin: Alignment.bottomLeft,
                                                    end: Alignment.topRight)),
                                            height: 144,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Container(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Container(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width -
                                                            37 -
                                                            70,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Container(
                                                              child: Text(
                                                                cryptoList[index] !=
                                                                        null
                                                                    ? cryptoList[
                                                                        index]
                                                                    : '--',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        16),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width -
                                                              37 -
                                                              70,
                                                          child: StreamBuilder<
                                                              Crypto>(
                                                            stream:
                                                                getCryptoPrice(
                                                                    index),
                                                            // initialData: ,// a Stream<int> or null
                                                            builder: (BuildContext
                                                                    context,
                                                                AsyncSnapshot<
                                                                        Crypto>
                                                                    snapshot) {
                                                              print(
                                                                  ownerCryptoData);
                                                              if (snapshot
                                                                  .hasError)
                                                                return Text(
                                                                    'Error: ${snapshot.error}');
                                                              switch (snapshot
                                                                  .connectionState) {
                                                                case ConnectionState
                                                                    .none:
                                                                  return Text(
                                                                      'no Stream',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                              16));
                                                                case ConnectionState
                                                                    .waiting:
                                                                  return Text(
                                                                      'Loading...',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                              16));
                                                                case ConnectionState
                                                                    .active:
                                                                  Crypto
                                                                      cryptyInfo =
                                                                      snapshot
                                                                          ?.data;
                                                                  return Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Container(
                                                                            child:
                                                                                Text(
                                                                              '持仓',
                                                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                                                            ),
                                                                          ),
                                                                          Container(
                                                                            child:
                                                                                Text(
                                                                              ownerCryptoData != null ? (double.parse(cryptyInfo?.data?.amount) * double.parse(ownerCryptoData[index])).toStringAsFixed(2) + ' ' + cryptyInfo?.data?.currency : '0' + ' ' + cryptyInfo?.data?.currency,
                                                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Container(
                                                                            child:
                                                                                Text(
                                                                              '当前价格',
                                                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                                                            ),
                                                                          ),
                                                                          Container(
                                                                            child:
                                                                                Text(
                                                                              double.parse(cryptyInfo.data.amount).toStringAsFixed(2) + ' ' + cryptyInfo?.data?.currency,
                                                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  );
                                                                case ConnectionState
                                                                    .done:
                                                                  return Text(
                                                                      'Stream off',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                              16));
                                                              }
                                                              return null; // unreachable
                                                            },
                                                          )),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ));
                                    },
                                  )
                                : Center(
                                    child: Text('你还没有添加持有币的嗷！'),
                                  ))),
                  ],
                ),
              ),
              Positioned(
                top: 64,
                left: 0,
                right: 0,
                child: isShowSearchList
                    ? Container(
                        height: MediaQuery.of(context).size.height -
                            (otherHeight - 140),
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.only(left: 18.5, right: 18.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(0),
                          ),
                          color: Colors.blueGrey,
                        ),
                        child: searchResultList != null &&
                                searchResultList.length > 0
                            ? ListView.separated(
                                itemCount: searchResultList?.length,
                                separatorBuilder:
                                    (BuildContext context, int index) {
                                  return Divider(
                                    height: 6,
                                    color: Color(0xFFEEEEEE),
                                  );
                                },
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin:
                                        EdgeInsets.only(top: 10, bottom: 10),
                                    padding: EdgeInsets.only(top: 2, bottom: 2),
                                    height: 56,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    37 -
                                                    60,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        searchResultList[index]
                                                            .name,
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        searchResultList[index]
                                                            .fundBaseInfo
                                                            .dwjz
                                                            .toString(),
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    37 -
                                                    60,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      child: Text(
                                                        searchResultList[index]
                                                            .code,
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16),
                                                      ),
                                                    ),
                                                    Container(
                                                      child: Text(
                                                        '单位净值',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          alignment: Alignment.center,
                                          child: lastFundCodeList != null &&
                                                  lastFundCodeList.contains(
                                                      searchResultList[index]
                                                          .code
                                                          .toString())
                                              ? IconButton(
                                                  onPressed: null,
                                                  icon: Icon(
                                                    Icons.check,
                                                    size: 24,
                                                    color: Colors.white,
                                                  ))
                                              : IconButton(
                                                  onPressed: () => addOwner(
                                                      searchResultList[index]
                                                          .code),
                                                  icon: Icon(
                                                    Icons.add,
                                                    size: 24,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                            : Center(
                                child: Text(
                                  '没有搜到相关的🐔嗷！',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
                              ),
                      )
                    : Text(''),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
