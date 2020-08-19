
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:snmp/src/byter.dart';
import 'package:snmp/src/oid.dart';
import 'package:snmp/src/pdu.dart';

Future<void> main() async {

    var oid=OID('1.3.6.1.2.1.43342.10.2.1.4.1.1');
    print(oid);
    print(OID.decode(oid.encode()));
    print(utf8.decode(hex.decode('7075626C6963')));
    print(PDU(OID('1.3.6.1.2.1.43.10.2.1.4.1.1')));
    print(PDU(Byter(hex.decode('302F02010004067075626C6963A222020463C8A0F602010002010030143012060C2B060102012B0A020104010141020094'))));

}
