
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:snmp/snmp.dart';

Future<void> main() async {

    var oid=OID('1.3.6.1.2.1.43342.10.2.1.4.1.1');
    print(oid);
    print(OID.decode(oid.encode()));
    print(utf8.decode(hex.decode('7075626C6963')));
    print(PDU(OID('1.3.6.1.2.1.43.10.2.1.4.1.1')));
    var pud=PDU(Byter(hex.decode('304C02010004067075626C6963A03F020251B80201000201003033300F060B2B060102011903020105010500300F060B2B060102011903050101010500300F060B2B060102011903050102010500')));
    print(pud);
    print(hex.encode(pud.value.all));

}
