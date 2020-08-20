import 'package:snmp/src/byter.dart';
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

class BER {
  static const int ASN_BOOLEAN = 0x01;
  static const int ASN_INTEGER = 0x02;
  static const int ASN_BIT_STR = 0x03;
  static const int ASN_OCTET_STR = 0x04;
  static const int ASN_NULL = 0x05;
  static const int ASN_OBJECT_ID = 0x06;
  static const int ASN_SEQUENCE = 0x10;
  static const int ASN_SET = 0x11;
  static const int ASN_UNIVERSAL = 0x00;
  static const int ASN_APPLICATION = 0x40;
  static const int ASN_CONTEXT = 0x80;
  static const int ASN_PRIVATE = 0xC0;
  static const int ASN_PRIMITIVE = 0x00;
  static const int ASN_CONSTRUCTOR = 0x20;

  static const int ASN_LONG_LEN = 0x80;
  static const int ASN_EXTENSION_ID = 0x1F;
  static const int ASN_BIT8 = 0x80;

  static const int INTEGER = ASN_UNIVERSAL | 0x02;
  static const int INTEGER32 = ASN_UNIVERSAL | 0x02;
  static const int BITSTRING = ASN_UNIVERSAL | 0x03;
  static const int OCTETSTRING = ASN_UNIVERSAL | 0x04;
  static const int NULL = ASN_UNIVERSAL | 0x05;
  static const int OID = ASN_UNIVERSAL | 0x06;
  static const int SEQUENCE = ASN_CONSTRUCTOR | 0x10;

  static const int IPADDRESS = ASN_APPLICATION | 0x00;
  static const int COUNTER = ASN_APPLICATION | 0x01;
  static const int COUNTER32 = ASN_APPLICATION | 0x01;
  static const int GAUGE = ASN_APPLICATION | 0x02;
  static const int GAUGE32 = ASN_APPLICATION | 0x02;
  static const int TIMETICKS = ASN_APPLICATION | 0x03;
  static const int OPAQUE = ASN_APPLICATION | 0x04;
  static const int COUNTER64 = ASN_APPLICATION | 0x06;

  static const int NOSUCHOBJECT = 0x80;
  static const int NOSUCHINSTANCE = 0x81;
  static const int ENDOFMIBVIEW = 0x82;

  static const int LENMASK = 0x0ff;
  static const int MAX_OID_LENGTH = 127;

  static bool checkSequenceLength = true;
  static bool checkValueLength = true;
  static bool checkFirstSubID012 = true;

  static List<int> encodeLength(int length) {
    var os = <int>[];
    if (length < 0) {
      os.add(0x04 | ASN_LONG_LEN);
      os.add((length >> 24) & 0xFF);
      os.add((length >> 16) & 0xFF);
      os.add((length >> 8) & 0xFF);
      os.add(length & 0xFF);
    } else if (length < 0x80) {
      os.add(length);
    } else if (length <= 0xFF) {
      os.add((0x01 | ASN_LONG_LEN));
      os.add(length);
    } else if (length <= 0xFFFF) {
      /* 0xFF < length <= 0xFFFF */
      os.add(0x02 | ASN_LONG_LEN);
      os.add((length >> 8) & 0xFF);
      os.add(length & 0xFF);
    } else if (length <= 0xFFFFFF) {
      /* 0xFFFF < length <= 0xFFFFFF */
      os.add(0x03 | ASN_LONG_LEN);
      os.add((length >> 16) & 0xFF);
      os.add((length >> 8) & 0xFF);
      os.add(length & 0xFF);
    } else {
      os.add(0x04 | ASN_LONG_LEN);
      os.add((length >> 24) & 0xFF);
      os.add((length >> 16) & 0xFF);
      os.add((length >> 8) & 0xFF);
      os.add(length & 0xFF);
    }
    return os;
  }

  static int getOIDLength(List<int> value) {
    var length = 1;
    if (value.length > 1) {
      // for first 2 subids, one sub-id is saved by special encoding
      length = getSubIDLength((value[0] * 40) + value[1]);
    }
    for (var i = 2; i < value.length; i++) {
      length += getSubIDLength(value[i]);
    }
    return length;
  }

  static int getSubIDLength(int subID) {
    int length;
    var v = subID & 0xFFFFFFFF;
    if (v < 0x80) {
      length = 1;
    } else if (v < 0x4000) {
      length = 2;
    } else if (v < 0x200000) {
      length = 3;
    } else if (v < 0x10000000) {
      length = 4;
    } else {
      length = 5;
    }
    return length;
  }

  static dynamic encodeSubID(int subID) {
    var os = <int>[];
    var subid = (subID & 0xFFFFFFFF);
    if (subid < 127) {
      os.add(subid & 0xFF);
    } else {
      var mask = 0x7F; /* handle subid == 0 case */
      var bits = 0;
      /* testmask *MUST* !!!! be of an unsigned type */
      for (var testmask = 0x7F, testbits = 0; testmask != 0; testmask <<= 7, testbits += 7) {
        if ((subid & testmask) > 0) {
          /* if any bits set */
          mask = testmask;
          bits = testbits;
        }
      }
      /* mask can't be zero here */
      for (; mask != 0x7F; mask >>= 7, bits -= 7) {
        /* fix a mask that got truncated above */
        if (mask == 0x1E00000) {
          mask = 0xFE00000;
        }
        os.add((((subid & mask) >> bits) | ASN_BIT8));
      }
      os.add((subid & mask));
    }
    return os;
  }

  static int decodeLength(Byter byter, [bool isCheckLength = true]) {
    var length = 0;
    var lengthbyte = byter.byte();
    if ((lengthbyte & ASN_LONG_LEN) > 0) {
      lengthbyte &= ~ASN_LONG_LEN; /* turn MSb off */
      if (lengthbyte == 0) throw Exception('Indefinite lengths are not supported');
      if (lengthbyte > 4) throw Exception('Data length > 4 bytes are not supported!');
      for (var i = 0; i < lengthbyte; i++) {
        var l = byter.byte() & 0xFF;
        length |= (l << (8 * ((lengthbyte - 1) - i)));
      }
      if (length < 0) throw Exception('SNMP does not support data lengths > 2^31');
    } else {
      length = lengthbyte & 0xFF;
    }
    if (isCheckLength) checkLength(byter, length);
    return length;
  }

  static void checkLength(Byter byter, int length) {
    if (!checkValueLength) return;
    if ((length < 0) || (length > byter.length)) throw Exception('The encoded length $length exceeds,input ${byter.length}');
  }

  static Byter encode(Byter input,[int type=BER.SEQUENCE]) {
    var byter=Byter();
    byter.add(type);
    byter.addAll(encodeLength(input.length));
    byter.addAll(input.all);
    return byter;
  }

  static Byter decode(Byter input,[int type=BER.SEQUENCE]) {
    var t=input.byte();
    if(t!=type) throw Exception('The encoded type $t not equal type:$type ');
    return input.bytes(decodeLength(input));
  }
}