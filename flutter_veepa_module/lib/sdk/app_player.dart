import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ffi';

import 'app_dart.dart';

enum VideoSourceType {
  /// 文件源
  FILE_SOURCE,

  /// 设备实时源
  LIVE_SOURCE,

  /// 设备TF卡回放源
  CARD_SOURCE,

  /// 网络下载源
  NETWORK_SOURCE,

  /// TF卡时间轴回放源
  TimeLine_SOURCE,

  ///
  SUB_PLAYER_SOURCE,

  //SUB2_PLAYER_SOURCE,

  ///移动端设备视频源
  CAMERA_VIDEO_SOURCE,
}

abstract class VideoSource {
  final VideoSourceType sourceType;

  VideoSource(this.sourceType);

  dynamic getSource();
}

class FileVideoSource extends VideoSource {
  FileVideoSource(this.filePath) : super(VideoSourceType.FILE_SOURCE);
  final String filePath;

  @override
  getSource() {
    return filePath;
  }
}

class LiveVideoSource extends VideoSource {
  LiveVideoSource(this.clientPtr) : super(VideoSourceType.LIVE_SOURCE);
  final int clientPtr;

  @override
  getSource() {
    return clientPtr;
  }
}

class CameraVideoSource extends VideoSource {
  CameraVideoSource(this.clientPtr, {this.dir = 0, this.frameRate = 8})
      : super(VideoSourceType.CAMERA_VIDEO_SOURCE);
  final int clientPtr;
  final int dir;
  final int frameRate;

  @override
  getSource() {
    return [clientPtr, dir, frameRate];
  }
}

class CardVideoSource extends VideoSource {
  CardVideoSource(this.clientPtr, this.size, {this.checkHead = 1})
      : super(VideoSourceType.CARD_SOURCE);
  final int clientPtr;
  final int size;
  final int checkHead;

  @override
  getSource() {
    return [clientPtr, size, checkHead];
  }
}

class TimeLineSource extends VideoSource {
  TimeLineSource(this.clientPtr) : super(VideoSourceType.TimeLine_SOURCE);
  final int clientPtr;

  @override
  getSource() {
    return [clientPtr];
  }
}

class NetworkVideoSource extends VideoSource {
  NetworkVideoSource(this.urls) : super(VideoSourceType.NETWORK_SOURCE);
  final List<String> urls;

  @override
  getSource() {
    return urls;
  }
}

class SubPlayerSource extends VideoSource {
  SubPlayerSource() : super(VideoSourceType.SUB_PLAYER_SOURCE);

  @override
  getSource() {}
}

// class Sub2PlayerSource extends VideoSource {
//   Sub2PlayerSource() : super(VideoSourceType.SUB2_PLAYER_SOURCE);
//
//   @override
//   getSource() {}
// }

enum VideoStatus { STOP, STARTING, PLAY, PAUSE }

enum VoiceStatus { PLAY, STOP }

enum RecordStatus { PLAY, STOP }

enum RecordEncoderType { ADPCM, G711, PCM }

enum SoundTouchType {
  /// 无效果
  TOUCH_0,

  /// 大叔
  TOUCH_1,

  /// 搞怪
  TOUCH_2
}

typedef CreatedCallback<T> = void Function(T data);
typedef StateChangeCallback<T> = void Function(
    T data,
    VideoStatus videoStatus,
    VoiceStatus voiceStatus,
    RecordStatus recordStatus,
    SoundTouchType touchType);
typedef ProgressChangeCallback<T> = void Function(T data, int totalSec,
    int playSec, int progress, int loadState, int velocity, int timestamp);

typedef FocalChangeCallback<T> = void Function(T data, int focal);

typedef GPSChangeCallback<T> = void Function(
    T data,
    int fixStatus,
    int satellitesinview,
    double latitude,
    double logitude,
    double speed,
    double course);

typedef IFrameCountChangeCallback<T> = void Function(T data, int frameCount);
typedef VideoHeadInfoCallback<T> = void Function(
    T data, int resolution, int channel, int type);

