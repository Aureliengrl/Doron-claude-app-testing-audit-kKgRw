$path = "lib\pages\new_pages\onboarding_advanced\onboarding_advanced_widget.dart"
$content = Get-Content -Path $path -Raw -Encoding UTF8

# 1. Add import if not present
if (-not $content.Contains("import 'package:doron/services/voice_assistant_service.dart';")) {
    $content = $content -replace "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';`nimport 'package:doron/services/voice_assistant_service.dart';"
}

# 2. Add state variables
$stateVars = @"
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  bool _isRecording = false;
  String _currentTranscript = '';

  @override
"@
$content = $content -replace "(?s)class _OnboardingAdvancedWidgetState extends State<OnboardingAdvancedWidget> \{.*?@override", $stateVars

# 3. Add to dispose
$disposeLogic = @"
  void dispose() {
    _voiceService.dispose();
    _model.dispose();
"@
$content = $content -replace "(?s)void dispose\(\) \{\s*_model.dispose\(\);", $disposeLogic

# 4. Add to _buildStepContent
$newBuildStepContent = @"
    } else if (type == 'slider') {
      return _buildSliderScreen(stepData);
    } else if (type == 'voice_recording') {
      return _buildVoiceRecordingScreen(stepData);
    }
"@
$content = $content -replace "(?s)\} else if \(type == 'slider'\) \{\s*return _buildSliderScreen\(stepData\);\s*\}", $newBuildStepContent

# 5. Inject _buildVoiceRecordingScreen before _buildSliderScreen
$voiceRecordingWidget = @"
  Widget _buildVoiceRecordingScreen(Map<String, dynamic> stepData) {
    final field = stepData['field'] as String;
    
    // RÃ©cupÃ©rer le texte dÃ©jÃ  enregistrÃ© s'il y en a
    if (_currentTranscript.isEmpty && _model.answers[field] != null && _model.answers[field] is String && (_model.answers[field] as String).isNotEmpty) {
       _currentTranscript = _model.answers[field] as String;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Text(
          stepData['question'] as String,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (stepData['subtitle'] != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              stepData['subtitle'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 40),
        
        // Zone de texte transcrit
        Container(
          width: double.infinity,
          minHeight: 120,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isRecording ? violetColor.withOpacity(0.1) : Colors.black26,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isRecording ? violetColor : Colors.white12,
              width: _isRecording ? 2 : 1,
            ),
          ),
          child: _currentTranscript.isEmpty
              ? Center(
                  child: Text(
                    _isRecording ? 'Je vous Ã©coute...' : 'Appuyez sur le micro pour parler',
                    style: GoogleFonts.poppins(
                      color: _isRecording ? violetColor : Colors.white38,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Text(
                  _currentTranscript,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
        ),
        
        const SizedBox(height: 40),
        
        // Bouton Micro
        GestureDetector(
          onTap: () async {
            if (_isRecording) {
              await _voiceService.stopListening();
              setState(() {
                _isRecording = false;
                _model.answers[field] = _currentTranscript;
              });
            } else {
              final initialized = await _voiceService.initialize();
              if (initialized) {
                _voiceService.onTranscriptUpdate = (text) {
                  setState(() {
                    _currentTranscript = text;
                    _model.answers[field] = text;
                  });
                };
                await _voiceService.startListening();
                setState(() => _isRecording = true);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Impossible d''accÃ©der au microphone')),
                  );
                }
              }
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isRecording ? 90 : 80,
            height: _isRecording ? 90 : 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? Colors.red : violetColor,
              boxShadow: [
                if (_isRecording)
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                if (!_isRecording)
                  BoxShadow(
                    color: violetColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderScreen(Map<String, dynamic> stepData) {
"@
$content = $content -replace "(?s)  Widget _buildSliderScreen\(Map<String, dynamic> stepData\) \{", $voiceRecordingWidget

Set-Content -Path $path -Value $content -Encoding UTF8
