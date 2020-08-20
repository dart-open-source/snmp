import 'package:snmp/snmp.dart';
import 'package:snmp/src/pdu.dart';

Future<void> main() async {
    //Bind your local SNMP client ip
    var pack = await SnmpPack.bind();
    //Request OID to some host

    var to='192.168.199.214:161'; //target ip and port

    var pdu=await pack.get(PDU(OID('1.3.6.1.2.1.43.10.2.1.4.1.1')),to);
    print(pdu.value);
    print(BER.decode(pdu.value,BER.COUNTER).toInt());

    await pack.get(PDU(OID('1.3.6.1.2.1.43.10.2.1.4.1.1')),to).then(print);
    //device model
    await pack.get(PDU(OID('1.3.6.1.2.1.25.3.2.1.3.1')),to).then(print);
    pack.close();
}