typedef DrawChangeCallback<T> = void Function(
    T data,
    int width,
    int height,
    int draw_type,
    double percent_x1,
    double percent_y1,
    double percent_x2,
    double percent_y2);

class AppPlayerController<T> {
  static const MethodChannel app_player_channel =
      const MethodChannel('app_player');

  static const EventChannel app_player_event =
      const EventChannel("app_player/event");

  static Stream _eventStream = app_player_event.receiveBroadcastStream();

  static final DynamicLibrary playerLib = Platform.isAndroid
      ? DynamicLibrary.open('libOKSMARTPLAY.so')
      : DynamicLibrary.process();

  void Function(int playerPtr, double minScale, double maxScale, int minFocal,
      int maxFocal, int direction, double threshold)? appPlayerSetScale;
  void Function(
      int playerPtr,
      double minScale,
      double maxScale,
      int minFocal,
      int maxFocal,
      int direction,
      double threshold,
      double x,
      double y)? appPlayerSetScaleCenter;
  void Function(int playerPtr, int channel, int key)? appPlayerSetChannel;
  int Function(int playerPtr, int cameraPtr)? appPlayerEnableCamera;
  int Function(int playerPtr)? appPlayerDisableCamera;
  int Function(int playerPtr, int channel)? appPlayerSetVoiceChannel;
  void Function(int playerPtr, int deviceType, int nvrFour, int nvrIndex)?
      appPlayerSetDeviceType;

  void scale(int direction, int minFocal, int maxFocal, double minScale,
      double maxScale, double threshold) {
    if (appPlayerSetScale == null) return;
    if (minScale < 1.0) minScale = 1.0;
    if (maxScale < 1.0) maxScale = 1.0;
    appPlayerSetScale!(
        playerId, minScale, maxScale, minFocal, maxFocal, direction, threshold);
  }

  void scaleCenter(int direction, int minFocal, int maxFocal, double minScale,
      double maxScale, double threshold, double x, double y) {
    if (appPlayerSetScale == null) return;
    if (minScale < 1.0) minScale = 1.0;
    if (maxScale < 1.0) maxScale = 1.0;
    appPlayerSetScaleCenter!(playerId, minScale, maxScale, minFocal, maxFocal,
        direction, threshold, x, y);
  }

  void setChannelKey(int channel, int key) {
    appPlayerSetChannel!(playerId, channel, key);
  }

  void setDeviceType(int deviceType, int nvrFour, int nvrIndex) {
    appPlayerSetDeviceType!(playerId, deviceType, nvrFour, nvrIndex);
  }

  StreamSubscription? _subscription;

  T? userData;

  AppPlayerController({this.changeCallback, this.userData}) {
    // _subscription = _eventStream.listen(progressListener);
    appPlayerSetScale = playerLib
        .lookup<
            NativeFunction<
                Void Function(Int64, Double, Double, Uint8, Uint8, Int8,
                    Double)>>("app_player_set_scale")
        .asFunction();
    appPlayerSetScaleCenter = playerLib
        .lookup<
            NativeFunction<
                Void Function(Int64, Double, Double, Uint8, Uint8, Int8, Double,
                    Double, Double)>>("app_player_set_scale_center")
        .asFunction();

    appPlayerSetChannel = playerLib
        .lookup<NativeFunction<Void Function(Int64, Int32, Int32)>>(
            "app_player_set_channel")
        .asFunction();
    appPlayerSetVoiceChannel = playerLib
        .lookup<NativeFunction<Int32 Function(Int64, Int32)>>(
            "app_player_set_voice_channel")
        .asFunction();

    appPlayerEnableCamera = playerLib
        .lookup<NativeFunction<Int32 Function(Int64, Int64)>>(
            "app_player_enable_camera")
        .asFunction();
    appPlayerDisableCamera = playerLib
        .lookup<NativeFunction<Int32 Function(Int64)>>(
            "app_player_disable_camera")
        .asFunction();

    appPlayerSetDeviceType = playerLib
        .lookup<NativeFunction<Void Function(Int64, Int32, Int32, Int32)>>(
            "app_player_set_device_type")
        .asFunction();
    AppDart().addListener(progressListener);
    AppDart().addGPSListener(gpsListener);
    AppDart().addVideoHeadListener(headInfoListener);
    AppDart().addDrawListener(drawListener);
  }

