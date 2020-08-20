import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:snmp/snmp.dart';
import 'package:snmp/src/byter.dart';

import 'ber.dart';

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
class PDU {
  static const int HEADER = 0x30;
  static const int GET = (BER.ASN_CONTEXT | BER.ASN_CONSTRUCTOR);
  static const int GETNEXT = (BER.ASN_CONTEXT | BER.ASN_CONSTRUCTOR | 0x1);
  static const int RESPONSE = (BER.ASN_CONTEXT | BER.ASN_CONSTRUCTOR | 0x2);
  static const int SET = (BER.ASN_CONTEXT | BER.ASN_CONSTRUCTOR | 0x3);
  static const int V1TRAP = (BER.ASN_CONTEXT | BER.ASN_CONSTRUCTOR | 0x4);
  static const int GETBULK = (BER.ASN_CONTEXT | BER.ASN_CONSTRUCTOR | 0x5);
  static const int INFORM = (BER.ASN_CONTEXT | BER.ASN_CONSTRUCTOR | 0x6);
  static const int TRAP = (BER.ASN_CONTEXT | BER.ASN_CONSTRUCTOR | 0x7);
  static const int NOTIFICATION = TRAP;
  static const int REPORT = (BER.ASN_CONTEXT | BER.ASN_CONSTRUCTOR | 0x8);

  OID oid;

  int version=0;

  String community ='public';

  Byter raw = Byter();
  Byter value = Byter();

  int requestId = 0000000001;
  int requestStatus = 0;
  int requestIndex = 0;

  String get id => oid.id;

  @override
  String toString() {
    return 'PDU<$requestId,$requestStatus,$requestIndex>{ $oid->$value, community:$community, raw:$raw }';
  }

  String toHexString() => raw.toHexString();

  Map _option = {};

  Byter body = Byter();
  /// input should be OID, Byter , hexStr
  PDU(dynamic input, {Map option}) {
    _option = option ?? {};
    if (input is OID) encode(input);
    if (input is Byter) decode(input);
    if (input is String) decode(Byter(input));
  }

  static int get timeint => DateTime.now().millisecondsSinceEpoch;

  void requestEncode() {}

  void decode(Byter input) {
    raw = input.clone();
    var byter = BER.decode(input);
    var _version = BER.decode(byter, 0x02);
    version=int.parse(_version.toHexString(),radix: 16);
    community = utf8.decode(BER.decode(byter, 0x04).all);
    var type=byter.byte();
    byter.eat(type);
    body = BER.decode(byter, type);
    var req = body.clone();
    var reqId = BER.decode(req, 0x02);
    requestId = int.parse(reqId.toHexString(), radix: 16);
    var reqState = BER.decode(req, 0x02);
    requestStatus = int.parse(reqState.toHexString(), radix: 16);
    var reqIndex = BER.decode(req, 0x02);
    requestStatus = int.parse(reqIndex.toHexString(), radix: 16);
    var v1 = BER.decode(req);
    var v2 = BER.decode(v1);
    oid = OID.decode(v2);
    value = v2;
  }

  void encode(OID oid) {
    this.oid = oid;
    var oids = oid.encode(); //oid
    oids.add(0x05);
    oids.add(0x00);
    var req = BER.encode(BER.encode(oids)); //var-bind
    req.eat(BER.encode(Byter([0]), 0x02)); //request index
    req.eat(BER.encode(Byter([0]), 0x02)); //request status
    requestId = (timeint / 1000).round();
    req.eat(BER.encode(Byter(hex.decode(requestId.toRadixString(16))), 0x02)); //request id
    body = BER.encode(req, GET);
    var _pdu = Byter();
    _pdu.add(BER.encode(Byter([version]), 0x02)); //version info
    _pdu.add(BER.encode(Byter(community.codeUnits), 0x04)); //community
    _pdu.add(body);
    raw = BER.encode(_pdu,HEADER);
  }

  List<int> bytes() => raw.all;

  static PDU fromOid(String s) => PDU(OID(s));
}
