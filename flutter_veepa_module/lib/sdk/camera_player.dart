import 'package:get/get_rx/src/rx_types/rx_types.dart';

import 'app_player.dart';

enum VideoState {
  /// 默认状态
  none,

  /// 准备中
  starting,

  /// 正在播放
  playing,

  /// 暂停
  pause,

  /// 停止
  stop,

  /// 出现错误
  error,
}

enum AudioState {
  /// 默认状态
  none,

  /// 正在播放
  play,

  /// 停止
  stop,

  /// 出现错误
  error,
}

class CameraPlayer {
  int clientPtr = 0;

  /// 图形绘制纹理
  Rx<int> texture = Rx<int>(0);

  /// 播放控制器
  late AppPlayerController controller;

  /// 视频状态
  Rx<VideoState> videoState = Rx<VideoState>(VideoState.none);

  /// 音频状态
  Rx<AudioState> audioState = Rx<AudioState>(AudioState.none);

  /// 视频时长
  /// 秒为单位
  var duration = 0.obs;

  /// 播放进度
  /// 秒为单位
  var progress = 0.obs;
}