  CreatedCallback<T?>? createdCallback;
  StateChangeCallback<T?>? changeCallback;
  List<ProgressChangeCallback<T?>> progressCallbacks = [];
  List<FocalChangeCallback<T?>> focalCallbacks = [];
  List<GPSChangeCallback<T?>> gpsCallbacks = [];
  List<VideoHeadInfoCallback<T?>> headCallbacks = [];
  List<IFrameCountChangeCallback<T>> iFrameCountCallbacks = [];
  List<DrawChangeCallback<T?>> drawCallbacks = [];

  bool isCreated = false;
  int textureId = 0;
  int playerId = 0;
  VideoSourceType? sourceType;
  VoiceStatus _voiceStatus = VoiceStatus.STOP;

  VoiceStatus get voiceStatus => _voiceStatus;

  set voiceStatus(VoiceStatus value) {
    if (value != _voiceStatus) {
      _voiceStatus = value;
      if (changeCallback != null)
        changeCallback!(userData, _videoStatus, _voiceStatus, _recordStatus,
            _soundTouchType);
    }
  }

  VideoStatus _videoStatus = VideoStatus.STOP;

  VideoStatus get videoStatus => _videoStatus;

  set videoStatus(VideoStatus value) {
    if (value != _videoStatus) {
      _videoStatus = value;
      if (changeCallback != null)
        changeCallback!(userData, _videoStatus, _voiceStatus, _recordStatus,
            _soundTouchType);
    }
  }

  RecordStatus _recordStatus = RecordStatus.STOP;

  RecordStatus get recordStatus => _recordStatus;

  set recordStatus(RecordStatus value) {
    if (value != _recordStatus) {
      _recordStatus = value;
      if (changeCallback != null)
        changeCallback!(userData, _videoStatus, _voiceStatus, _recordStatus,
            _soundTouchType);
    }
  }

  SoundTouchType _soundTouchType = SoundTouchType.TOUCH_0;

  SoundTouchType get soundTouchType => _soundTouchType;

  set soundTouchType(SoundTouchType value) {
    if (value != _soundTouchType) {
      _soundTouchType = value;
      if (changeCallback != null)
        changeCallback!(userData, _videoStatus, _voiceStatus, _recordStatus,
            _soundTouchType);
    }
  }

  void setCreatedCallback(CreatedCallback<T?> callback) {
    this.createdCallback = callback;
  }

  void setStateChangeCallback(StateChangeCallback<T?> callback) {
    this.changeCallback = callback;
  }

  void addProgressChangeCallback(ProgressChangeCallback<T?> callback) {
    this.progressCallbacks.add(callback);
  }

  void removeProgressChangeCallback(ProgressChangeCallback<T?> callback) {
    this.progressCallbacks.remove(callback);
  }

  void clearProgressChangeCallback() {
    this.progressCallbacks.clear();
  }

  void addFocalChangeCallback(FocalChangeCallback<T?> callback) {
    this.focalCallbacks.add(callback);
  }

  void removeFocalChangeCallback(FocalChangeCallback<T> callback) {
    this.focalCallbacks.remove(callback);
  }

  void clearFocalChangeCallback() {
    this.focalCallbacks.clear();
  }

  void addGPSChangeCallback(GPSChangeCallback<T?> callback) {
    this.gpsCallbacks.add(callback);
  }

  void removeGPSChangeCallback(GPSChangeCallback<T> callback) {
    this.gpsCallbacks.remove(callback);
  }

  void clearGPSChangeCallback() {
    this.gpsCallbacks.clear();
  }

  void addHeadInfoCallback(VideoHeadInfoCallback<T?> callback) {
    this.headCallbacks.add(callback);
  }

  void removeHeadInfoCallback(VideoHeadInfoCallback<T> callback) {
    this.headCallbacks.remove(callback);
  }

