class Byter {
  final List<int> _bytes = [];

  List<int> get all => _bytes;

  int get first => _bytes.first;

  void clear() => _bytes.clear();

  @override
  String toString() => 'Byter{${length}}';

  Byter([List<int> ints]) {
    _bytes.clear();
    if (ints != null) _bytes.addAll(ints);
  }

  int get length => _bytes.length;

  bool get isEmpty => _bytes.isEmpty;

  bool get isNotEmpty => _bytes.isNotEmpty;

  Byter bytes([int len = 1]) {
    var r = _bytes.sublist(0, len);
    _bytes.removeRange(0, len);
    return Byter(r);
  }

  int byte() => bytes(1)?.first;

  void add(int b) => _bytes.add(b);

  void addAll(List<int> os) => os.forEach(add);

  void eat(int b) => _bytes.insert(0, b);

  void eatAll(List<int> os) => os.forEach(eat);
  Byter clone()  => Byter(all);
}
