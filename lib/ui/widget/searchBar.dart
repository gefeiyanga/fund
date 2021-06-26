import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:throttling/throttling.dart';

class SearchBar extends StatefulWidget {

  var toggleSearchList;
  var search;
  SearchBar(this.toggleSearchList, this.search);

  @override
  State<StatefulWidget> createState() => new _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {

  final Debouncing deb = new Debouncing(duration: Duration(milliseconds: 400));

  final controller = TextEditingController();
  bool isShowClose = false;
  GlobalKey equSearchBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  void handleChanged (text) {
    if(text.toString().length>0&&!isShowClose) {
      setState(() {
        isShowClose = true;
      });
    } else if(text.toString().length==0&&isShowClose) {
      setState(() {
        isShowClose = false;
      });
    }
    widget.toggleSearchList(text);
    if(text.toString().length>0) {
      deb.debounce(()=>widget.search(text));
    }
  }

  void clear () {
    controller.text='';
    widget.toggleSearchList(controller.text);
    setState(() {
      isShowClose = false;
    });
  }

  @override
  void dispose () {
    controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepOrange,
      child: Padding(
        padding: EdgeInsets.only(top: 0,),
        child: Container(
          height: 64.0,
          child: new Padding(
              padding: const EdgeInsets.all(6.0),
              child: new Card(
                  child: new Container(
                    child: new Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.deepOrange,
                            ),
                            child: TextField(
                              controller: controller,
                              style: TextStyle(color: Colors.white),
                              onChanged: (text)=>handleChanged(text),
                              decoration: new InputDecoration(
                                fillColor: Color(0xFFfc5531),
                                filled: true,
                                prefixIcon: IconButton(
                                  padding: EdgeInsets.all(4.0),
                                  icon: Icon(Icons.search, color: Colors.white,),
                                ),
                                suffixIcon: isShowClose ? IconButton(
                                  padding: EdgeInsets.all(4.0),
                                  icon: Icon(Icons.close_rounded, color: Colors.white,),
                                  onPressed: clear,
                                ) : null,
                                contentPadding: EdgeInsets.all(4),
                                hintText: '请输入基金代码、名称或简拼',
                                hintStyle: TextStyle(color: Colors.white, fontSize: 16),
                                border: new OutlineInputBorder(
//                                  borderRadius: const BorderRadius.all(
//                                    const Radius.circular(20.0),
//                                  ),
                                  borderSide: BorderSide(
                                    width: 0,
                                    style: BorderStyle.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
              )
          ),
        ),
      ),
    );
  }
}