  void clearHeadInfoCallback() {
    this.headCallbacks.clear();
  }

  void addIFrameCountChangeCallback(IFrameCountChangeCallback<T> callback) {
    this.iFrameCountCallbacks.add(callback);
  }

  void removeIFrameCountChangeCallback(IFrameCountChangeCallback<T> callback) {
    this.iFrameCountCallbacks.remove(callback);
  }

  void clearIFrameCountChangeCallback() {
    this.iFrameCountCallbacks.clear();
  }

  void addDrawChangeCallback(DrawChangeCallback<T?> callback) {
    this.drawCallbacks.add(callback);
  }

  void removeDrawChangeCallback(DrawChangeCallback<T> callback) {
    this.drawCallbacks.remove(callback);
  }

  void clearDrawChangeCallback() {
    this.drawCallbacks.clear();
  }

  dynamic source;

  int totalSec = 0,
      playSec = 0,
      progress = 0,
      velocity = 0,
      loadState = 0,
      focal = 0,
      version = 0,
      timestamp = 0,
      mainFrameCount = 0;

  bool changedProgress = false;

  void progressListener(dynamic args) {
    if (args is List) {
      if (args[0] == textureId) {
        totalSec = args[1];
        playSec = args[2];
        progress = args[3];
        loadState = args[4];
        velocity = args[5];
        version = args[7];
        timestamp = args[8];
        mainFrameCount = args[9];
        if (videoStatus == VideoStatus.STARTING) {
          videoStatus = VideoStatus.PLAY;
        }

        if (loadState == 4) {
          videoStatus = VideoStatus.STARTING;
        }
        // VPLog.file(
        //     "progressListener: totalSec:$totalSec  playSec:$playSec progress:$progress loadState:$loadState velocity:$velocity version:$version videoStatus:$videoStatus timestamp:$timestamp",
        //     tag: "PLAY");
        if (args[6] != focal) {
          if (focalCallbacks.isNotEmpty) {
            for (var item in focalCallbacks) {
              item(userData, args[6]);
            }
          }
        }
        focal = args[6];
        if (progressCallbacks.isNotEmpty && changedProgress == false) {
          for (var item in progressCallbacks) {
            item(
                userData, args[1], args[2], args[3], args[4], args[5], args[8]);
          }
        }

        if (iFrameCountCallbacks.isNotEmpty) {
          for (var item in iFrameCountCallbacks) {
            item(userData!, args[9]);
          }
        }
      }
    }
  }

  int? fixStatus, satellitesinview;
  double? latitude, logitude, speed, course;

  void gpsListener(dynamic args) {
    if (args is List) {
      if (args[0] == textureId) {
        fixStatus = args[1];
        satellitesinview = args[2];
        latitude = args[3];
        logitude = args[4];
        speed = args[5];
        course = args[6];
        // VPLog.file(
        //     "gpsListener: fixStatus:$fixStatus  satellitesinview:$satellitesinview latitude:$latitude logitude:$logitude speed:$speed course:$course",
        //     tag: "PLAY");
        if (gpsCallbacks.isNotEmpty) {
          for (var item in gpsCallbacks) {
            item(
                userData, args[1], args[2], args[3], args[4], args[5], args[6]);
          }
        }
      }
    }
  }

  int? resolution, channel, type;

  void headInfoListener(dynamic args) {
    if (args is List) {
      if (args[0] == textureId) {
        resolution = args[1];
        channel = args[2];
        type = args[3];
        // VPLog.file(
        //     "headInfoListener: resolution:$resolution",
        //     tag: "PLAY");
        if (headCallbacks.isNotEmpty) {
          for (var item in headCallbacks) {
            item(userData, args[1], args[2], args[3]);
          }
        }
      }
    }
  }

  int? width, height, draw_type;
  double? percent_x1, percent_y1, percent_x2, percent_y2;

