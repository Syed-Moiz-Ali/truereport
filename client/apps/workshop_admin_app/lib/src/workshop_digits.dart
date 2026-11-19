/// One numbering system for every data value in the app.
///
/// `NumberFormat.decimalPattern('ar')` already renders Latin digits in intl
/// 0.20, but `DateFormat` renders Arabic-Indic digits **and** inserts RLM/LRM
/// controls around separators. A data line must not mix numbering systems, and
/// an identifier or timestamp must not carry invisible direction switches
/// (dashboard Gate 6 caught `509:00 2026/11/`).
///
/// Used by the dashboard and the jobs queue. Formatting stays locale-aware;
/// only the digit set and the bidi controls are normalised.
String pinDigits(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    // Arabic-Indic digits -> ASCII.
    if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(rune - 0x0660 + 0x30);
      continue;
    }
    // Extended Arabic-Indic digits (Persian) -> ASCII.
    if (rune >= 0x06F0 && rune <= 0x06F9) {
      buffer.writeCharCode(rune - 0x06F0 + 0x30);
      continue;
    }
    // Bidi controls: LRM, RLM, ALM, embeddings/overrides, isolates.
    if (rune == 0x200E ||
        rune == 0x200F ||
        rune == 0x061C ||
        (rune >= 0x202A && rune <= 0x202E) ||
        (rune >= 0x2066 && rune <= 0x2069)) {
      continue;
    }
    buffer.writeCharCode(rune);
  }
  return buffer.toString();
}

/// A numeric range that stays readable inside an RTL sentence.
///
/// The range is wrapped in a left-to-right isolate so `1–10` is not reordered
/// to `10–1` by the bidi algorithm, while the surrounding Arabic still reads
/// right to left.
String ltrRange(int from, int to) => '\u2066$from–$to\u2069';
