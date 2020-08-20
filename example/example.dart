import 'package:snmp/snmp.dart';
import 'package:snmp/src/pdu.dart';

Future<void> main() async {
    //Bind your local SNMP client ip
    var pack = await SnmpPack.bind();
    //Request OID to some host
    await pack.get(PDU(OID('1.3.6.1.2.1.43.10.2.1.4.1.1')),to:'192.168.199.214:161').then(print);
    await pack.get(PDU(OID('1.3.6.1.2.1.43.10.2.1.4.1.1')),to:'192.168.8.2:161').then(print);
    //woking on ...
    await pack.get(PDU(OID('1, 3, 6, 1, 2, 1, 25, 3, 2, 1, 5, 1')),to:'192.168.199.214:161').then(print);
    pack.close();
}