  void drawListener(dynamic args) {
    if (args is List) {
      if (args[0] == textureId) {
        width = args[1];
        height = args[2];
        draw_type = args[3];
        percent_x1 = args[4];
        percent_y1 = args[5];
        percent_x2 = args[6];
        percent_y2 = args[7];
        // VPLog.file(
        //     "drawListener: width:$width  height:$height draw_type:$draw_type x1:$percent_x1 y1:$percent_y1 x2:$percent_x2 y2:$percent_y2",
        //     tag: "PLAY");
        if (drawCallbacks.isNotEmpty) {
          for (var item in drawCallbacks) {
            item(userData, args[1], args[2], args[3], args[4], args[5], args[6],
                args[7]);
          }
        }
      }
    }
  }

  AppPlayerController? sub_controller;
  AppPlayerController? sub2_controller;
  AppPlayerController? sub3_controller;

  Future<bool> create({int audioRate = 8000}) async {
    // VPLog.file("start", tag: "PLAY");
    if (isCreated == true) {
      // VPLog.file("isCreated:$isCreated end", tag: "PLAY");
      return true;
    }
    var result = await app_player_channel
        .invokeMapMethod("app_player_create", [0, 0, audioRate]);
    if (result == null || result["result"] == false) {
      // VPLog.file("result:$result error", tag: "PLAY");
      return false;
    }
    textureId = result["textureId"];
    if (result.containsKey("playerId"))
      playerId = result["playerId"];
    else
      playerId = 0;
    isCreated = true;
    if (createdCallback != null) {
      createdCallback!(userData);
    }
    // VPLog.file("textureId:$textureId end", tag: "PLAY");
    return true;
  }

  ///
  /// 设置视频源
  ///
  /// [sourceType] 视频源类型
  /// [source] 视频源
  /// 如果[sourceType]为[VideoSourceType.VIDEO_FILE_SOURCE]
  /// source应该为文件路径
  ///
  /// 如果[sourceType]为[VideoSourceType.VIDEO_LIVE_SOURCE]
  /// source应该为设备指针
  ///
  /// 如果[sourceType]为[VideoSourceType.VIDEO_CARD_SOURCE]
  /// source应该为设备指针
  ///
  /// 如果[sourceType]为[VideoSourceType.VIDEO_NETWORK_SOURCE]
  /// source应该为下载地址
  Future<bool> setVideoSource(VideoSource source) async {
    if (isCreated == false) return false;
    // VPLog.file("textureId:$textureId source:$source start", tag: "PLAY");

    if (source is FileVideoSource) {
      if (source.filePath == null ||
          File(source.filePath).existsSync() == false) {
        // VPLog.file("textureId:$textureId error", tag: "PLAY");
        return false;
      }
    }
    if (source is NetworkVideoSource) {
      if (source.urls == null || source.urls.isEmpty) {
        // VPLog.file("textureId:$textureId error", tag: "PLAY");
        return false;
      }
    }
    if (source is LiveVideoSource) {
      if (source.clientPtr == null || source.clientPtr == 0) {
        // VPLog.file("textureId:$textureId error", tag: "PLAY");
        return false;
      }
    }

    if (source is CameraVideoSource) {
      if (source.clientPtr == null || source.clientPtr == 0) {
        // VPLog.file("textureId:$textureId error", tag: "PLAY");
        return false;
      }
    }

    if (source is CardVideoSource) {
      if (source.clientPtr == null || source.clientPtr == 0) {
        // VPLog.file("textureId:$textureId error", tag: "PLAY");
        return false;
      }
      if (source.size == null || source.size < 0) {
        // VPLog.file("textureId:$textureId error", tag: "PLAY");
        return false;
      }
    }

    if (source is TimeLineSource) {
      if (source.clientPtr == null || source.clientPtr == 0) {
        // VPLog.file("textureId:$textureId error", tag: "PLAY");
        return false;
      }
    }
    print(
        "--setVideoSource---${this.textureId}----${source.sourceType.index}-------${source.getSource()}----------------");

    var result = await app_player_channel.invokeMethod("app_player_source",
        [this.textureId, source.sourceType.index, source.getSource()]);
    if (result == true) {
      this.sourceType = source.sourceType;
      this.source = source;
    }
    // VPLog.file("textureId:$textureId result:$result end", tag: "PLAY");
    return result;
  }

