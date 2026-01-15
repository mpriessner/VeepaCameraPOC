import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/sdk_integration_service.dart';
import 'package:veepa_camera_poc/services/real_connection_adapter.dart';
import 'package:veepa_camera_poc/services/real_video_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoPlaybackState', () {
    test('has all expected values', () {
      expect(VideoPlaybackState.values, contains(VideoPlaybackState.stopped));
      expect(VideoPlaybackState.values, contains(VideoPlaybackState.initializing));
      expect(VideoPlaybackState.values, contains(VideoPlaybackState.buffering));
      expect(VideoPlaybackState.values, contains(VideoPlaybackState.playing));
      expect(VideoPlaybackState.values, contains(VideoPlaybackState.paused));
      expect(VideoPlaybackState.values, contains(VideoPlaybackState.error));
    });
  });

  group('VideoFrameMetrics', () {
    test('creates with default values', () {
      final metrics = VideoFrameMetrics.empty();

      expect(metrics.textureId, equals(0));
      expect(metrics.frameCount, equals(0));
      expect(metrics.fps, equals(0));
    });

    test('creates with custom values', () {
      final metrics = VideoFrameMetrics(
        textureId: 1,
        frameCount: 100,
        fps: 30.0,
        width: 1920,
        height: 1080,
      );

      expect(metrics.textureId, equals(1));
      expect(metrics.frameCount, equals(100));
      expect(metrics.fps, equals(30.0));
      expect(metrics.width, equals(1920));
      expect(metrics.height, equals(1080));
    });
  });

  group('RealVideoAdapter', () {
    late MockVeepaSDK sdk;
    late RealConnectionAdapter connection;
    late RealVideoAdapter video;

    setUp(() async {
      sdk = MockVeepaSDK();
      await sdk.initialize();
      connection = RealConnectionAdapter(
        sdk: sdk,
        deviceId: 'TEST123',
        password: 'password',
      );
      video = RealVideoAdapter(connection: connection);
    });

    tearDown(() {
      video.dispose();
      connection.dispose();
    });

    test('starts in stopped state', () {
      expect(video.state, equals(VideoPlaybackState.stopped));
      expect(video.isPlaying, isFalse);
    });

    test('play fails when not connected', () async {
      final result = await video.play();

      expect(result, isFalse);
      expect(video.state, equals(VideoPlaybackState.error));
    });

    test('play succeeds when connected', () async {
      await connection.connect();

      final result = await video.play();

      expect(result, isTrue);
      expect(video.state, equals(VideoPlaybackState.playing));
    });

    test('stop transitions to stopped', () async {
      await connection.connect();
      await video.play();

      await video.stop();

      expect(video.state, equals(VideoPlaybackState.stopped));
    });

    test('pause transitions to paused', () async {
      await connection.connect();
      await video.play();

      video.pause();

      expect(video.state, equals(VideoPlaybackState.paused));
    });

    test('resume from pause transitions to playing', () async {
      await connection.connect();
      await video.play();
      video.pause();

      video.resume();

      expect(video.state, equals(VideoPlaybackState.playing));
    });

    test('toggleMute toggles mute state', () async {
      expect(video.isMuted, isFalse);

      video.toggleMute();
      expect(video.isMuted, isTrue);

      video.toggleMute();
      expect(video.isMuted, isFalse);
    });

    test('switchChannel changes channel', () async {
      expect(video.channel, equals(0));

      await video.switchChannel(1);

      expect(video.channel, equals(1));
    });
  });
}
