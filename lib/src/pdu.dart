import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:snmp/snmp.dart';
import 'package:snmp/src/byter.dart';

import 'ber.dart';

class PDU {
  static const int HEADER = 0x30;

  OID oid;
  String community = 'public';
  Byter raw = Byter();
  Byter value = Byter();

  String get id => oid.id;

  @override
  String toString() {
    return 'PDU{$oid->$value, community: $community, raw: $raw}';
  }

  Map _option = {};

  Byter _version = Byter(hex.decode('02010004'));
  Byter _community = Byter();
  Byter _request = Byter();

  PDU(dynamic input, {Map option}) {
    _option = option ?? {};
    if (input is OID) encode(input);
    if (input is Byter) decode(input);
  }

  void communityEncode() {
    var com = (_option['community'] ?? community).codeUnits;
    _community.clear();
    _community.addAll(BER.encodeLength(com.length));
    _community.addAll(com);
  }

  void requestEncode() {
    var oidD = oid.encode();
    _request.clear();
    _request.add(0xa0); //request
    var req = <int>[];
    req.addAll(hex.decode('020463C8A0F6')); //02+request-id-length+request-id
    req.addAll(hex.decode('020100')); //02+request-status-length+request-status
    req.addAll(hex.decode('020100')); //02+request-index-length+request-index
    req.addAll(hex.decode('3012')); //var-bind-list+length
    req.addAll(hex.decode('3010')); //var-bind-list+length
    _request.addAll(BER.encodeLength(oidD.length + req.length + 2)); //request+length
    _request.addAll(req); //req
    _request.addAll(oidD.all); //oid
    _request.add(0x05); //footer
    _request.add(0x00);
  }

  void decode(Byter byter) {
    raw = byter.clone();
    var header = byter.byte();
    if (header != HEADER) throw Exception('Wrong pdu header $HEADER:$header');
    var length = BER.decodeLength(byter);
    _version = byter.bytes(4);
    communityDecode(byter);
    requestDecode(byter);
  }

  void encode(OID oid) {
    this.oid = oid;
    requestEncode();
    communityEncode();
    var _pdu = Byter();
    _pdu.add(HEADER); //header
    var length = 4 + _community.length + _request.length;
    _pdu.addAll(BER.encodeLength(length)); //pud length
    _pdu.addAll(_version.all); //version info
    _pdu.addAll(_community.all); //community-length+community
    _pdu.addAll(_request.all);
    raw = _pdu.clone();
  }

  void communityDecode(Byter byter) {
    var len = byter.byte();
    var com = byter.bytes(len);
    _community = com;
    _community.eat(len);
    community = utf8.decode(com.all).trim();
  }

  void requestDecode(Byter byter) {
    var type = byter.byte();
    var reqL = byter.byte();
    _request = byter.bytes(reqL);
    var decode = _request.clone();
    decode.byte();
    var reqSL = decode.byte();
    var reqS = decode.bytes(reqSL);
    decode.byte();
    var reqEL = decode.byte();
    var reqE = decode.bytes(reqEL);
    decode.byte();
    var reqIL = decode.byte();
    var reqI = decode.bytes(reqIL);
    var valbind = decode.bytes(4);
    oid = OID.decode(decode);
    value = decode;
  }

  List<int> bytes() => raw.all;
}