  int cameraPlayerId = 0;

  bool enableCameraPlayer(int playerPtr) {
    if (playerId == 0 || cameraPlayerId != 0) return false;
    int ret = appPlayerEnableCamera!(playerId, playerPtr);
    if (ret == 0) cameraPlayerId = playerPtr;
    return ret == 0;
  }

  bool disableCameraPlayer() {
    if (playerId == 0 || cameraPlayerId == 0) return false;
    appPlayerDisableCamera!(playerId);
    cameraPlayerId = 0;
    return true;
  }

  void setVoiceChannel(int channel) {
    appPlayerSetVoiceChannel!(playerId, channel);
  }

  Future<bool> enableSubPlayer(AppPlayerController controller) async {
    if (sub_controller != null) return true;
    var result = await app_player_channel.invokeMethod(
        "app_player_enable_sub_player", [this.textureId, controller.textureId]);
    sub_controller = controller;
    // VPLog.file(
    //     "textureId:$textureId subTextureId:${controller
    //         .textureId} result:$result end",
    //     tag: "PLAY");
    return result;
  }

  Future<bool> enableSub2Player(AppPlayerController controller) async {
    if (sub2_controller != null) return true;
    var result = await app_player_channel.invokeMethod(
        "app_player_enable_sub2_player",
        [this.textureId, controller.textureId]);
    sub2_controller = controller;
    // VPLog.file(
    //     "textureId:$textureId sub2TextureId:${controller
    //         .textureId} result:$result end",
    //     tag: "PLAY");
    return result;
  }

  Future<bool> enableSub3Player(AppPlayerController controller) async {
    if (sub3_controller != null) return true;
    var result = await app_player_channel.invokeMethod(
        "app_player_enable_sub3_player",
        [this.textureId, controller.textureId]);
    sub3_controller = controller;
    // VPLog.file(
    //     "textureId:$textureId sub3TextureId:${controller
    //         .textureId} result:$result end",
    //     tag: "PLAY");
    return result;
  }

  Future<bool> disableSubPlayer() async {
    if (sub_controller == null) return true;
    var result = await app_player_channel.invokeMethod(
        "app_player_disable_sub_player", this.textureId);

    // VPLog.file(
    //     "textureId:$textureId subTextureId:${sub_controller
    //         .textureId} result:$result end",
    //     tag: "PLAY");
    sub_controller = null;
    if (sub2_controller != null) {
      sub2_controller = null;
    }
    if (sub3_controller != null) {
      sub3_controller = null;
    }
    return result;
  }

  Future<bool> start() async {
    // VPLog.file(
    //     "textureId:$textureId videoStatus:$videoStatus source:$source start",
    //     tag: "PLAY");
    if (source == null) return false;
    var result = await app_player_channel.invokeMethod(
        "app_player_start", this.textureId);
    if (result == true) {
      if (videoStatus == VideoStatus.STOP)
        this.videoStatus = VideoStatus.STARTING;
    }
    // VPLog.file("textureId:$textureId result:$result end", tag: "PLAY");
    return result;
  }

  Future<bool> startVoice() async {
    if (source == null) return false;
    // VPLog.file("textureId:$textureId start", tag: "PLAY");
    var result = await app_player_channel.invokeMethod(
        "app_player_start_voice", this.textureId);
    if (result == true) {
      this.voiceStatus = VoiceStatus.PLAY;
    }
    // VPLog.file("textureId:$textureId result:$result end", tag: "PLAY");
    return result;
  }

  Future<bool> startRecord(
      {RecordEncoderType encoderType = RecordEncoderType.G711}) async {
    if (source == null) return false;
    var result = await app_player_channel.invokeMethod(
        "app_player_start_record", [this.textureId, encoderType.index]);
    if (result == true) {
      this.recordStatus = RecordStatus.PLAY;
    }
    return result;
  }

