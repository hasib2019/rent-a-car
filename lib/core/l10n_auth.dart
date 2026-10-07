import 'l10n.dart';

/// Strings for accounts, access and server messages.
extension AuthStrings on S {
  String _t(String b, String e) => bn ? b : e;

  // ── Auth screen ──────────────────────────────────────────────────────────
  String get welcomeBack => _t('আবার স্বাগতম', 'Welcome back');
  String get createAccount => _t('নতুন অ্যাকাউন্ট', 'Create account');
  String get authTagline => _t('আপনার গাড়ির ব্যবসার হিসাব, নিরাপদে আপনার অ্যাকাউন্টে।', 'Your fleet business, safely under your own account.');
  String get loginTab => _t('লগইন', 'Log in');
  String get registerTab => _t('রেজিস্ট্রেশন', 'Register');
  String get loginField => _t('ইমেইল / মোবাইল / ইউজারনেম', 'Email / phone / username');
  String get password => _t('পাসওয়ার্ড', 'Password');
  String get confirmPassword => _t('আবার পাসওয়ার্ড', 'Confirm password');
  String get passwordHint => _t('অন্তত ৮ অক্ষর, অক্ষর ও সংখ্যা মিলিয়ে', 'At least 8 characters, letters and numbers');
  String get passwordsDontMatch => _t('দুইটা পাসওয়ার্ড মেলেনি', "Passwords don't match");
  String get forgotPassword => _t('পাসওয়ার্ড ভুলে গেছেন?', 'Forgot password?');
  String get loginButton => _t('লগইন করুন', 'Log in');
  String get registerButton => _t('অ্যাকাউন্ট খুলুন', 'Create account');
  String get fullName => _t('আপনার নাম', 'Your name');
  String get username => _t('ইউজারনেম', 'Username');
  String get usernameHint => _t('ছোট হাতের ইংরেজি, সংখ্যা, _ ও .', 'lowercase letters, numbers, _ and .');
  String get email => _t('ইমেইল', 'Email');
  String get mobile => _t('মোবাইল নম্বর', 'Mobile number');
  String get businessInfo => _t('ব্যবসার তথ্য (ঐচ্ছিক)', 'Business details (optional)');
  String get district => _t('জেলা', 'District');
  String get fleetSize => _t('কয়টি গাড়ি আছে', 'How many vehicles');
  String get invalidEmail => _t('সঠিক ইমেইল দিন', 'Enter a valid email');
  String get invalidPhone => _t('সঠিক মোবাইল নম্বর দিন (01XXXXXXXXX)', 'Enter a valid mobile number (01XXXXXXXXX)');
  String get invalidUsername => _t('৩-৩০ অক্ষর: a-z, 0-9, _ .', '3–30 characters: a-z, 0-9, _ .');
  String get weakPassword => _t('অন্তত ৮ অক্ষর, অক্ষর ও সংখ্যা দুইটাই থাকতে হবে', 'At least 8 characters with letters and numbers');
  String get termsNote => _t('অ্যাকাউন্ট খুলে আপনি আমাদের শর্তাবলী মেনে নিচ্ছেন। আপনার গাড়ির হিসাব আপনার ফোনেই থাকে।', 'By signing up you accept our terms. Your ledger stays on your phone.');
  String get registrationClosed => _t('এই মুহূর্তে নতুন রেজিস্ট্রেশন বন্ধ আছে।', 'Registrations are closed right now.');
  String get offline => _t('ইন্টারনেট সংযোগ পাওয়া যাচ্ছে না। আবার চেষ্টা করুন।', "Can't reach the server. Check the internet and try again.");
  String get haveAccount => _t('আগে থেকেই অ্যাকাউন্ট আছে?', 'Already have an account?');
  String get noAccount => _t('অ্যাকাউন্ট নেই?', "Don't have an account?");

