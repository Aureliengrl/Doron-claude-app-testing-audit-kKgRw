import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:confetti/confetti.dart';
import '/utils/iconly_compat.dart';
import '/services/first_time_service.dart';
import '/components/liquid_glass.dart';

class UserOnboardingFlowPage extends StatefulWidget {
  const UserOnboardingFlowPage({super.key});

  static const String routeName = 'UserOnboarding';
  static const String routePath = '/setup-profile';

  @override
  State<UserOnboardingFlowPage> createState() => _UserOnboardingFlowPageState();
}

class _UserOnboardingFlowPageState extends State<UserOnboardingFlowPage> {
  final PageController _pageController = PageController();
  late ConfettiController _confettiController;

  static const Color _violet = Color(0xFF8A2BE2);
  static const Color _pink = Color(0xFFEC4899);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _gold = Color(0xFFF59E0B);

  int _currentStep = 0;
  static const int _totalSteps = 5;
  bool _isSaving = false;

  // --- Step 1: Profil & Identité ---
  File? _profileImageFile;
  int _selectedAvatarIndex = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _handleController = TextEditingController();
  DateTime? _dateOfBirth;
  final String _selectedGender = 'femme';
  bool _isCheckingHandle = false;
  bool? _isHandleValid;
  String? _handleError;

  // --- Step 2: Passions & Hobbies (multi-select) ---
  final Set<String> _selectedPassions = {'Mode & Style', 'Tech & Gadgets'};

  // --- Step 3: Cadeaux Préférés (multi-select) ---
  final Set<String> _selectedGiftTypes = {'Vêtements & Sneakers', 'High-tech'};

  // --- Step 4: Tailles & Budget ---
  String _clothingSize = 'M';
  String _shoeSize = '39';
  String _budgetTier = '25€ - 75€';

  // Avatars avec dégradés et icônes
  final List<Map<String, dynamic>> _avatars = const [
    {'icon': Icons.face_rounded, 'colors': [Color(0xFF8A2BE2), Color(0xFFEC4899)]},
    {'icon': Icons.face_3_rounded, 'colors': [Color(0xFFEC4899), Color(0xFFF59E0B)]},
    {'icon': Icons.face_6_rounded, 'colors': [Color(0xFF06B6D4), Color(0xFF6366F1)]},
    {'icon': Icons.face_2_rounded, 'colors': [Color(0xFF10B981), Color(0xFF06B6D4)]},
    {'icon': Icons.face_4_rounded, 'colors': [Color(0xFFF59E0B), Color(0xFFEF4444)]},
    {'icon': Icons.face_5_rounded, 'colors': [Color(0xFF6366F1), Color(0xFF8A2BE2)]},
  ];

  // Liste des passions
  final List<Map<String, dynamic>> _passionsList = const [
    {'name': 'Mode & Style', 'icon': Icons.checkroom_rounded, 'color': Color(0xFFEC4899)},
    {'name': 'Tech & Gadgets', 'icon': Icons.devices_rounded, 'color': Color(0xFF6366F1)},
    {'name': 'Gaming', 'icon': Icons.sports_esports_rounded, 'color': Color(0xFF8A2BE2)},
    {'name': 'Beauté & Soins', 'icon': Icons.spa_rounded, 'color': Color(0xFFF43F5E)},
    {'name': 'Déco & Maison', 'icon': Icons.weekend_rounded, 'color': Color(0xFF06B6D4)},
    {'name': 'Sport & Fitness', 'icon': Icons.fitness_center_rounded, 'color': Color(0xFF10B981)},
    {'name': 'Gastronomie & Vins', 'icon': Icons.restaurant_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'Lecture & Mangas', 'icon': Icons.menu_book_rounded, 'color': Color(0xFF3B82F6)},
    {'name': 'Voyages & Nature', 'icon': Icons.flight_takeoff_rounded, 'color': Color(0xFF14B8A6)},
    {'name': 'Musique & Concerts', 'icon': Icons.headphones_rounded, 'color': Color(0xFFA855F7)},
    {'name': 'Art & Création', 'icon': Icons.palette_rounded, 'color': Color(0xFFFB923C)},
    {'name': 'Animaux', 'icon': Icons.pets_rounded, 'color': Color(0xFFEAB308)},
  ];