  Future<bool> stop() async {
    if (videoStatus == VideoStatus.STOP) return true;
    // VPLog.file("textureId:$textureId start", tag: "PLAY");
    var result = await app_player_channel.invokeMethod(
        "app_player_stop", this.textureId);
    if (result == true) {
      this.videoStatus = VideoStatus.STOP;
    }
    // VPLog.file("textureId:$textureId result:$result end", tag: "PLAY");
    return result;
  }

  Future<bool> stopVoice() async {
    if (source == null) return false;
    // VPLog.file("textureId:$textureId start", tag: "PLAY");
    var result = await app_player_channel.invokeMethod(
        "app_player_stop_voice", this.textureId);
    if (result == true) {
      this.voiceStatus = VoiceStatus.STOP;
    }
    // VPLog.file("textureId:$textureId result:$result end", tag: "PLAY");
    return result;
  }

  Future<bool> stopRecord() async {
    if (source == null) return false;
    // VPLog.file("textureId:$textureId start", tag: "PLAY");
    var result = await app_player_channel.invokeMethod(
        "app_player_stop_record", this.textureId);
    if (result == true) {
      this.recordStatus = RecordStatus.STOP;
    }
    // VPLog.file("textureId:$textureId result:$result end", tag: "PLAY");
    return result;
  }

  Future<bool> pause() async {
    if (videoStatus == VideoStatus.PAUSE) return true;
    if (videoStatus != VideoStatus.PLAY) return false;
    var result = await app_player_channel.invokeMethod(
        "app_player_pause", this.textureId);
    if (result == true) {
      this.videoStatus = VideoStatus.PAUSE;
    }
    return result;
  }

  Future<bool> flipCamera(int front) async {
    // if (videoStatus == VideoStatus.PAUSE) return true;
    // if (videoStatus != VideoStatus.PLAY) return false;
    var result = await app_player_channel
        .invokeMethod("flip_camera", [this.textureId, front]);
    return result;
  }

  Future<bool> isFrontCamera() async {
    var result = await app_player_channel
        .invokeMethod("isFrontCamera", [this.textureId]);
    return result;
  }

  Future<bool> resume() async {
    if (videoStatus == VideoStatus.PLAY) return true;
    if (videoStatus != VideoStatus.PAUSE) return false;
    var result = await app_player_channel.invokeMethod(
        "app_player_resume", this.textureId);
    if (result == true) {
      this.videoStatus = VideoStatus.PLAY;
    }
    return result;
  }

  Future<bool> setProgress(int duration,
      {bool timeLine = false, int channel = 2, int key = 0}) async {
    if (isCreated == false) return false;
    if (source == null) return false;
    if (videoStatus == VideoStatus.STOP) return false;
    if (duration >= totalSec && timeLine == false) return false;
    if (duration == playSec) return true;
    changedProgress = true;
    var result = await app_player_channel.invokeMethod(
        "app_player_progress", [this.textureId, duration, channel, key]);
    changedProgress = false;
    if (result == true) {
      playSec = duration;
    }
    return result;
  }

  Future<bool> screenshot(String filePath,
      {String imageSize = "0",
      double widthPercent = 0,
      double heightPercent = 0,
      int sub = 0}) async {
    if (isCreated == false) return false;
    if (source == null) return false;
    int destWidth = 0;
    int destHeight = 0;
    if (imageSize != "0" && imageSize.contains("x")) {
      var list = imageSize.split("x").toList();
      destWidth = int.tryParse(list.first) ?? 0;
      destHeight = int.tryParse(list.last) ?? 0;
    }

    return await app_player_channel.invokeMethod("app_player_screenshot", [
      this.textureId,
      filePath,
      destWidth,
      destHeight,
      widthPercent,
      heightPercent,
      sub
    ]);
  }

  Future<bool> setSoundTouch(SoundTouchType touchType) async {
    if (isCreated == false) return false;
    if (source == null) return false;
    var result = await app_player_channel.invokeMethod(
        "app_player_soundTouch", [this.textureId, touchType.index]);
    if (result == true) {
      this.soundTouchType = touchType;
    }
    return result;
  }

  double playSpeed = 0;

