import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; //
import 'package:flutter_tts/flutter_tts.dart'; // TTS
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../secrets.dart';

class GuideTab extends StatefulWidget {
  const GuideTab({super.key});

  @override
  State<GuideTab> createState() => _GuideTabState();
}

enum GuideViewMode { step, text, audio, video }

class _GuideTabState extends State<GuideTab> {
  String? _selectedGuide;

  // 현재 선택된 탭
  GuideViewMode _viewMode = GuideViewMode.step;

  final TextEditingController _promptController = TextEditingController();
  String? _aiGuideText;

  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoFuture;

  late FlutterTts _tts;
  bool _isSpeaking = false;

  final List<EmergencyType> _emergencyTypes = [
    EmergencyType(
      id: 'cardiac',
      title: '심정지',
      icon: Icons.favorite,
      color: Colors.red,
      bgColor: Color(0xFFFFEBEE),
      description: 'CPR 및 AED 사용법',
      steps: ['의식 확인', '119 신고', '가슴압박 시작', 'AED 사용'],

      //
      textGuide:
          '🫀 심정지 발생 시 반드시 기억해야 할 핵심 원칙\n'
          '심정지는 한 순간에 생명을 위협하는 치명적인 응급상황입니다.\n'
          '가장 중요한 것은 “지체 없이, 정확하게, 침착하게” 행동하는 것입니다.\n\n'
          '1. 반응 및 호흡 확인\n'
          '환자의 어깨를 가볍게 두드리며 크게 외치세요.\n'
          '“괜찮으세요? 들리시면 대답해보세요!”\n'
          '반응이 없고 정상 호흡이 없다면 즉시 다음 단계로 이동합니다.\n\n'
          '2. 119 신고 및 주변 지원 요청\n'
          '가능한 경우 주변인에게 도움을 요청하세요.\n'
          '“119에 신고해주세요! 그리고 AED 가져와주세요!”\n'
          '혼자라면 휴대전화 스피커폰을 켜고 신고를 유지하며 CPR을 진행합니다.\n\n'
          '3. 가슴압박 시작 (CPR)\n'
          '환자를 딱딱하고 평평한 바닥에 눕힙니다.\n'
          '흉골 중앙에 두 손을 포갠 후 팔을 곧게 펴고 빠르고 강하게 압박합니다.\n'
          '• 압박 깊이: 5cm 이상\n'
          '• 압박 속도: 분당 100~120회\n'
          '• 이완 완전 확보: 너무 빠른 압박은 금물\n'
          '• 중단 시간 최소화: 1초의 지체도 생존율을 떨어뜨립니다.\n\n'
          '4. AED 사용\n'
          'AED가 도착하면 즉시 전원을 켜고 음성 안내를 따릅니다.\n'
          '• 패드를 맨 가슴에 정확히 부착합니다.\n'
          '• 분석 중 환자에게 절대 손대지 않습니다.\n'
          '• “충격 버튼을 누르십시오” 안내 시, 주변 모두에게 외칩니다.\n'
          '  “떨어지세요! 손대지 마세요!”\n'
          '• 충격 후 즉시 가슴압박을 재개합니다.\n\n'
          '💡 중요한 팁\n'
          '• 잘못된 CPR보다 ‘늦어진 CPR’이 더 위험합니다.\n'
          '• 신속하고 정확한 행동이 생명을 살립니다.\n'
          '• 힘이 들면 주변인과 교대로 압박하여 고품질 CPR을 유지하세요.',
      videoGuide: 'assets/audio/heart_stop.mp4',

      ttsSteps: [
        '1단계: 반응 및 호흡 확인. 환자의 어깨를 가볍게 두드리며 크게 외치세요. “괜찮으세요? 들리시면 대답해보세요!” ',
        '반응이 없고 정상 호흡이 없다면 즉시 다음 단계로 이동합니다.',
        '2단계: 119 신고 및 주변 지원 요청. 가능한 경우 주변인에게 도움을 요청하세요. ',
        '"119에 신고해주세요! 그리고 AED를 가져와주세요!” 라고 알려주세요',
        '혼자라면 휴대전화 스피커폰을 켜고 신고를 유지하며 CPR을 진행합니다.',
        '3단계: 가슴압박 시작. 환자를 딱딱하고 평평한 바닥에 눕힙니다.',
        '흉골 중앙에 두 손을 포갠 후 팔을 곧게 펴고 빠르고 강하게 압박합니다.',
        '압박 깊이는 5cm 이상, 압박 속도는 분당 100에서 120회입니다.',
        ' 이완을 완전히 확보하고 중단 시간을 최소화하세요.',
        '4단계: AED 사용. AED가 도착하면 즉시 전원을 켜고 음성 안내를 따릅니다. ',
        '패드를 맨 가슴에 정확히 부착하고 분석 중에는 환자에게 절대 손대지 마세요.',
        ' “충격 버튼을 누르십시오” 안내 시, 주변 모두에게 외칩니다. ',
        '“떨어지세요! 손대지 마세요!” 충격 후 즉시 가슴압박을 재개합니다.',
      ],
    ),
    EmergencyType(
      id: 'choking',
      title: '기도 막힘',
      icon: Icons.air,
      color: Colors.blue,
      bgColor: Color(0xFFE3F2FD),
      description: '하임리히법 안내',
      steps: ['환자 상태 확인', '복부 압박', '이물질 제거', '호흡 확인'],

      //textguide
      textGuide:
          '🫁 기도 막힘 응급처치 핵심 가이드\n'
          '기도가 막히면 신속하고 정확한 대응이 생명을 구합니다.\n'
          '다음은 하임리히법을 포함한 기도 막힘 시 응급처치 방법입니다.\n\n'
          '1. 환자 상태 확인\n'
          '환자가 기침을 할 수 있는지, 말을 할 수 있는지 확인하세요.\n'
          '• 기침/말 가능: 환자에게 계속 기침하도록 격려합니다.\n'
          '• 기침/말 불가능: 즉시 다음 단계로 이동합니다.\n\n'
          '2. 도움 요청 및 119 신고\n'
          '주변인에게 도움을 요청하고 119에 신고하도록 지시하세요.\n'
          '혼자라면 즉시 119에 신고하고 도움을 요청하세요.\n\n'
          '3. 하임리히법 실시\n'
          '환자의 뒤에 서서 양팔로 환자를 감싸 안습니다.\n'
          '한 손을 주먹 쥐고, 다른 손으로 주먹을 감싸 쥡니다.\n'
          '주먹을 환자의 배꼽과 흉골 사이에 위치시킵니다.\n'
          '강하고 빠르게 위쪽과 안쪽으로 압박합니다.\n'
          '• 반복: 이물질이 제거되거나 환자가 의식을 잃을 때까지 반복합니다.\n\n'
          '4. 의식 상실 시 CPR 실시\n'
          '환자가 의식을 잃으면 즉시 바닥에 눕히고 CPR을 시작하세요.\n'
          '• 가슴압박: 분당 100~120회의 속도로 깊게 압박합니다.\n'
          '• 인공호흡: 가능하면 인공호흡도 실시합니다.\n\n'
          '💡 중요한 팁\n'
          '• 하임리히법은 성인과 어린이에게 적용됩니다. 영유아는 다른 방법이 필요합니다.\n'
          '• 이물질이 제거되지 않으면 즉시 의료기관으로 이송해야 합니다.',
      videoGuide: 'assets/audio/block_breath.mp4',

      ttsSteps: [
        '1단계: 환자가 기침이 가능한지 확인하세요.',
        '기침이 가능하면 계속 기침하도록 격려하세요.',
        '2단계: 기침이 불가능하면 즉시 119에 신고하세요.',
        '3단계: 하임리히법 실시. 환자 뒤에서 양팔로 감싸고 배꼽 위를 강하게 위로 당겨 압박합니다.',
        '압박을 반복하여 이물질이 나오는지 확인하세요.',
        '4단계: 환자가 의식을 잃으면 즉시 CPR을 시작하세요.',
      ],
    ),
    EmergencyType(
      id: 'bleeding',
      title: '출혈',
      icon: Icons.water_drop,
      color: Colors.redAccent,
      bgColor: Color(0xFFFFEBEE),
      description: '지혈 및 압박법',
      steps: ['깨끗한 천 준비', '직접 압박', '상처 부위 높이기', '압박 유지'],

      //textguide
      textGuide:
          '🩸 출혈 응급처치 핵심 가이드\n'
          '출혈은 신속한 대응이 필요한 응급상황입니다.\n'
          '다음은 출혈 시 지혈 및 압박법을 포함한 응급처치 방법입니다.\n\n'
          '1. 안전 확보 및 환자 상태 확인\n'
          '먼저 주변 환경이 안전한지 확인하세요.\n'
          '환자의 의식과 호흡 상태를 점검합니다.\n\n'
          '2. 도움 요청 및 119 신고\n'
          '주변인에게 도움을 요청하고 119에 신고하도록 지시하세요.\n'
          '심한 출혈이거나 환자가 의식을 잃으면 즉시 119에 신고하세요.\n\n'
          '3. 직접 압박 실시\n'
          '깨끗한 천이나 붕대를 사용하여 상처 부위를 직접 압박합니다.\n'
          '• 압박: 상처 부위를 강하게 눌러 혈류를 차단합니다.\n'
          '• 교체: 천이 혈액으로 젖으면 새로운 천으로 교체하지 말고 계속 압박합니다.\n\n'
          '4. 상처 부위 높이기\n'
          '가능하면 상처 부위를 심장보다 높게 유지하여 혈류를 줄입니다.\n\n'
          '5. 압박 유지 및 관찰\n'
          '출혈이 멈출 때까지 압박을 유지합니다.\n'
          '환자의 상태를 지속적으로 관찰하고 필요시 추가 도움을 요청하세요.\n\n'
          '💡 중요한 팁\n'
          '• 출혈이 심할 경우, 지체 없이 전문 의료기관으로 이송해야 합니다.\n'
          '• 감염 예방을 위해 가능한 한 깨끗한 재료를 사용하세요.',
      videoGuide: 'assets/audio/mor_blood.mp4',

      ttsSteps: [
        '1단계: 주변이 안전한지 확인하고 환자 상태를 확인하세요.',
        '2단계: 심한 출혈이면 즉시 119에 신고하세요.',
        '3단계: 깨끗한 천이나 붕대로 상처를 강하게 직접 압박하세요.',
        '천이 피로 젖어도 절대 떼지 말고 계속 눌러주세요.',
        '4단계: 가능하면 상처 부위를 심장보다 높게 올려주세요.',
        '5단계: 출혈이 멈출 때까지 압박을 유지하고 환자 상태를 계속 관찰하세요.',
      ],
    ),
    EmergencyType(
      id: 'burn',
      title: '화상',
      icon: Icons.local_fire_department,
      color: Colors.orange,
      bgColor: Color(0xFFFFF3E0),
      description: '화상 응급처치',
      steps: ['열원 제거', '찬물로 식히기', '물집 보호', '깨끗한 천으로 덮기'],

      textGuide:
          '🔥 화상 응급처치 핵심 가이드\n'
          '화상은 신속하고 적절한 처치가 필요합니다.\n'
          '다음은 화상 시 응급처치 방법입니다.\n\n'
          '1. 열원 제거\n'
          '화상을 일으킨 열원(불, 뜨거운 액체 등)에서 환자를 즉시 멀리 이동시킵니다.\n\n'
          '2. 찬물로 식히기\n'
          '화상 부위를 즉시 찬물(15~25°C)로 최소 10분 이상 식힙니다.\n'
          '• 주의: 얼음물이나 매우 차가운 물은 사용하지 마세요.\n\n'
          '3. 물집 보호\n'
          '물집이 생겼다면 터뜨리지 말고 자연스럽게 두세요.\n'
          '감염 위험이 있으므로 물집을 건드리지 않는 것이 중요합니다.\n\n'
          '4. 깨끗한 천으로 덮기\n'
          '화상 부위를 깨끗한 비닐 랩이나 멸균 거즈로 덮어 보호합니다.\n'
          '• 주의: 면봉이나 솜은 사용하지 마세요.\n\n'
          '💡 중요한 팁\n'
          '• 심한 화상(3도 화상)이나 얼굴, 손, 발, 생식기 부위의 화상은 즉시 전문 의료기관으로 이송해야 합니다.\n'
          '• 통증 완화를 위해 진통제를 복용할 수 있습니다.',
      videoGuide: 'assets/audio/burns.mp4',

      ttsSteps: [
        '1단계: 열원을 즉시 제거하고 환자를 안전한 곳으로 이동시키세요.',
        '2단계: 화상 부위를 흐르는 찬물에 10분 이상 식히세요.',
        '얼음물은 사용하지 마세요.',
        '3단계: 물집은 터뜨리지 말고 그대로 두세요.',
        '4단계: 화상 부위를 깨끗한 거즈나 비닐 랩으로 가볍게 덮어주세요.',
        '5단계: 얼굴, 손, 발, 생식기 화상이거나 통증이 심하면 즉시 119에 신고하세요.',
      ],
    ),
    EmergencyType(
      id: 'seizure',
      title: '발작/경련',
      icon: Icons.warning,
      color: Colors.purple,
      bgColor: Color(0xFFF3E5F5),
      description: '발작 시 대응법',
      steps: ['주변 정리', '옆으로 눕히기', '시간 체크', '움직임 관찰'],

      textGuide:
          '⚡ 경련/발작 응급처치 핵심 가이드\n'
          '경련이나 발작은 신속하고 침착한 대응이 필요합니다.\n'
          '다음은 발작 시 응급처치 방법입니다.\n\n'
          '1. 주변 정리\n'
          '환자 주변의 위험한 물건(날카로운 물건, 가구 등)을 치워 안전한 공간을 만듭니다.\n\n'
          '2. 옆으로 눕히기\n'
          '환자를 옆으로 눕혀 기도가 확보되도록 합니다.\n'
          '• 주의: 환자의 입에 아무것도 넣지 마세요.\n\n'
          '3. 시간 체크\n'
          '발작이 시작된 시간을 기록하여 의료진에게 알릴 수 있도록 합니다.\n\n'
          '4. 움직임 관찰\n'
          '발작 동안 환자의 움직임을 관찰하고, 발작이 5분 이상 지속되거나 반복될 경우 즉시 119에 신고합니다.\n\n'
          '💡 중요한 팁\n'
          '• 발작 후 환자가 혼란스러워할 수 있으므로 안정시켜 주세요.\n'
          '• 발작이 끝난 후에도 환자가 의식을 회복하지 못하면 즉시 의료기관으로 이송해야 합니다.',
      videoGuide: 'assets/audio/crazy.mp4',

      ttsSteps: [
        '1단계: 환자 주변의 위험한 물건을 치워 안전한 공간을 확보하세요.',
        '2단계: 환자를 억지로 눌러 움직임을 막지 마세요.',
        '3단계: 발작이 시작된 시간을 기록하세요.',
        '4단계: 발작이 끝나면 환자를 옆으로 눕혀 기도를 확보하세요.',
        '발작이 5분 이상 지속되거나 반복되면 즉시 119에 신고하세요.',
      ],
    ),
    EmergencyType(
      id: 'infant',
      title: '영유아 CPR',
      icon: Icons.child_care,
      color: Colors.pink,
      bgColor: Color(0xFFFCE4EC),
      description: '영유아 특화 처치',
      steps: ['두 손가락 압박', '부드러운 압박', '호흡 확인', '즉시 신고'],
      textGuide:
          '👶 영유아 CPR 응급처치 핵심 가이드\n'
          '영유아는 성인과 다른 특화된 CPR 방법이 필요합니다.\n'
          '다음은 영유아 CPR 시 응급처치 방법입니다.\n\n'
          '1. 반응 및 호흡 확인\n'
          '영유아의 어깨를 가볍게 두드리며 크게 외치세요.\n'
          '“괜찮으세요? 들리시면 대답해보세요!”\n'
          '반응이 없고 정상 호흡이 없다면 즉시 다음 단계로 이동합니다.\n\n'
          '2. 119 신고 및 주변 지원 요청\n'
          '가능한 경우 주변인에게 도움을 요청하세요.\n'
          '“119에 신고해주세요! 그리고 AED 가져와주세요!”\n'
          '혼자라면 휴대전화 스피커폰을 켜고 신고를 유지하며 CPR을 진행합니다.\n\n'
          '3. 가슴압박 시작 (CPR)\n'
          '영유아를 딱딱하고 평평한 바닥에 눕힙니다.\n'
          '두 손가락(검지와 중지)을 사용하여 흉골 중앙에 위치시킵니다.\n'
          '부드럽고 빠르게 압박합니다.\n'
          '• 압박 깊이: 약 4cm\n'
          '• 압박 속도: 분당 100~120회\n'
          '• 이완 완전 확보: 너무 빠른 압박은 금물\n'
          '• 중단 시간 최소화: 1초의 지체도 생존율을 떨어뜨립니다.\n\n'
          '4. AED 사용\n'
          'AED가 도착하면 즉시 전원을 켜고 음성 안내를 따릅니다.\n'
          '• 패드를 맨 가슴에 정확히 부착합니다.\n'
          '• 분석 중 환자에게 절대 손대지 않습니다.\n'
          '• “충격 버튼을 누르십시오” 안내 시, 주변 모두에게 외칩니다.\n'
          '  “떨어지세요! 손대지 마세요!”\n'
          '• 충격 후 즉시 가슴압박을 재개합니다.\n\n'
          '💡 중요한 팁\n'
          '• 영유아는 성인과 다른 CPR 방법이 필요합니다. 반드시 두 손가락을 사용하세요.\n'
          '• 신속하고 정확한 행동이 생명을 살립니다.\n'
          '• 힘이 들면 주변인과 교대로 압박하여 고품질 CPR을 유지하세요.',
      videoGuide: 'assets/audio/baby_CPR.mp4',

      ttsSteps: [
        '1단계: 영유아의 어깨를 가볍게 두드리며 반응과 호흡을 확인하세요.',
        '2단계: 반응이 없으면 즉시 119에 신고하세요.',
        '3단계: 두 손가락으로 흉골 중앙을 약 4cm 깊이로 빠르게 압박하세요.',
        '압박 속도는 분당 100에서 120회입니다.',
        '4단계: 호흡이 없으면 인공호흡 2회를 시행하세요.',
        '5단계: AED가 도착하면 패드를 붙이고 음성 안내를 따르세요.',
      ],
    ),
    EmergencyType(
      id: 'fracture',
      title: '골절',
      icon: Icons.accessibility_new,
      color: Colors.teal,
      bgColor: Colors.teal,
      description: '골절 시 응급 대처',
      steps: ['움직이지 않게 고정', '냉찜질', '압박 금지', '119 신고'],
    ),
    EmergencyType(
      id: 'poison',
      title: '중독',
      icon: Icons.warning_amber,
      color: Colors.green,
      bgColor: Colors.green,
      description: '중독 응급처치',
      steps: ['노출 차단', '의식 확인', '구토 유도 금지', '119 신고'],
    ),
    EmergencyType(
      id: 'hypoglycemia',
      title: '저혈당',
      icon: Icons.local_cafe,
      color: Colors.brown,
      bgColor: Colors.brown,
      description: '저혈당 처리',
      steps: ['증상 확인', '당 섭취', '휴식', '호전 없으면 119'],
    ),
    EmergencyType(
      id: 'dehydration',
      title: '탈수',
      icon: Icons.opacity,
      color: Colors.blueGrey,
      bgColor: Colors.blueGrey,
      description: '탈수 응급처치',
      steps: ['시원한 곳으로 이동', '수분 보충', '휴식', '심하면 병원 방문'],
    ),
    EmergencyType(
      id: 'heatstroke',
      title: '열사병',
      icon: Icons.wb_sunny,
      color: Colors.deepOrange,
      bgColor: Colors.deepOrange,
      description: '고열 환경에서 발생',
      steps: ['즉시 그늘 이동', '옷 느슨하게', '물 보급', '필요시 병원'],
    ),
    EmergencyType(
      id: 'hypothermia',
      title: '저체온증',
      icon: Icons.ac_unit,
      color: Colors.lightBlue,
      bgColor: Colors.lightBlue,
      description: '저체온증 응급처치',
      steps: ['따뜻한 곳 이동', '젖은 옷 제거', '담요 덮기', '서서히 체온 올리기'],
    ),
    EmergencyType(
      id: 'traffic',
      title: '교통사고',
      icon: Icons.car_crash,
      color: Colors.indigo,
      bgColor: Colors.indigo,
      description: '사고 현장 응급 대처',
      steps: ['현장 안전 확보', '환자 확인', '출혈 여부 확인', '즉시 신고'],
    ),
    EmergencyType(
      id: 'animal',
      title: '동물 상처',
      icon: Icons.pets,
      color: Colors.brown,
      bgColor: Colors.brown,
      description: '개·고양이·야생동물 상처',
      steps: ['상처 세척', '지혈', '소독', '병원 방문'],
    ),
  ];
  @override
  void initState() {
    super.initState();

    _tts = FlutterTts();

    // 언어, 속도 기본값 설정 (한국어)
    _tts.setLanguage('ko-KR');
    _tts.setSpeechRate(0.5); // 0.0 ~ 1.0 (느리게 ~ 빠르게)
    _tts.setPitch(1.0); // 목소리 톤

    // 말하기가 끝났을 때 상태 업데이트 (옵션)
    _tts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  // 선택된 항목의 텍스트를 읽어주는 함수
  Future<void> _speakText(String text) async {
    await _tts.stop(); // 혹시 이전에 읽고 있으면 정지
    await _tts.setLanguage('ko-KR'); // 혹시 몰라 다시 설정
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    setState(() {
      _isSpeaking = true;
    });

    await _tts.speak(text);
    // 말하기 끝난 후 상태는 completionHandler에서 false로 바뀜
  }

  Future<void> _speakGuide(EmergencyType emergency) async {
    final List<String>? tts = emergency.ttsSteps;

    final String text;
    if (tts != null && tts.isNotEmpty) {
      // ttsSteps 전부를 한 번에 이어서 읽기
      text = tts.join(' ');
    } else if (emergency.textGuide != null && emergency.textGuide!.isNotEmpty) {
      // ttsSteps가 없으면 예전처럼 textGuide 읽기
      text = emergency.textGuide!;
    } else {
      text = '${emergency.title} 상황에 대한 음성 안내는 준비 중입니다.';
    }

    await _speakText(text);
  }

  Future<void> _toggleTts(EmergencyType emergency) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      await _speakGuide(emergency);
    }
  }

  void _initVideoPlayer(EmergencyType emergency) {
    final path = emergency.videoGuide;
    if (path == null) return;

    // 기존 컨트롤러 정리
    if (!path.toLowerCase().endsWith('.mp4')) {
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

  @override
  void dispose() {
    _videoController?.dispose();
    _tts.stop(); // TTS 정리
    _promptController.dispose(); // 컨트롤러 정리
    super.dispose();
  }

  // --- 보기 좋은 카테고리 그룹 ---
  final Map<String, List<String>> _groups = {
    "🔥 생명 위급": ['cardiac', 'choking', 'seizure'],
    "🩹 일반 응급": ['bleeding', 'burn', 'fracture', 'dehydration', 'hypoglycemia'],
    "☣ 환경·상황": ['poison', 'heatstroke', 'hypothermia'],
    "🚑 사고/외상": ['traffic', 'animal'],
    "👶 영유아": ['infant'],
  };

  @override
  Widget build(BuildContext context) {
    final selectedEmergency = _emergencyTypes.firstWhere(
      (e) => e.id == _selectedGuide,
      orElse: () => _emergencyTypes[0],
    );

    return Scrollbar(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              const Text(
                '상황별 응급 가이드',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '응급 상황을 선택하세요',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Emergency Type Selection or Detail View
              if (_selectedGuide == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔎 AI 프롬프트 영역
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
                            decoration: const InputDecoration(
                              hintText: '증상을 입력해주세요',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _onAskAiPressed,
                          child: const Text('검색'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_aiGuideText != null) _buildAiResultCard(_aiGuideText!),

                    // 🔻 기존 6개 카드 그리드
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                      itemCount: _emergencyTypes.length,
                      itemBuilder: (context, index) {
                        final emergency = _emergencyTypes[index];

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedGuide = emergency.id;
                              _viewMode = GuideViewMode.step;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  emergency.icon,
                                  size: 32,
                                  color: emergency.color,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  emergency.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                )
              else ...[
                // Back Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedGuide = null;
                        _viewMode = GuideViewMode.step; // 목록 돌아갈 때도 초기화
                      });
                    },
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('목록으로 돌아가기'),
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency Detail Card
                Container(
                  decoration: BoxDecoration(
                    color: selectedEmergency.bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
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
                            child: Icon(
                              selectedEmergency.icon,
                              color: selectedEmergency.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${selectedEmergency.title} 응급처치',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  selectedEmergency.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Badges (탭)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _buildBadge('단계별 안내', GuideViewMode.step),
                          _buildBadge('텍스트', GuideViewMode.text),
                          _buildBadge('음성', GuideViewMode.audio),
                          _buildBadge('영상', GuideViewMode.video),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 탭에 따라 다른 내용
                      _buildGuideContent(selectedEmergency),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAskAiPressed() async {
    final query = _promptController.text.trim();
    if (query.isEmpty) return;

    setState(() => _aiGuideText = '응답 생성 중입니다...');

    final answer = await _callGemini(query);

    setState(() {
      _aiGuideText = answer;
    });
  }

  Future<String> _callGemini(String query) async {
    final apiKey = Secrets.geminiApiKey; // 👈 새로 정의할 값

    if (apiKey.isEmpty) {
      return 'Gemini API 키가 설정되지 않았습니다.\n'
          'secrets_private.dart 파일에서 geminiApiKey를 설정해 주세요.';
    }

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // 키는 헤더로 전달
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {
                  "text":
                      "너는 응급처치 가이드 앱의 도우미야. 항상 한국어로 간단한 단계별 응급처치를 알려줘.\n"
                      "상황: $query\n"
                      "응급처치 방법을 단계별로 간단히 알려줘.",
                },
              ],
            },
          ],
          "generationConfig": {"maxOutputTokens": 300},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Gemini 응답 구조에 맞게 파싱
        // candidates[0].content.parts[*].text 를 이어붙이기
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          return '응답이 비어 있습니다.';
        }

        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          return '응답을 읽어오지 못했습니다.';
        }

        final buffer = StringBuffer();
        for (final p in parts) {
          final t = p['text']?.toString() ?? '';
          if (t.isNotEmpty) buffer.writeln(t);
        }

        final result = buffer.toString().trim();
        return result.isEmpty ? '응답을 읽어오지 못했습니다.' : result;
      } else {
        return 'Gemini 서버 오류: ${response.statusCode}\n${response.body}';
      }
    } catch (e) {
      return 'Gemini 요청 오류: $e';
    }
  }

  /// AI 응답을 예쁘게 보여주는 카드
  /// AI 응답을 예쁘게 보여주는 카드
  Widget _buildAiResultCard(String rawText) {
    final lines = rawText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String? title;
    List<String> steps = [];
    List<String> extraLines = [];

    final stepReg = RegExp(r'^\s*([0-9]+)[\).\s]');

    for (final line in lines) {
      if (title == null && !stepReg.hasMatch(line)) {
        title = line.replaceAll('**', '');
      } else if (stepReg.hasMatch(line)) {
        steps.add(line.replaceFirst(stepReg, '').trim());
      } else {
        extraLines.add(line);
      }
    }

    bool showMore = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.medical_information, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'AI 응급 안내',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (title != null)
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),

              const SizedBox(height: 12),

              // 간단 요약 2~3줄
              if (extraLines.isNotEmpty)
                Text(
                  extraLines.take(3).join('\n'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),

              const SizedBox(height: 10),

              // 단계 카드
              ...steps.asMap().entries.map((entry) {
                final idx = entry.key;
                final stepText = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red),
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          stepText,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 6),

              // 펼쳐보기
              if (extraLines.length > 3)
                InkWell(
                  onTap: () => setState(() => showMore = !showMore),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      showMore ? "▲ 자세한 설명 접기" : "▼ 자세한 설명 보기",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              if (showMore)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    extraLines.skip(3).join('\n'),
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),

              const SizedBox(height: 8),
              const Text(
                '※ 생명 위급 시 반드시 119를 먼저 호출하세요.',
                style: TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiResult(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.health_and_safety, color: Colors.red, size: 20),
              SizedBox(width: 6),
              Text(
                'AI 응급 안내',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 요약 제목
          Text(
            extractTitle(text),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // 단계 카드들
          ...extractSteps(text).map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, size: 16, color: Colors.red),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(step, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 주의사항
          const Text(
            '⚠️ 절단 부위를 물에 직접 넣지 마세요.\n⚠️ 출혈이 심하면 즉시 119에 신고하세요.',
            style: TextStyle(color: Colors.red, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }

  // 탭 버튼(뱃지)
  Widget _buildBadge(String label, GuideViewMode mode) {
    final bool isPrimary = _viewMode == mode;

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () {
        setState(() {
          _viewMode = mode;

          if (mode == GuideViewMode.video && _selectedGuide != null) {
            final emergency = _emergencyTypes.firstWhere(
              (e) => e.id == _selectedGuide,
            );
            _initVideoPlayer(emergency);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isPrimary ? Colors.red : Colors.grey[400]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isPrimary ? Colors.white : Colors.grey[700],
            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 탭별 내용
  Widget _buildGuideContent(EmergencyType selectedEmergency) {
    switch (_viewMode) {
      case GuideViewMode.step:
        // 단계별 안내 탭
        return Column(
          children: [
            ...selectedEmergency.steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
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
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedEmergency.color,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selectedEmergency.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 단계 제목
                      Expanded(
                        child: Text(step, style: const TextStyle(fontSize: 14)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 20),
                        onPressed: () {
                          final ttsList = selectedEmergency.ttsSteps;

                          // 해당 단계에 맞는 음성 문장 있으면 그걸 사용, 없으면 step 텍스트를 그대로 읽기
                          final String toSpeak =
                              (ttsList != null && ttsList.length > index)
                              ? ttsList[index]
                              : step;

                          _speakText(toSpeak); // 🔊 여기서는 문자열만 읽기
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // 하단 버튼: 음성/영상 가이드
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _viewMode = GuideViewMode.audio; // audio 탭으로 전환
                        // 음성 플레이어를 나중에 구현할 때 여기서 초기화하면 됨
                      });
                    },
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
                    onPressed: () {
                      setState(() {
                        _viewMode = GuideViewMode.video; // ✅ video 탭으로 전환
                        _initVideoPlayer(selectedEmergency); // ✅ 이때만 비디오 초기화
                      });
                    },
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

      case GuideViewMode.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selectedEmergency.title} 상황에서의 응급처치 방법',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              selectedEmergency.textGuide ?? '이 상황에 대한 텍스트 안내는 준비 중입니다.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        );

      case GuideViewMode.audio:
        // TTS 음성 탭
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _toggleTts(selectedEmergency),
                          icon: Icon(
                            _isSpeaking ? Icons.stop : Icons.play_arrow,
                          ),
                          label: Text(_isSpeaking ? '읽기 중지' : '전체 읽어주기'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

      case GuideViewMode.video:
        // 영상 / 이미지 공통 탭
        // 영상이 없을 경우 이미지로 대체
        final guidePath = selectedEmergency.videoGuide;

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
            //  1) mp4 → video_player로 재생
            else if (guidePath.toLowerCase().endsWith('.mp4'))
              FutureBuilder<void>(
                future: _initializeVideoFuture,
                builder: (context, snapshot) {
                  if (_videoController == null) {
                    return const Text(
                      '영상 로딩에 실패했습니다.',
                      style: TextStyle(fontSize: 14),
                    );
                  }

                  if (snapshot.connectionState != ConnectionState.done) {
                    return AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: VideoPlayer(_videoController!),
                            ),
                          ),
                          if (!_videoController!.value.isPlaying)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _videoController!.play();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 40,
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_videoController!.value.isPlaying) {
                                  _videoController!.pause();
                                } else {
                                  _videoController!.play();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              )
            //  그 외(jpg, png 등) → 이미지 표시
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      guidePath,
                      width: double.infinity, // 카드 가로 꽉 채우기
                      fit: BoxFit.fitWidth, // 가로 기준으로 맞추고 세로는 자연스럽게
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '이미지로 제공되는 단계별 응급처치 가이드입니다.\n'
                    '각 단계를 차례대로 확인하면서 따라 해 주세요.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
          ],
        );
    }
  }
}
// ---------- AI 요약 파싱 헬퍼 ----------

// 제목(첫 줄) 추출
String extractTitle(String text) {
  // 줄 단위로 나눈 뒤 빈 줄 제거
  final lines = text
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  if (lines.isEmpty) {
    return 'AI 응급 안내';
  }

  String first = lines.first;

  // 마크다운 볼드 표시(**제목**) 제거
  first = first.replaceAll('**', '').trim();

  return first;
}

// 단계별 내용 추출
List<String> extractSteps(String text) {
  final lines = text.split('\n');

  final steps = <String>[];

  for (final raw in lines) {
    var line = raw.trim();
    if (line.isEmpty) continue;

    // 1) "1. ~", "2) ~", "3- ~" 같은 번호 있는 줄
    final numbered = RegExp(r'^[0-9]+[.)\-:]\s*');
    // 2) "• ~", "- ~" 같은 불릿 줄
    final bullet = RegExp(r'^[•\-]\s*');

    if (numbered.hasMatch(line) || bullet.hasMatch(line)) {
      line = line.replaceFirst(numbered, '').replaceFirst(bullet, '').trim();
      if (line.isNotEmpty) {
        steps.add(line);
      }
    }
  }

  // 번호/불릿을 못 찾았으면 전체 문장을 하나의 단계로
  if (steps.isEmpty && text.trim().isNotEmpty) {
    steps.add(text.trim());
  }

  return steps;
}

// 데이터 모델
class EmergencyType {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String description;
  final List<String> steps; // 화면에 보이는 간단 단계 제목
  final String? textGuide; // 긴 설명 텍스트
  final String? audioGuide; // 음성
  final String? videoGuide; // 영상
  final List<String>? ttsSteps; // TTS용 단계별 텍스트

  EmergencyType({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.description,
    required this.steps,
    this.textGuide,
    this.audioGuide,
    this.videoGuide,
    this.ttsSteps,
  });
}
