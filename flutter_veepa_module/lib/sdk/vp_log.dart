import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:veepa_camera_poc/sdk/vp_log_code.dart';

enum VPLogLevel {
  INFO,
  DEBUG,
  WARN,
  ERROR,
  FILE,
  MAX,
}

class VPLogStackTraceInfo {
  final StackTrace trace;

  String fileName = "Unknown";
  String lineNumber = "0";
  String columnNumber = "0";
  String funName = "Unknown";
  int stackTraceNum = 0;

  VPLogStackTraceInfo(this.trace, int traceNum) {
    stackTraceNum = traceNum;
  }

  void parseTrace() {
    if (trace == null) return;
    var stackString = trace.toString();
    var strList = stackString.split("\n");
    if (stackTraceNum >= strList.length) return;
    var traceString = strList[stackTraceNum];
    var funList = traceString.split("(");
    funName = funList.first;
    funName = funName.replaceAll("#$stackTraceNum", "").trim();
    funList = funName.split(".");
    funName = funList.last;
    var fileInfo = traceString.split("/").last;
    var listOfInfo = fileInfo.split(":");
    if (listOfInfo.length < 1) return;
    fileName = "${listOfInfo[0]}";
    if (listOfInfo.length < 2) return;
    lineNumber = listOfInfo[1];
    if (listOfInfo.length < 3) return;
    columnNumber = listOfInfo[2].replaceFirst(")", "");
  }
}

typedef LogFileFullListener = Future<void> Function(File file);

class VPLog {
  static const EventChannel _logEvent = const EventChannel('vp_log/event');
  static const MethodChannel _logMethod = const MethodChannel('vp_log/method');

  static VPLogLevel _logLevel = VPLogLevel.INFO;

  static int _maxFileSize = 15;

  static int _logFileSize = 0;

  static File? _logFile;

  static IOSink? _logFileIO;

  static LogFileFullListener? _logListener;

  static String _levelString(VPLogLevel level) {
    switch (level) {
      case VPLogLevel.FILE:
        return " FILE";
      case VPLogLevel.ERROR:
        return "ERROR";
      case VPLogLevel.WARN:
        return " WARN";
      case VPLogLevel.DEBUG:
        return "DEBUG";
      case VPLogLevel.INFO:
        return " INFO";
      case VPLogLevel.MAX:
        break;
    }
    return " NONE";
  }

  static void _writeFile(String log) async {
    if (_logFile == null || _logFileIO == null) return;
    try {
      List<int> listLogs = utf8.encode(log);
      var encodeStr = logEncode(Uint8List.fromList(listLogs));
      _logFileIO?.writeln(encodeStr);
      _logFileSize += encodeStr.length;

      if (_logFileSize > _maxFileSize) {
        await _logFileIO?.flush();
        await _logFileIO?.close();
        if (_logListener != null) {
          await _logListener!(_logFile!);
        }
        _logFile?.deleteSync();
        _logFile?.createSync();
        _logFileIO = _logFile?.openWrite(mode: FileMode.write);
        _logFileSize = 0;
      }
    } catch (ex) {}
  }

  static String _fourDigits(int n) {
    int absN = n.abs();
    if (absN >= 1000) return "$n";
    if (absN >= 100) return "0$absN";
    if (absN >= 10) return "00$absN";
    return "000$absN";
  }

  static String _sixDigits(int n) {
    int absN = n.abs();
    if (absN >= 100000) return "$n";
    if (absN >= 10000) return "0$absN";
    if (absN >= 1000) return "00$absN";
    if (absN >= 100) return "000$absN";
    if (absN >= 10) return "000$absN";
    return "00000$absN";
  }

  static String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  static String _dateString(DateTime date) {
    String y = _fourDigits(date.year);
    String m = _twoDigits(date.month);
    String d = _twoDigits(date.day);
    String h = _twoDigits(date.hour);
    String min = _twoDigits(date.minute);
    String sec = _twoDigits(date.second);
    String ms = _sixDigits(date.millisecond * 1000 + date.microsecond);
    return "$y-$m-$d $h:$min:$sec.$ms";
  }

  static void _log(Object msg,
      {String tag = "APP",
      bool writeFile = false,
      VPLogLevel level = VPLogLevel.INFO,
      VPLogStackTraceInfo? stack}) {
    if (msg == null) msg = "null";
    if (level.index < _logLevel.index && writeFile == false) return;
    if (stack == null) stack = VPLogStackTraceInfo(StackTrace.current, 0);
    stack.parseTrace();
    var date = DateTime.now();
    String data =
        '${_dateString(date)} [${_levelString(level)}] [${stack?.fileName}:${stack?.lineNumber}] ${stack?.funName} :[$tag] $msg';
    if (level.index >= _logLevel.index) print(data);
    if (writeFile) _writeFile(data);
  }

  static void _nativeLog(dynamic data) {
    _writeFile(data);
  }

  static void printLog(String msg) {
    _log(msg,
        level: VPLogLevel.INFO,
        stack: VPLogStackTraceInfo(StackTrace.current, 5));
  }

  static void printError(Object error, StackTrace stackTrace) {
    List<String> str = [];
    if (error != null) str.addAll(error.toString().split("\n"));
    if (stackTrace != null) str.addAll(stackTrace.toString().split("\n"));
    for (var o in str) {
      _log(o,
          tag: "ERR",
          writeFile: true,
          level: VPLogLevel.ERROR,
          stack: VPLogStackTraceInfo(StackTrace.current, 1));
    }
  }

  /// 初始化日志记录器
  static init(
      {VPLogLevel logLevel = VPLogLevel.INFO,
      int logFileSize = 30,
      String? logFilePath}) {
    _maxFileSize = logFileSize * 1024 * 1024;
    _logLevel = logLevel;
    if (_logFileIO == null) {
      try {
        if (logFilePath != null)
          _logFile = File(logFilePath);
        else
          _logFile = File("${Directory.systemTemp.path}/logs.log");
        if (!_logFile!.existsSync()) {
          _logFile?.createSync();
        }
        _logFileSize = _logFile!.lengthSync();
        _logFileIO = _logFile?.openWrite(mode: FileMode.append);
      } catch (ex) {}
    }
    _logEvent.receiveBroadcastStream().listen(_nativeLog);
    _logMethod.invokeMethod("vp_log_set_level", [_logLevel.index]);
  }

  static void warn(Object object,
      {String tag = "APP", bool writeFile = false}) {
    _log(object,
        level: VPLogLevel.WARN,
        writeFile: writeFile,
        tag: tag,
        stack: VPLogStackTraceInfo(StackTrace.current, 1));
  }

  static void error(Object object,
      {String tag = "APP", bool writeFile = false}) {
    _log(object,
        level: VPLogLevel.ERROR,
        writeFile: writeFile,
        tag: tag,
        stack: VPLogStackTraceInfo(StackTrace.current, 1));
  }

  static void file(Object object, {String tag = "APP"}) {
    _log(object,
        level: VPLogLevel.FILE,
        writeFile: true,
        tag: tag,
        stack: VPLogStackTraceInfo(StackTrace.current, 1));
  }

  static File? getLogFile() {
    return _logFile;
  }

  static void setLogFileFullListener(LogFileFullListener listener) {
    _logListener = listener;
  }
}
