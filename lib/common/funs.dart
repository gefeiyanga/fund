import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast(String text, {
  gravity: ToastGravity.CENTER,
  toastLength: Toast.LENGTH_SHORT,
}) {
  Fluttertoast.showToast(
    msg: text,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIos: 2,
    backgroundColor: Colors.grey[600],
    fontSize: 16.0,
  );
}

void showLoading(context, [String text]) {
  text = text ?? 'loading...';
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return Center(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3.0),
                boxShadow: [
                  // 阴影
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10.0,
                  )
                ]
            ),
            padding: EdgeInsets.all(16.0),
            margin: EdgeInsets.all(16.0),
            constraints: BoxConstraints(minHeight: 120, minWidth: 180),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    text,
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyText1,
                  ),
                )
              ],
            ),
          ),
        );
      }
  );
}