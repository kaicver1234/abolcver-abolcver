enum SpeedTestStep {
  ready,
  loading,
  download,
  upload,
}

class SpeedTestResult {
  final double downloadSpeed;
  final double uploadSpeed;
  final int ping;
  final int latency;
  final double packetLoss;
  final int jitter;

  const SpeedTestResult({
    this.downloadSpeed = 0.0,
    this.uploadSpeed = 0.0,
    this.ping = 0,
    this.latency = 0,
    this.packetLoss = 0.0,
    this.jitter = 0,
  });

  SpeedTestResult copyWith({
    double? downloadSpeed,
    double? uploadSpeed,
    int? ping,
    int? latency,
    double? packetLoss,
    int? jitter,
  }) {
    return SpeedTestResult(
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      ping: ping ?? this.ping,
      latency: latency ?? this.latency,
      packetLoss: packetLoss ?? this.packetLoss,
      jitter: jitter ?? this.jitter,
    );
  }

  @override
  String toString() {
    return 'SpeedTestResult(download: ${downloadSpeed.toStringAsFixed(2)} Mbps, '
        'upload: ${uploadSpeed.toStringAsFixed(2)} Mbps, '
        'ping: $ping ms, jitter: $jitter ms)';
  }
}

class SpeedTestState {
  final SpeedTestStep step;
  final SpeedTestResult result;
  final double progress;
  final bool isConnectionStable;
  final String? errorMessage;
  final String currentPhase;
  final double currentSpeed;
  final bool hadError;
  final bool testCompleted;

  const SpeedTestState({
    this.step = SpeedTestStep.ready,
    this.result = const SpeedTestResult(),
    this.progress = 0.0,
    this.isConnectionStable = true,
    this.errorMessage,
    this.currentPhase = '',
    this.currentSpeed = 0.0,
    this.hadError = false,
    this.testCompleted = false,
  });

  SpeedTestState copyWith({
    SpeedTestStep? step,
    SpeedTestResult? result,
    double? progress,
    bool? isConnectionStable,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? currentPhase,
    double? currentSpeed,
    bool? hadError,
    bool? testCompleted,
  }) {
    return SpeedTestState(
      step: step ?? this.step,
      result: result ?? this.result,
      progress: progress ?? this.progress,
      isConnectionStable: isConnectionStable ?? this.isConnectionStable,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      currentPhase: currentPhase ?? this.currentPhase,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      hadError: hadError ?? this.hadError,
      testCompleted: testCompleted ?? this.testCompleted,
    );
  }
}
