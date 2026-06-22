import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleStorageKey = '__locale_key__';

class FFLocalizations {
  FFLocalizations(this.locale);

  final Locale locale;

  static FFLocalizations of(BuildContext context) =>
      Localizations.of<FFLocalizations>(context, FFLocalizations)!;

  static List<String> languages() => ['fr', 'en', 'es'];

  static late SharedPreferences _prefs;
  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();
  static Future storeLocale(String locale) =>
      _prefs.setString(_kLocaleStorageKey, locale);
  static Locale? getStoredLocale() {
    final locale = _prefs.getString(_kLocaleStorageKey);
    return locale != null && locale.isNotEmpty ? createLocale(locale) : null;
  }

  String get languageCode => locale.toString();
  String? get languageShortCode =>
      _languagesWithShortCode.contains(locale.toString())
          ? '${locale.toString()}_short'
          : null;
  int get languageIndex => languages().contains(languageCode)
      ? languages().indexOf(languageCode)
      : 0;

  String getText(String key) =>
      (kTranslationsMap[key] ?? {})[locale.toString()] ?? '';

  String getVariableText({
    String? frText = '',
    String? enText = '',
  }) =>
      [frText, enText][languageIndex] ?? '';

  static const Set<String> _languagesWithShortCode = {
    'ar',
    'az',
    'ca',
    'cs',
    'da',
    'de',
    'dv',
    'en',
    'es',
    'et',
    'fi',
    'fr',
    'gr',
    'he',
    'hi',
    'hu',
    'it',
    'km',
    'ku',
    'mn',
    'ms',
    'no',
    'pt',
    'ro',
    'ru',
    'rw',
    'sv',
    'th',
    'uk',
    'vi',
  };
}

/// Used if the locale is not supported by GlobalMaterialLocalizations.
class FallbackMaterialLocalizationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(FallbackMaterialLocalizationDelegate old) => false;
}

/// Used if the locale is not supported by GlobalCupertinoLocalizations.
class FallbackCupertinoLocalizationDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(FallbackCupertinoLocalizationDelegate old) => false;
}

class FFLocalizationsDelegate extends LocalizationsDelegate<FFLocalizations> {
  const FFLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isSupportedLocale(locale);

  @override
  Future<FFLocalizations> load(Locale locale) =>
      SynchronousFuture<FFLocalizations>(FFLocalizations(locale));

  @override
  bool shouldReload(FFLocalizationsDelegate old) => false;
}

Locale createLocale(String language) => language.contains('_')
    ? Locale.fromSubtags(
        languageCode: language.split('_').first,
        scriptCode: language.split('_').last,
      )
    : Locale(language);

bool _isSupportedLocale(Locale locale) {
  final language = locale.toString();
  return FFLocalizations.languages().contains(
    language.endsWith('_')
        ? language.substring(0, language.length - 1)
        : language,
  );
}

