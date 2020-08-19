A SNMP library for Dart developers.

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/almpazel/dart-snmp/blob/master/LICENSE).

## Usage

This package used to SNMP protocol, in flutter also work.

## Tested
- printers;
- .....
- if you need other printers contact with Email.


A simple usage example:

```dart
import 'package:snmp/snmp.dart';

main() {
  //Change your printer ip

  SnmpPack.ip='192.168.199.232';
  SnmpPack.port=161;

  //Printer Total Page
    var pack = SnmpPack();
    var res=await pack.get(OID('1.3.6.1.4.4.4.1'));
    print('response $res');
  
}
```

## References

[Wikipedia/SNMP](https://en.wikipedia.org/wiki/Simple_Network_Management_Protocol) 
