import 'dart:async';
import 'dart:io';

import 'byter.dart';
import 'oid.dart';
import 'pdu.dart';

export 'oid.dart';
export 'ber.dart';
export 'pdu.dart';
export 'byter.dart';
///
/// About:->
/// Copyright 2020 Alm.Pazel
/// License-Identifier: MIT
///
///
/// Refrences:->
/// https://en.wikipedia.org/wiki/Simple_Network_Management_Protocol
/// https://tools.ietf.org/html/rfc1228
///

class SnmpPack {
  RawDatagramSocket socket;
  Map<String,Completer<PDU>> completer={};
  SnmpPack(RawDatagramSocket datagramSocket){
    socket=datagramSocket;
    socket.listen(onSubscribe);
  }

  void onSubscribe(RawSocketEvent event) {
    //print(event.toString());
    try{
      var dg = socket.receive();
      if(dg != null) {
        var pdu=PDU(Byter(dg.data.toList()));
//        print('res:$pdu');
        if(pdu!=null&&completer.containsKey(pdu.id)){
          completer[pdu.id].complete(pdu);
        }
      }
    }catch(e){
      print(event.toString());
    }
  }

  /// @oid example OID('1.3.6.xxxx.x.x')
  /// @to example 0.0.0.0:161
  Future<PDU> get(PDU pdu,String to,{Duration timeOut}) async {
    var uri=to.split(':');
    completer[pdu.id]=Completer<PDU>();
    socket.send(pdu.bytes(), InternetAddress(uri.first), int.parse(uri.last));
    var res=await completer[pdu.id].future.timeout(timeOut??Duration(seconds: 5),onTimeout:(){
      return null;
    });
    completer.remove(pdu.id);
    return res;
  }

  static Future<SnmpPack> bind({InternetAddress address,int port=1614}) async {
    return SnmpPack(await RawDatagramSocket.bind(address??InternetAddress.anyIPv4, port));
  }

  void close() {
    try{
      socket.close();
    // ignore: empty_catches
    }catch(e){
    }
  }

}