final kTranslationsMap = <Map<String, Map<String, String>>>[
  // authentification
  {
    'aj469saw': {
      'fr': 'Créer un compte',
      'en': 'Create an account',
    },
    'qifcg95i': {
      'fr': 'Bienvenue !',
      'en': 'Welcome !',
    },
    '3opxnh28': {
      'fr': 'Commençons par remplir le formulaire ci-dessous',
      'en': 'Let\'s start by filling out the form below',
    },
    'una0p4g9': {
      'fr': 'Nom d\'affichage',
      'en': 'Display Name',
    },
    '7iay6bh2': {
      'fr': 'E-mail',
      'en': 'Email',
    },
    'zvmf0xv1': {
      'fr': 'Mot de passe',
      'en': 'Password',
    },
    'c96r06t3': {
      'fr': 'Confirmez le mot de passe',
      'en': 'Confirm Password',
    },
    'vxsb87la': {
      'fr': 'Créer',
      'en': 'Create',
    },
    'mvbo32ml': {
      'fr': 'Continuer sans connexion',
      'en': 'Continue without connection',
    },
    'c357hcpj': {
      'fr': 'Ou inscrivez-vous avec ',
      'en': 'Or register with',
    },
    '828xwien': {
      'fr': 'Continue with Google',
      'en': '',
    },
    'xy6o5xqi': {
      'fr': 'Continue with Apple',
      'en': '',
    },
    's4r9ole4': {
      'fr': 'Le nom d\'affichage est requis',
      'en': 'Display Name is requried ',
    },
    'w8fxlbwz': {
      'fr': 'Au moins 3 caractères',
      'en': 'Atleast 3 characters ',
    },
    'mij1umiz': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    '1drkjedw': {
      'fr': 'Email est requis',
      'en': 'Email is required',
    },
    'df8881pe': {
      'fr': 'Email invalide',
      'en': 'Invalid Email',
    },
    'bpzluv84': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'lykhbuk6': {
      'fr': 'Mot de passe est requis',
      'en': 'Password is required',
    },
    'd7anp80h': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'alq39fyf': {
      'fr': 'Confirmez le mot de passe est requis',
      'en': 'Confirm password is required',
    },
    'fklgquf1': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'txubw033': {
      'fr': 'Se connecter',
      'en': 'Log in',
    },
    'qu8l0ock': {
      'fr': 'Content de te revoir !',
      'en': 'Nice to see you again!',
    },
    'qcpikann': {
      'fr':
          'Remplissez les informations ci-dessous afin d’accéder à votre compte',
      'en': 'Fill in the information below to access your account',
    },
    '87wzf30z': {
      'fr': 'Email',
      'en': '',
    },
    'j7x8ripb': {
      'fr': 'Password',
      'en': '',
    },
    'm92c14c1': {
      'fr': 'Se connecter',
      'en': 'Log in',
    },
    'yiujiyqq': {
      'fr': 'Ou connectez vous avec',
      'en': 'Or connect with',
    },
    '835qhd6h': {
      'fr': 'Continue with Google',
      'en': '',
    },
    'hbm7a9cp': {
      'fr': 'Continue with Apple',
      'en': '',
    },
    'xjzekes6': {
      'fr': 'Mot de passe oublié ?',
      'en': 'Forgot your password?',
    },
    '7emdil6i': {
      'fr': 'L\'e-mail est requis',
      'en': 'Email is required',
    },
    'nzbj4kiq': {
      'fr': 'E-mail invalide',
      'en': 'Invalid email',
    },
    '3x6g7qz9': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'z39strzg': {
      'fr': 'Password is required',
      'en': 'Password is required',
    },
    'crv6ae4j': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'jvo958vo': {
      'fr': 'Home',
      'en': '',
    },
  },
  // GiftGenerator
  {
    'ga37cue6': {
      'fr': 'Recherche de cadeaux',
      'en': 'Search for gifts',
    },
    '9tmeff1x': {
      'fr': 'Parlez-nous-en, nous vous proposerons le cadeau parfait !',
      'en': 'Tell us about them, we’ll suggest the perfect gift!',
    },
    '5ia4f15y': {
      'fr': 'Frère, Soeur',
      'en': 'Brother , Sister',
    },
    '1djo92qp': {
      'fr': 'À qui est destiné le cadeau ?',
      'en': 'Who is the gift for?',
    },
    'mvmxsqdd': {
      'fr': 'Quel âge ont-ils ?',
      'en': 'How old are they?',
    },
    'ovrncmsl': {
      'fr': 'Quel est votre budget ?',
      'en': 'What’s your budget?',
    },
    'xm462cp6': {
      'fr': 'min',
      'en': 'min',
    },
    '6hva4k4i': {
      'fr': 'max',
      'en': 'max',
    },
    '97kjjkm3': {
      'fr': 'Intérêts',
      'en': 'Interests',
    },
    'qs2dyjgz': {
      'fr': 'Jeux, voyages',
      'en': 'Gaming , Travelling',
    },
    '3pool446': {
      'fr': 'Ajouter',
      'en': 'Add',
    },
    'm238ri24': {
      'fr': 'Trouver un cadeau',
      'en': 'Find Gift',
    },
    'wxtrcnv3': {
      'fr': 'hintText is required',
      'en': '',
    },
    'vfxdtznb': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'hxd2gc0u': {
      'fr': 'hintText is required',
      'en': '',
    },
    '77652l25': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'u927yqcf': {
      'fr': 'min is required',
      'en': '',
    },
    'dumrpa6t': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'uijhcuxh': {
      'fr': 'max is required',
      'en': '',
    },
    '7f19lfa2': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'df0lfnnk': {
      'fr': 'Gaming , Travelling is required',
      'en': '',
    },
    '3unr1hol': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'c0s4089z': {
      'fr': 'Home',
      'en': '',
    },
  },
  // HomeAlgoace
  {
    'oo49mhxh': {
      'fr': 'DORÕN',
      'en': 'DORÕN',
    },
    'm9f7q8vx': {
      'fr': 'Offres et recherche',
      'en': 'Offers and Search',
    },
    '9d4ox1fe': {
      'fr': 'Recherche',
      'en': 'Search',
    },
    'dvsaxnjn': {
      'fr': 'Home',
      'en': '',
    },
  },
  // Favourites
  {
    'i8cjlmu0': {
      'fr': 'Favoris',
      'en': 'Favourites',
    },
    '5ot76rm7': {
      'fr': 'Les cadeaux que vous aimez seront sauvegardés ici',
      'en': 'The gifts that you like will be saved here',
    },
    '8ty3kok9': {
      'fr': 'Home',
      'en': '',
    },
  },
  // profile
  {
    's2pb5jum': {
      'fr': 'Profil',
      'en': 'Profile',
    },
    'afdwk4n1': {
      'fr': 'Passer en mode sombre ',
      'en': 'Switch to Light Mode',
    },
    'u0xaau0x': {
      'fr': 'Passer en mode sombre ',
      'en': 'Switch to Light Mode',
    },
    '9qq275lu': {
      'fr': 'Paramètres du compte',
      'en': 'Account settings',
    },
    'ky4dsll3': {
      'fr': 'Changer le mot de passe ',
      'en': 'Change password',
    },
    '2qbw6ji7': {
      'fr': 'Modifier le profil',
      'en': 'Edit profile',
    },
    've6bceva': {
      'fr': 'Changer de langue',
      'en': 'Change Language',
    },
    '8serubl2': {
      'fr': 'Se déconnecter ',
      'en': 'Log out',
    },
    '48g82y7e': {
      'fr': 'Supprimer le compte',
      'en': 'Delete account',
    },
    '5m4dt1tl': {
      'fr': '__',
      'en': '__',
    },
  },
  // ChatHistory
  {
    '3x1clynu': {
      'fr': 'Recherche de cadeaux',
      'en': 'Search for gifts',
    },
    'gb96lv0a': {
      'fr': 'Parlez-nous-en, nous vous proposerons le cadeau parfait',
      'en': 'Tell us about them, we’ll suggest the perfect gift!',
    },
    'jfrmi7vm': {
      'fr': 'Home',
      'en': '',
    },
  },
  // chat_ai_Screen
  {
    'pgc0bg6m': {
      'fr': 'Home',
      'en': '',
    },
  },
  // openAiSuggestedGifts
  {
    'jwsskj7o': {
      'fr': 'Home',
      'en': '',
    },
  },
  // preview_chat
  {
    '2biuqndb': {
      'fr': 'Home',
      'en': '',
    },
  },
  // ForgotPassword
  {
    'zpfkm5xy': {
      'fr': 'Back',
      'en': '',
    },
    'fc6p5lfn': {
      'fr': 'Mot de passe oublié',
      'en': 'Forgot Password',
    },
    '8vqfvmg3': {
      'fr':
          'Nous vous enverrons un e-mail avec un lien pour réinitialiser votre mot de passe, veuillez saisir l\'e-mail associé à votre compte ci-dessous.',
      'en':
          'We will send you an email with a link to reset your password, please enter the email associated with your account below.',
    },
    'psl6o9pw': {
      'fr': '',
      'en': '',
    },
    'jasgkd0u': {
      'fr': 'Entrez votre email...',
      'en': 'Enter your email...',
    },
    'pmmp1ybo': {
      'fr': 'l\'adresse e-mail est requise',
      'en': 'email address is required',
    },
    '70xlwkr4': {
      'fr': 'doit être une adresse e-mail valide',
      'en': 'must be valid email address',
    },
    'bpngj25u': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'zplf6nj0': {
      'fr': 'Envoyer le lien',
      'en': 'Send Link',
    },
    'y6iz7oj8': {
      'fr': 'Home',
      'en': '',
    },
  },
  // Product
  {
    'kswhbcfi': {
      'fr': 'Sepora',
      'en': 'Sepora',
    },
    'q56q9h91': {
      'fr': 'IKEA',
      'en': 'IKEA',
    },
    'xif9o1ax': {
      'fr': 'Amazon',
      'en': 'Amazon',
    },
    '2xu6rfkn': {
      'fr': '',
      'en': '',
    },
  },
  // emptyData
  {
    'b7cfw6wv': {
      'fr': 'Aucun produit disponible',
      'en': 'No Products Available',
    },
    'bu90q32a': {
      'fr': 'Il semble qu\'aucun produit ne soit disponible.',
      'en': 'It looks like no products are available.',
    },
  },
  // loader
  {
    'gkcqv5jc': {
      'fr': '',
      'en': '',
    },
  },
  // ai_chat_Component
  {
    'l4uezc6t': {
      'fr': 'Tapez quelque chose...',
      'en': 'Type something...',
    },
  },
  // ChangeLanguage
  {
    '02ifvcvm': {
      'fr': 'Français',
      'en': 'French',
    },
    'dl05lwrh': {
      'fr': 'Anglais',
      'en': 'English',
    },
  },
  // ChangeName
  {
    '94z2e6d2': {
      'fr': 'Changer le nom',
      'en': 'Change Name',
    },
    'yqcmjjjl': {
      'fr': 'Le nom d’affichage est requis',
      'en': ' Display Name is required',
    },
    'lm5wnana': {
      'fr': 'au moins 3 caractères sont requis',
      'en': 'minimum 3 character are required',
    },
    '0hhpzp4e': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'f0pr4sri': {
      'fr': 'Annuler',
      'en': 'Cancel',
    },
    'ulhryxaj': {
      'fr': 'Enregistrer les modifications',
      'en': 'Save Changes',
    },
  },
  // ChangePassword
  {
    'queq7dpm': {
      'fr': 'Changer le mot de passe',
      'en': 'Change Password',
    },
    'sur0f1dc': {
      'fr': 'Mot de passe actuel',
      'en': 'Current Password',
    },
    '9rsnplqy': {
      'fr': 'Nouveau mot de passe',
      'en': 'New Password',
    },
    'cr5s7ygt': {
      'fr': 'Confirmer que le mot de passe',
      'en': 'Confirm password',
    },
    'x9pfhs44': {
      'fr': 'Annuler',
      'en': 'Cancel',
    },
    'ozdp0fq2': {
      'fr': 'Enregistrer les modifications',
      'en': 'Save Changes',
    },
    'ehdclzgd': {
      'fr': 'Le mot de passe actuel est requis',
      'en': 'Current password is required',
    },
    'v1t5d9yl': {
      'fr': '',
      'en': '',
    },
    'gnmlcxss': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'jtiugbnd': {
      'fr': 'Un nouveau mot de passe est requis',
      'en': 'New password is required',
    },
    '4g965rzh': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
    'fe87q4ln': {
      'fr': 'confirmer que le mot de passe est requis',
      'en': 'confirm password is required',
    },
    'anj7fhhz': {
      'fr': 'Please choose an option from the dropdown',
      'en': '',
    },
  },
  // emptyChatHistory
  {
    'o38j7bd3': {
      'fr': 'Aucune discussion disponible',
      'en': 'No Chats Available',
    },
    'vshro8ba': {
      'fr': 'créez votre première suggestion de cadeau.',
      'en': 'create your first gift suggestion.',
    },
  },
  // InvalidCurrentPassword
  {
    'm1ruilrt': {
      'fr': 'Mot de passe actuel invalide',
      'en': 'Invalid Current Password',
    },
  },
  // NewPasswordAndCurrentPassError
  {
    'twi3dumw': {
      'fr': 'New password and confirm password must be same',
      'en': 'New password and confirm password must be same',
    },
  },
  // Miscellaneous
  {
    'rlesv230': {
      'fr': '',
      'en': '',
    },
    '268gxyqt': {
      'fr': '',
      'en': '',
    },
    'rtelqp13': {
      'fr': '',
      'en': '',
    },
    'a77nj6po': {
      'fr': '',
      'en': '',
    },
    '9bm5c060': {
      'fr': '',
      'en': '',
    },
    '4r1krr8e': {
      'fr': '',
      'en': '',
    },
    '7p102ogx': {
      'fr': '',
      'en': '',
    },
    'ev6ytw21': {
      'fr': '',
      'en': '',
    },
    'j3p4nvff': {
      'fr': '',
      'en': '',
    },
    'nxf27l4e': {
      'fr': '',
      'en': '',
    },
    '4dlo7lz5': {
      'fr': '',
      'en': '',
    },
    'm84iagon': {
      'fr': '',
      'en': '',
    },
    '6dl7iraq': {
      'fr': '',
      'en': '',
    },
    'v4ecd1ia': {
      'fr': '',
      'en': '',
    },
    'vgd6vvmf': {
      'fr': '',
      'en': '',
    },
    'ovo10nlx': {
      'fr': '',
      'en': '',
    },
    'zeqrm2ip': {
      'fr': '',
      'en': '',
    },
    'ywoy93k7': {
      'fr': '',
      'en': '',
    },
    'earhtier': {
      'fr': '',
      'en': '',
    },
    'eiy83hrk': {
      'fr': '',
      'en': '',
    },
    'yqgpmp09': {
      'fr': '',
      'en': '',
    },
    '60ffg40m': {
      'fr': '',
      'en': '',
    },
    'wz5rl5mg': {
      'fr': '',
      'en': '',
    },
    'xa2eihtr': {
      'fr': '',
      'en': '',
    },
    'kgvomodx': {
      'fr': '',
      'en': '',
    },
  },
].reduce((a, b) => a..addAll(b));
