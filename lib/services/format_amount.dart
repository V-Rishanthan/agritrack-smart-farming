String FormatAmount(double amount) {
  final wholePart = amount.toInt().toString();
  if (wholePart.length <= 3) return wholePart;
  final lastThree = wholePart.substring(wholePart.length - 3);
  final rest = wholePart.substring(0, wholePart.length - 3);
  final restWithCommas = rest.replaceAllMapped(
    RegExp(r'\B(?=(\d{2})+(?!\d))'),
    (match) => ',',
  );
  return '$restWithCommas,$lastThree';
}