  // ── Forgot password ──────────────────────────────────────────────────────
  String get resetTitle => _t('পাসওয়ার্ড রিসেট', 'Reset password');
  String get resetStep1 => _t('অ্যাকাউন্টের ইমেইল দিন, সেখানে ৬ সংখ্যার কোড পাঠানো হবে।', "Enter your account email — we'll send a 6-digit code.");
  String get sendCode => _t('কোড পাঠান', 'Send code');
  String resetStep2(String email) => _t('$email-এ পাঠানো কোড আর নতুন পাসওয়ার্ড দিন।', 'Enter the code sent to $email and a new password.');
  String get code => _t('৬ সংখ্যার কোড', '6-digit code');
  String get newPassword => _t('নতুন পাসওয়ার্ড', 'New password');
  String get setPassword => _t('পাসওয়ার্ড সেট করুন', 'Set password');
  String get resendCode => _t('আবার কোড পাঠান', 'Resend code');

  // ── Profile ──────────────────────────────────────────────────────────────
  String get account => _t('অ্যাকাউন্ট', 'Account');
  String get myAccount => _t('আমার অ্যাকাউন্ট', 'My account');
  String get editProfile => _t('প্রোফাইল এডিট', 'Edit profile');
  String get changePassword => _t('পাসওয়ার্ড পরিবর্তন', 'Change password');
  String get currentPassword => _t('বর্তমান পাসওয়ার্ড', 'Current password');
  String get passwordChanged => _t('পাসওয়ার্ড বদলানো হয়েছে', 'Password changed');
  String get logout => _t('লগআউট', 'Log out');
  String get logoutConfirm => _t('লগআউট করবেন?', 'Log out?');
  String get logoutBody => _t('আপনার হিসাবের ডাটা এই ফোনেই থাকবে। আবার লগইন করলে সব আগের মতো পাবেন।', 'Your ledger stays on this phone. Log in again to continue where you left off.');
  String get deleteAccount => _t('অ্যাকাউন্ট মুছে ফেলুন', 'Delete account');
  String get deleteAccountBody => _t('আপনার অ্যাকাউন্ট স্থায়ীভাবে মুছে যাবে এবং এই ফোনের সব হিসাবও মুছে ফেলা হবে। এটা আর ফেরত আনা যাবে না। নিশ্চিত করতে পাসওয়ার্ড দিন।', 'Your account is deleted permanently and the ledger on this phone is erased. This cannot be undone. Enter your password to confirm.');
  String get accountDeleted => _t('অ্যাকাউন্ট মুছে ফেলা হয়েছে', 'Account deleted');
  String get memberSince => _t('সদস্য হয়েছেন', 'Member since');

  // ── Access / server states ───────────────────────────────────────────────
  String get lockedTitle => _t('এই সুবিধাটি চালু নেই', 'This feature is not enabled');
  String get lockedBody => _t('আপনার অ্যাকাউন্টে এই সুবিধাটি এখন চালু নেই। চালু করতে আমাদের সাথে যোগাযোগ করুন।', "This feature isn't enabled on your account. Contact us to turn it on.");
  String vehicleLimit(int n) => _t('আপনার অ্যাকাউন্টে সর্বোচ্চ ${this.n(n)}টি গাড়ি রাখা যাবে। বেশি গাড়ি যোগ করতে যোগাযোগ করুন।', 'Your account allows up to $n vehicles. Contact us to add more.');
  String driverLimit(int n) => _t('আপনার অ্যাকাউন্টে সর্বোচ্চ ${this.n(n)} জন ড্রাইভার রাখা যাবে। বেশি যোগ করতে যোগাযোগ করুন।', 'Your account allows up to $n drivers. Contact us to add more.');
  String get contactSupport => _t('কল করুন', 'Call us');
  String get whatsapp => _t('হোয়াটসঅ্যাপ', 'WhatsApp');
  String get close => _t('ঠিক আছে', 'OK');
  String get signedOutTitle => _t('আপনাকে লগআউট করা হয়েছে', 'You were signed out');
  String get updateTitle => _t('নতুন ভার্সন দরকার', 'Update required');
  String get updateBody => _t('অ্যাপটি চালু রাখতে নতুন ভার্সনে আপডেট করুন।', 'Please update to the latest version to keep using the app.');
  String get updateNow => _t('এখনই আপডেট করুন', 'Update now');
}