  // Liste des types de cadeaux
  final List<Map<String, dynamic>> _giftTypesList = const [
    {'name': 'Vêtements & Sneakers', 'icon': Icons.shopping_bag_outlined, 'desc': 'Sapes, baskets, style'},
    {'name': 'High-tech', 'icon': Icons.headphones_rounded, 'desc': 'Casques, audio, gadgets'},
    {'name': 'Expériences & Sorties', 'icon': Icons.celebration_outlined, 'desc': 'Concerts, week-ends, resto'},
    {'name': 'Parfums & Soins', 'icon': Icons.auto_awesome_outlined, 'desc': 'Cosmétiques, fragrances'},
    {'name': 'Bijoux & Montres', 'icon': Icons.diamond_outlined, 'desc': 'Bagues, colliers, accessoires'},
    {'name': 'Décoration & Objets', 'icon': Icons.chair_outlined, 'desc': 'Luminaires, design, maison'},
    {'name': 'Livres & Pop-culture', 'icon': Icons.menu_book_outlined, 'desc': 'Romans, mangas, BDs'},
    {'name': 'Gourmandises', 'icon': Icons.cake_outlined, 'desc': 'Chocolats, vins, coffrets'},
  ];

  final List<String> _clothingSizes = const ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> _shoeSizes = const ['36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46'];
  final List<String> _budgetTiers = const ['< 25€', '25€ - 75€', '75€ - 150€', '> 150€'];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Pré-remplissage du nom si disponible via Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      _nameController.text = user.displayName!;
      final generatedHandle = user.displayName!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      if (generatedHandle.length >= 3) {
        _handleController.text = generatedHandle;
        _checkHandle(generatedHandle);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _nameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    HapticFeedback.lightImpact();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (picked != null) {
        setState(() {
          _profileImageFile = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint('[Onboarding] Error picking image: $e');
    }
  }

  Future<void> _checkHandle(String handle) async {
    final clean = handle.trim().toLowerCase();
    if (clean.length < 3) {
      setState(() {
        _isHandleValid = false;
        _handleError = '3 caractères minimum';
      });
      return;
    }
    setState(() {
      _isCheckingHandle = true;
      _handleError = null;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('handles').doc(clean).get();
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final isTakenByOther = doc.exists && doc.data()?['uid'] != myUid;

      if (mounted) {
        setState(() {
          _isCheckingHandle = false;
          _isHandleValid = !isTakenByOther;
          _handleError = isTakenByOther ? 'Ce nom d\'utilisateur est déjà pris' : null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingHandle = false);
    }
  }

  void _goToNextStep() {
    HapticFeedback.mediumImpact();
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOutCubic);
    } else {
      _finishOnboarding();
    }
  }

  void _goToPreviousStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic);
    }
  }

  Future<void> _skipOnboarding() async {
    HapticFeedback.selectionClick();
    await _saveDataAndFinish(isSkipped: true);
  }

  Future<void> _finishOnboarding() async {
    _confettiController.play();
    await _saveDataAndFinish(isSkipped: false);
  }

