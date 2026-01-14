import 'dart:typed_data';

const String _log_chars =
    "ZWXYMPTERQUONCHBJILGFSDVKAhiopxyzamtbeqnwrsjklucdvfg089/174+5236";

bool _isBase64(String char) {
  return _log_chars.contains(char);
}

String logEncode(Uint8List input) {
  if (input == null || input.isEmpty) {
    return "";
  }
  int length = input.length;
  int i = 0, j = 0, s = 0;
  var charArray3 = []..length = 3;

  var charArray4 = []..length = 4;

  var b64str = StringBuffer();

  while (length-- > 0) {
    charArray3[i] = input[s];
    s += 1;
    i += 1;
    if (i == 3) {
      charArray4[0] = (charArray3[0] & 0xfc) >> 2;
      charArray4[1] =
          ((charArray3[0] & 0x03) << 4) + ((charArray3[1] & 0xf0) >> 4);
      charArray4[2] =
          ((charArray3[1] & 0x0f) << 2) + ((charArray3[2] & 0xc0) >> 6);
      charArray4[3] = charArray3[2] & 0x3f;

      for (i = 0; i < 4; i++)
        b64str.writeCharCode(_log_chars.codeUnitAt(charArray4[i]));
      i = 0;
    }
  }
  if (i != 0) {
    for (j = i; j < 3; j++) charArray3[j] = 0;
    charArray4[0] = (charArray3[0] & 0xfc) >> 2;
    charArray4[1] =
        ((charArray3[0] & 0x03) << 4) + ((charArray3[1] & 0xf0) >> 4);
    charArray4[2] =
        ((charArray3[1] & 0x0f) << 2) + ((charArray3[2] & 0xc0) >> 6);
    charArray4[3] = charArray3[2] & 0x3f;

    for (j = 0; j < i + 1; j++)
      b64str.writeCharCode(_log_chars.codeUnitAt(charArray4[j]));

    while (i++ < 3) b64str.writeCharCode('='.codeUnitAt(0));
  }

  return b64str.toString();
}

List<int>? logDecode(String input) {
  if (input == null || input.isEmpty) {
    return null;
  }
  int length = input.length;
  int i = 0;
  int j = 0;
  int idx = 0;
  var charArray4 = []..length = 4;
  var charArray3 = []..length = 3;
  var output = <int>[];

  while (length-- > 0 && input[idx] != '=') {
    if (!_isBase64(input[idx])) {
      idx++;
      continue;
    }
    charArray4[i++] = input[idx++];
    if (i == 4) {
      for (i = 0; i < 4; i++) {
        charArray4[i] = _log_chars.indexOf(charArray4[i]);
      }

      charArray3[0] = (charArray4[0] << 2) + ((charArray4[1] & 0x30) >> 4);
      charArray3[1] =
          ((charArray4[1] & 0xf) << 4) + ((charArray4[2] & 0x3c) >> 2);
      charArray3[2] = ((charArray4[2] & 0x3) << 6) + charArray4[3];

      for (i = 0; (i < 3); i++) output.add(charArray3[i]);
      i = 0;
    }
  }

  if (i != 0) {
    for (j = i; j < 4; j++) charArray4[j] = '\0';

    for (j = 0; j < 4; j++) {
      charArray4[j] = _log_chars.indexOf(charArray4[j]);
    }

    charArray3[0] = (charArray4[0] << 2) + ((charArray4[1] & 0x30) >> 4);
    charArray3[1] =
        ((charArray4[1] & 0xf) << 4) + ((charArray4[2] & 0x3c) >> 2);
    charArray3[2] = ((charArray4[2] & 0x3) << 6) + charArray4[3];

    for (j = 0; (j < i - 1); j++) output.add(charArray3[j]);
  }

  return output;
}