  Future<bool> setSpeed(double speed) async {
    if (isCreated == false) return false;
    if (source == null) return false;
    if (source is LiveVideoSource) {
      return false;
    }
    if (speed != 1.0) await stopVoice();
    var result = await app_player_channel
        .invokeMethod("app_player_speed", [this.textureId, speed]);
    if (result == true) {
      this.playSpeed = speed;
    }
    return result;
  }

  Future<int> save(String filePath,
      {int start = 0, int end = 0xFFFFFFFF}) async {
    if (isCreated == false) return -1;
    if (source == null) return -1;
    return await app_player_channel.invokeMethod(
        "app_player_save", [this.textureId, filePath, start, end]);
  }

  Future<int> saveNVR(String filePath,
      {int start = 0, int end = 0xFFFFFFFF, int index = 0}) async {
    if (isCreated == false) return -1;
    if (source == null) return -1;
    return await app_player_channel.invokeMethod(
        "app_player_save_nvr", [this.textureId, filePath, start, end, index]);
  }

  Future<bool> startDown(String filePath) async {
    if (isCreated == false) return false;
    if (source == null) return false;
    return await app_player_channel
        .invokeMethod("app_player_start_down", [this.textureId, filePath]);
  }

  Future<bool> stopDown() async {
    if (isCreated == false) return false;
    if (source == null) return false;
    return await app_player_channel
        .invokeMethod("app_player_stop_down", [this.textureId]);
  }

  static Future<bool> saveMP4(String srcPath, String destPath,
      {int enableSub = 0,
      int destWidth = 0,
      int destHeight = 0,
      int audioRate = 8000}) async {
    if (Platform.isAndroid) {
      destWidth = 0;
      destHeight = 0;
    }
    return await app_player_channel.invokeMethod("app_player_save_mp4",
        [srcPath, destPath, enableSub, destWidth, destHeight, audioRate]);
  }

  static Future<bool> saveWAVE(String srcPath, String destPath,
      {int channel = 1, int fmt = 16, int rate = 8000}) async {
    return await app_player_channel.invokeMethod(
        "app_player_save_wave", [srcPath, destPath, channel, fmt, rate]);
  }

  Future<bool> clearCacheData() async {
    return await app_player_channel
        .invokeMethod("app_player_clear", [this.textureId]);
  }

  static Future<bool> saveMP4Rate(String srcPath, String destPath,
      {double rate = 1.0}) async {
    return await app_player_channel
        .invokeMethod("app_player_save_mp4_rate", [srcPath, destPath, rate]);
  }

  void dispose() async {
    if (isCreated == false) return;
    isCreated = false;
    progressCallbacks.clear();
    focalCallbacks.clear();
    gpsCallbacks.clear();
    headCallbacks.clear();
    if (_subscription != null) _subscription!.cancel();
    AppDart().rmvListener(progressListener);
    AppDart().rmvGPSListener(gpsListener);
    AppDart().rmvVideoHeadListener(headInfoListener);
    AppDart().rmvDrawListener(drawListener);
    await app_player_channel.invokeMethod("app_player_stop", this.textureId);
    await app_player_channel.invokeMethod("app_player_destroy", this.textureId);
  }
}

class AppPlayerView extends StatelessWidget {
  const AppPlayerView({Key? key, required this.controller}) : super(key: key);
  final AppPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double width = constraints.constrainWidth();
      double height = constraints.constrainHeight();
      width = width * window.devicePixelRatio;
      height = height * window.devicePixelRatio;
      if (controller.isCreated == false) {
        return FutureBuilder(
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.done) {
              if (asyncSnapshot.data == true) {
                return Container(
                  color: Colors.black,
                  child: Texture(textureId: controller.textureId),
                );
              }
            }
            return Container();
          },
          future: controller.create(),
        );
      }
      // controller.changeSize(width, height);
      return Container(
        color: Colors.black,
        child: Texture(textureId: controller.textureId),
      );
    });
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != AppPlayerView) {
      return false;
    }
    if (other is AppPlayerView) {
      return controller == other.controller;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(this, controller);
}
