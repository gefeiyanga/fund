import 'package:flutter/material.dart';
import 'package:fundapp/model/ownerFund.dart';
import 'package:fundapp/ui/widget/searchBar.dart';
import 'package:fundapp/common/api.dart';
import 'package:fundapp/model/searchResult.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

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
  int otherHeight = 0;

  @override
  void initState() {
    update();
  }

  update () async {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        lastFundCodeList = prefs.getStringList('fundCodeList')??[];
      });
      List<OwnerFund> tempArr = [];
      lastFundCodeList.forEach((code) async {
        var result = await Api().getFundDetail(code);
        tempArr.add(result);
      });
      this.setState(() {
        ownerFundList = tempArr;
      });
    });
    Future.delayed(Duration.zero, () {
      int height = 52 + MediaQueryData.fromWindow(window).padding.top.toInt() + kToolbarHeight.toInt();
      setState(() {
        otherHeight = height;
      });
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
      this.setState(() {
        lastFundCodeList = prefs.getStringList('fundCodeList')??[];
      });
      update();
    }
  }

  toggleOwner (code) async {
    print(code);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> oldFundCodeList = prefs.getStringList('fundCodeList')??[];
    if(oldFundCodeList.contains(code.toString())) {
      oldFundCodeList.remove(code.toString());
      prefs.setStringList('fundCodeList', oldFundCodeList);
      this.setState(() {
        lastFundCodeList = prefs.getStringList('fundCodeList')??[];
      });
      update();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('lastFundCodeList: $lastFundCodeList');
    print('ownerFundList: $ownerFundList');
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
                  itemCount: ownerFundList.length,
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
                                  width: MediaQuery.of(context).size.width-37-70,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        child: Text(ownerFundList[index]!=null ? ownerFundList[index].name : '未知',
                                          style: TextStyle(color: Colors.black, fontSize: 14),),
                                      ),
                                      Container(
                                        child: Text(ownerFundList[index]!=null ? ownerFundList[index].dwjz.toString() : '未知',
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
                                        child: Text(ownerFundList[index]!=null ? ownerFundList[index].fundcode : '未知',
                                          style: TextStyle(color: Colors.black, fontSize: 14),),
                                      ),
                                      Container(
                                        child: Text('单位净值',
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
                    );

                  },
                ) : Text('暂无数据3'),
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
                  ) : Text('暂无数据'),
                ) : Text(''),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
