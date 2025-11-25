import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/emergency_type.dart';
import '../utils/emergency_data.dart';
import '../services/tts_service.dart';
import '../services/stt_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ai_service.dart';
import '../widgets/guide/emergency_card.dart';
import '../widgets/guide/step_card.dart';
import '../widgets/guide/video_player_widget.dart';
import '../widgets/guide/ai_result_card.dart';

class GuideTab extends StatefulWidget {
  const GuideTab({super.key});

  @override
  State<GuideTab> createState() => _GuideTabState();
}

enum GuideViewMode { step, text, audio, video }

class _GuideTabState extends State<GuideTab> {
  String? _selectedGuide;
  GuideViewMode _viewMode = GuideViewMode.step;
  
  final TextEditingController _promptController = TextEditingController();
  String? _aiGuideText;
  
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoFuture;
  
  // Services
  late final TTSService _ttsService;
  late final STTService _sttService;
  late final AIService _aiService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// 서비스 초기화
  Future<void> _initializeServices() async {
    _ttsService = TTSService();
    _sttService = STTService();
    _aiService = AIService();

    // TTS 초기화
    try {
      await _ttsService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('음성 안내 기능을 사용할 수 없습니다')),
        );
      }
    }

    // 상태 변경 리스너 설정
    _ttsService.onSpeakingStateChanged = (isSpeaking) {
      if (mounted) setState(() {});
    };

    _sttService.onListeningStateChanged = (isListening) {
      if (mounted) setState(() {});
    };

    _sttService.onResult = (text) {
      setState(() {
        _promptController.text = text;
      });
    };
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _ttsService.dispose();
    _sttService.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _onEmergencySelected(String id) {
    setState(() {
      _selectedGuide = id;
      _viewMode = GuideViewMode.step;
    });
  }

  void _onBackPressed() {
    setState(() {
      _selectedGuide = null;
      _viewMode = GuideViewMode.step;
    });
  }

  void _onViewModeChanged(GuideViewMode mode) {
    setState(() {
      _viewMode = mode;
      if (mode == GuideViewMode.video && _selectedGuide != null) {
        final emergency = emergencyTypes.firstWhere((e) => e.id == _selectedGuide);
        _initVideoPlayer(emergency);
      }
    });
  }

  Future<void> _onAiSearchPressed() async {
    final query = _promptController.text.trim();
    if (query.isEmpty) return;

    setState(() => _aiGuideText = '응답 생성 중입니다...');
    final answer = await _aiService.getEmergencyGuide(query);
    setState(() => _aiGuideText = answer);
  }

  /// 음성 안내
  Future<void> _speakText(String text) async {
    if (!_ttsService.isAvailable) {
      _showError('음성 안내 기능을 사용할 수 없습니다');
      return;
    }

    try {
      await _ttsService.speak(text);
    } catch (e) {
      if (mounted) {
        _showError('음성 재생 중 오류가 발생했습니다');
      }
    }
  }

  /// 전체 TTS 토글
  Future<void> _toggleTts(EmergencyType emergency) async {
    if (_ttsService.isSpeaking) {
      await _ttsService.stop();
      return;
    }

    // textGuide를 우선적으로 사용 (더 자세한 설명)
    final text = emergency.textGuide ?? 
                 emergency.ttsSteps?.join(' ') ?? 
                 '${emergency.title} 상황에 대한 음성 안내는 준비 중입니다.';
    await _speakText(text);
  }

  /// 음성 입력 토글
  Future<void> _handleVoiceInput() async {
    try {
      await _sttService.toggleListening();
    } on PermissionPermanentlyDeniedException catch (e) {
      if (mounted) {
        _showPermissionError(e.toString());
      }
    } on PermissionDeniedException catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    }
  }

  /// 에러 표시
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 권한 에러 표시
  void _showPermissionError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: '설정',
          textColor: Colors.white,
          onPressed: () async {
            await openAppSettings();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _initVideoPlayer(EmergencyType emergency) {
    final path = emergency.videoGuide;
    if (path == null || !path.toLowerCase().endsWith('.mp4')) {
      _videoController?.dispose();
      _videoController = null;
      _initializeVideoFuture = null;
      return;
    }

    _videoController?.dispose();
    _videoController = VideoPlayerController.asset(path);
    _initializeVideoFuture = _videoController!.initialize().then((_) {
      setState(() {});
    });
  }

  void _toggleVideoPlayback() {
    setState(() {
      _videoController!.value.isPlaying
          ? _videoController!.pause()
          : _videoController!.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _selectedGuide == null 
                ? _buildMainView() 
                : _buildDetailView(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.menu_book, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(
              '상황별 응급 가이드',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '응급 상황을 선택하세요',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMainView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAiSearchSection(),
        const SizedBox(height: 16),
        if (_aiGuideText != null) ...[
          AiResultCard(rawText: _aiGuideText!),
          const SizedBox(height: 16),
        ],
        _buildEmergencyGrid(),
      ],
    );
  }

  Widget _buildAiSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '응급 상황을 입력해주세요',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promptController,
                decoration: InputDecoration(
                  hintText: '증상을 입력하거나 말해주세요',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _sttService.isListening ? Icons.mic : Icons.mic_none,
                      color: _sttService.isListening ? Colors.red : Colors.grey,
                    ),
                    onPressed: _handleVoiceInput,
                    tooltip: '음성 입력',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _onAiSearchPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('검색'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencyGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: emergencyTypes.length,
      itemBuilder: (context, index) {
        final emergency = emergencyTypes[index];
        return EmergencyCard(
          emergency: emergency,
          onTap: () => _onEmergencySelected(emergency.id),
        );
      },
    );
  }

  Widget _buildDetailView() {
    final emergency = emergencyTypes.firstWhere((e) => e.id == _selectedGuide);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _onBackPressed,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('목록으로 돌아가기'),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: emergency.bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailHeader(emergency),
              const SizedBox(height: 16),
              _buildViewModeTabs(),
              const SizedBox(height: 16),
              _buildGuideContent(emergency),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailHeader(EmergencyType emergency) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(emergency.icon, color: emergency.color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${emergency.title} 응급처치',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                emergency.description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeTabs() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _buildTabBadge('단계별 안내', GuideViewMode.step),
        _buildTabBadge('텍스트', GuideViewMode.text),
        _buildTabBadge('음성', GuideViewMode.audio),
        _buildTabBadge('영상', GuideViewMode.video),
      ],
    );
  }

  Widget _buildTabBadge(String label, GuideViewMode mode) {
    final isActive = _viewMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => _onViewModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isActive ? Colors.red : Colors.grey[400]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGuideContent(EmergencyType emergency) {
    switch (_viewMode) {
      case GuideViewMode.step:
        return _buildStepView(emergency);
      case GuideViewMode.text:
        return _buildTextView(emergency);
      case GuideViewMode.audio:
        return _buildAudioView(emergency);
      case GuideViewMode.video:
        return _buildVideoView(emergency);
    }
  }

  Widget _buildStepView(EmergencyType emergency) {
    return Column(
      children: [
        ...emergency.steps.asMap().entries.map((entry) {
          return StepCard(
            emergency: emergency,
            index: entry.key,
            step: entry.value,
            onSpeakPressed: () {
              final ttsList = emergency.ttsSteps;
              final toSpeak = (ttsList != null && ttsList.length > entry.key)
                  ? ttsList[entry.key]
                  : entry.value;
              _speakText(toSpeak);
            },
          );
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _onViewModeChanged(GuideViewMode.audio),
                icon: const Text('🔊', style: TextStyle(fontSize: 16)),
                label: const Text('음성 안내', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _onViewModeChanged(GuideViewMode.video),
                icon: const Text('📹', style: TextStyle(fontSize: 16)),
                label: const Text('영상 가이드', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextView(EmergencyType emergency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${emergency.title} 상황에서의 응급처치 방법',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          emergency.textGuide ?? '이 상황에 대한 텍스트 안내는 준비 중입니다.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildAudioView(EmergencyType emergency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '음성 안내',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이 항목의 텍스트 내용을 음성으로 안내합니다.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _ttsService.isAvailable ? () => _toggleTts(emergency) : null,
                  icon: Icon(_ttsService.isSpeaking ? Icons.stop : Icons.play_arrow),
                  label: Text(_ttsService.isSpeaking ? '읽기 중지' : '전체 읽어주기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoView(EmergencyType emergency) {
    final guidePath = emergency.videoGuide;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '영상 / 이미지 가이드',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (guidePath == null)
          const Text(
            '이 상황에 대한 영상/이미지 가이드는 준비 중입니다.',
            style: TextStyle(fontSize: 14),
          )
        else if (guidePath.toLowerCase().endsWith('.mp4'))
          VideoPlayerWidget(
            controller: _videoController,
            initializeFuture: _initializeVideoFuture,
            onPlayPause: _toggleVideoPlayback,
          )
        else
          _buildImageGuide(guidePath),
      ],
    );
  }

  Widget _buildImageGuide(String path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(path, width: double.infinity, fit: BoxFit.fitWidth),
        ),
        const SizedBox(height: 8),
        const Text(
          '이미지로 제공되는 단계별 응급처치 가이드입니다.\n'
          '각 단계를 차례대로 확인하면서 따라 해 주세요.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}
