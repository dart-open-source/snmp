import 'ber.dart';
import 'byter.dart';

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
class OID {
  final String value;
  List<int> list;

  static const int HEADER = 0x06;

  OID(this.value) {
    var nv=value;
    nv=nv.replaceAll(',', '.');
    list = nv.split('.').map((e) => int.parse(e.trim())).toList();
  }
  String get id=>list.join('.');

  Byter encode() {
    var os = <int>[];
    os.add(HEADER);
    os.addAll(BER.encodeLength(BER.getOIDLength(list)));
    var encodedLength = list.length;
    var rpos = 0;
    if (list.length < 2) {
      os.add(0);
      encodedLength = 0;
    } else {
      var firstSubID = list[0];
      if (BER.checkFirstSubID012 && (firstSubID < 0 || firstSubID > 2)) {
        throw Exception('Invalid first sub-identifier (must be 0, 1, or 2)');
      }
      os.addAll(BER.encodeSubID(list[1] + (firstSubID * 40)));
      encodedLength -= 2;
      rpos = 2;
    }
    while (encodedLength-- > 0) {
      os.addAll(BER.encodeSubID(list[rpos++]));
    }
    return Byter(os);
  }

  @override
  String toString() => 'OID<${list.length}>{ ${list.join('.')} }';

  static OID decode(Byter byter) {
    int subidentifier;
    int length;
    // get the header
    var header = byter.byte();
    if (header != HEADER) throw Exception('Wrong header $HEADER:$header');
    length = BER.decodeLength(byter);
    var oid = List<int>(length+2);
    if (length == 0) oid[0] = oid[1] = 0;
    var pos = 1;
    /* Handle invalid object identifier encodings of the form 06 00 robustly */
    while (length > 0) {
      subidentifier = 0;
      int b;
      do {
        var next = byter.byte();
        if (next < 0) throw Exception('Unexpected end of input stream');
        b = next & 0xFF;
        subidentifier = (subidentifier << 7) + (b & ~BER.ASN_BIT8);
        length--;
      } while ((length > 0) && ((b & BER.ASN_BIT8) != 0));
      /* last byte has high bit clear */
      oid[pos++] = subidentifier;
    }
    subidentifier = oid[1];
    if (subidentifier == 0x2B) {
      oid[0] = 1;
      oid[1] = 3;
    } else if (subidentifier >= 0 && subidentifier < 80) {
      if (subidentifier < 40) {
        oid[0] = 0;
      } else {
        oid[0] = 1;
        oid[1] = subidentifier - 40;
      }
    } else {
      oid[0] = 2;
      oid[1] = subidentifier - 80;
    }
    var noid=[];
    oid.forEach((element) {
      if(element!=null) noid.add(element);
    });
    return OID(noid.join('.'));
  }


  @override
  bool operator ==(other) {
    if(other is OID) return other.id==id;
    return super == other;
  }

}