  Future<void> _saveDataAndFinish({required bool isSkipped}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      if (uid != null) {
        final name = _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : (user?.displayName ?? 'Ami Doron');
        
        final handle = _handleController.text.trim().isNotEmpty
            ? _handleController.text.trim().toLowerCase()
            : 'user_${uid.substring(0, 6)}';

        final profileData = <String, dynamic>{
          'display_name': name,
          'first_name': name,
          'handle': handle,
          'handle_lower': handle,
          'searchName': name.toLowerCase(),
          'gender': _selectedGender,
          'avatar_index': _selectedAvatarIndex,
          'passions': _selectedPassions.toList(),
          'favorite_gift_types': _selectedGiftTypes.toList(),
          'clothing_size': _clothingSize,
          'shoe_size': _shoeSize,
          'budget_tier': _budgetTier,
          'onboarding_completed': true,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (_dateOfBirth != null) {
          profileData['dob'] = _dateOfBirth!.toIso8601String();
        }

        // Upload de photo de profil si choisie
        if (_profileImageFile != null) {
          try {
            final storageRef = FirebaseStorage.instance.ref().child('users').child(uid).child('profile.jpg');
            await storageRef.putFile(_profileImageFile!);
            final downloadUrl = await storageRef.getDownloadURL();
            profileData['photo_url'] = downloadUrl;
            profileData['photoUrl'] = downloadUrl;
          } catch (e) {
            debugPrint('[Onboarding] Error uploading image: $e');
          }
        }

        // Sauvegarde profil Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(profileData, SetOptions(merge: true));

        // Sauvegarde index handle
        try {
          await FirebaseFirestore.instance.collection('handles').doc(handle).set({
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      await FirstTimeService.setOnboardingCompleted();

      if (mounted) {
        // Redirection vers l'accueil
        context.go('/search-page');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        context.go('/search-page');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: Stack(
        children: [
          // Effets d'orbes ambiants en arrière-plan
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _violet.withOpacity(0.2),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: const SizedBox(),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pink.withOpacity(0.18),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                _buildTopNavigationHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentStep = i),
                    children: [
                      _buildStep0Welcome(),
                      _buildStep1Identity(),
                      _buildStep2Passions(),
                      _buildStep3GiftTypes(),
                      _buildStep4SizesAndBudget(),
                    ],
                  ),
                ),
                _buildBottomActionBar(),
              ],
            ),
          ),

          // Confettis festifs lors de la complétion
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [_violet, _pink, _cyan, _gold, Colors.white],
            ),
          ),
        ],
      ),
    );
  }

  // --- Barre de navigation supérieure (Progression + Passer) ---
  Widget _buildTopNavigationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
              onPressed: _goToPreviousStep,
            )
          else
            const SizedBox(width: 40),

          // Barre de progression liquide
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(_pink),
                ),
              ),
            ),
          ),

          // Bouton "Passer"
          TextButton(
            onPressed: _skipOnboarding,
            child: Text(
              'Passer',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 0 : WELCOME & SUPER-POUVOIRS DORON
  // ==========================================
  Widget _buildStep0Welcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_violet, _pink]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _violet.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 52),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            'Bienvenue sur DORÕN',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recevez enfin les cadeaux que vous aimez vraiment et trouvez les idées parfaites pour vos proches.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // 3 Cartes de présentation
          _buildFeatureIntroCard(
            icon: IconlyLight.heart,
            gradient: const [_violet, _pink],
            title: 'Wishlists Intelligentes',
            desc: 'Partagez vos envies précises avec vos amis et votre famille.',
          ),
          const SizedBox(height: 12),
          _buildFeatureIntroCard(
            icon: IconlyLight.discovery,
            gradient: const [_pink, _gold],
            title: 'Suggestions IA sur-mesure',
            desc: 'Des milliers d\'idées cadeaux adaptées à chaque personnalité.',
          ),
          const SizedBox(height: 12),
          _buildFeatureIntroCard(
            icon: IconlyLight.calendar,
            gradient: const [_cyan, _violet],
            title: 'Calendrier des Anniversaires',
            desc: 'Ne ratez plus jamais une fête ni une date importante.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIntroCard({
    required IconData icon,
    required List<Color> gradient,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  desc,
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 1 : IDENTITÉ & PROFIL
  // ==========================================
  Widget _buildStep1Identity() {
    final hasCustomPhoto = _profileImageFile != null;
    final selectedAvatar = _avatars[_selectedAvatarIndex];
    final avatarColors = selectedAvatar['colors'] as List<Color>;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Créons ton profil ✨',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Ajoute ta photo ou choisis un avatar, et personnalise tes infos.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 24),

          // Photo de profil & Avatar Hero
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: hasCustomPhoto ? null : LinearGradient(colors: avatarColors),
                          border: Border.all(color: _pink.withOpacity(0.8), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: (hasCustomPhoto ? _pink : avatarColors.first).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: hasCustomPhoto
                              ? Image.file(_profileImageFile!, width: 104, height: 104, fit: BoxFit.cover)
                              : Icon(selectedAvatar['icon'] as IconData, color: Colors.white, size: 52),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_violet, _pink]),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _pickProfileImage,
                      icon: const Icon(Icons.photo_library_rounded, color: _pink, size: 16),
                      label: Text(
                        hasCustomPhoto ? 'Changer de photo' : 'Ajouter une photo',
                        style: GoogleFonts.poppins(color: _pink, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    if (hasCustomPhoto) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setState(() => _profileImageFile = null),
                        child: Text(
                          'Utiliser l\'avatar',
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Palette d'avatars alternatifs
          if (!hasCustomPhoto) ...[
            Text('Ou choisis ton avatar', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white70)),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatars.length,
                itemBuilder: (ctx, i) {
                  final isSel = _selectedAvatarIndex == i;
                  final av = _avatars[i];
                  final colors = av['colors'] as List<Color>;
                  final icon = av['icon'] as IconData;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedAvatarIndex = i;
                        _profileImageFile = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? Colors.white : Colors.transparent,
                          width: isSel ? 2.5 : 0,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Prénom / Nom
          Text('Ton prénom ou pseudo', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Ex: Camille, Alex...',
              hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              prefixIcon: const Icon(IconlyLight.user2, color: Colors.white54, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 20),

          // @handle
          Text('Nom d\'utilisateur unique (@)', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          TextField(
            controller: _handleController,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            onChanged: _checkHandle,
            decoration: InputDecoration(
              hintText: 'mon_handle',
              hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.white54, size: 20),
              suffixIcon: _isCheckingHandle
                  ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : _isHandleValid == true
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
                      : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          if (_handleError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(_handleError!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11)),
            ),

          const SizedBox(height: 20),

          // Date de naissance
          Text('Date de naissance 🎂', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(primary: _violet, onPrimary: Colors.white, surface: Color(0xFF161626)),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _dateOfBirth = picked);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(IconlyLight.calendar, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _dateOfBirth == null
                        ? 'Sélectionner ta date'
                        : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}',
                    style: GoogleFonts.poppins(color: _dateOfBirth == null ? Colors.white38 : Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2 : PASSIONS & HOBBIES
  // ==========================================
  Widget _buildStep2Passions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Tes centres d\'intérêt 🎨',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Sélectionne au moins 2 passions pour des idées cadeaux adaptées.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 24),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _passionsList.map((p) {
              final name = p['name'] as String;
              final icon = p['icon'] as IconData;
              final color = p['color'] as Color;
              final isSel = _selectedPassions.contains(name);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSel) {
                      _selectedPassions.remove(name);
                    } else {
                      _selectedPassions.add(name);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? color.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSel ? color : Colors.white.withOpacity(0.12),
                      width: isSel ? 1.5 : 1,
                    ),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: isSel ? color : Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: isSel ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3 : CADEAUX PRÉFÉRÉS
  // ==========================================
  Widget _buildStep3GiftTypes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Ce que tu adores recevoir 🎁',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Les types de cadeaux qui te font craquer à coup sûr.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 20),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _giftTypesList.length,
            itemBuilder: (ctx, i) {
              final item = _giftTypesList[i];
              final name = item['name'] as String;
              final desc = item['desc'] as String;
              final icon = item['icon'] as IconData;
              final isSel = _selectedGiftTypes.contains(name);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSel) {
                        _selectedGiftTypes.remove(name);
                      } else {
                        _selectedGiftTypes.add(name);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSel
                          ? LinearGradient(
                              colors: [_violet.withOpacity(0.25), _pink.withOpacity(0.15)],
                            )
                          : null,
                      color: isSel ? null : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel ? _pink : Colors.white.withOpacity(0.1),
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSel ? _pink.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: isSel ? _pink : Colors.white70, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                desc,
                                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSel ? Icons.check_circle_rounded : Icons.circle_outlined,
                          color: isSel ? _pink : Colors.white24,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 4 : TAILLES & BUDGET (Contraste parfait)
  // ==========================================
  Widget _buildStep4SizesAndBudget() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Tes mensurations & budget 📏',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Pour que vos proches ne se trompent plus jamais sur les tailles.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 24),

          // Taille Vêtements (Haut)
          Text('Taille de vêtement (Haut)', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _clothingSizes.map((size) {
                final isSel = _clothingSize == size;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildSelectableChip(
                    label: size,
                    isSelected: isSel,
                    activeColor: _violet,
                    onTap: () => setState(() => _clothingSize = size),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Pointure Chaussures
          Text('Pointure de chaussures', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _shoeSizes.map((shoe) {
                final isSel = _shoeSize == shoe;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildSelectableChip(
                    label: shoe,
                    isSelected: isSel,
                    activeColor: _pink,
                    onTap: () => setState(() => _shoeSize = shoe),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Budget habituel
          Text('Fourchette de budget favorite', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _budgetTiers.map((b) {
              final isSel = _budgetTier == b;
              return _buildSelectableChip(
                label: b,
                isSelected: isSel,
                activeColor: _cyan,
                onTap: () => setState(() => _budgetTier = b),
              );
            }).toList(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Composant de Chip Tactile Haut Contraste & Sans Bug de Thème ---
  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.35) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withOpacity(0.12),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // --- Barre d'action inférieure (Bouton Suivant / Terminer) ---
  Widget _buildBottomActionBar() {
    final isLast = _currentStep == _totalSteps - 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _goToNextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: _violet,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: _violet.withOpacity(0.5),
          ),
          child: _isSaving
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast ? 'Terminer et Découvrir ✨' : 'Continuer',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Icon(isLast ? Icons.check_rounded : Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}
