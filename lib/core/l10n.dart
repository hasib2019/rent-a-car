import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/settings.dart';

/// Lightweight bilingual strings. Bangla is the default; English is a toggle.
class S {
  const S(this.bn, {this.bnNum = true});
  final bool bn;
  final bool bnNum;

  static S of(BuildContext context) => _from(context.watch<Settings>());
  static S read(BuildContext context) => _from(context.read<Settings>());
  static S _from(Settings s) => S(s.isBangla, bnNum: s.useBanglaDigits);

  String _(String b, String e) => bn ? b : e;
  String n(Object v) => bnNum ? bnDigits(v) : v.toString();

  // ── App ────────────────────────────────────────────────────────────────
  String get appName => _('গাড়ির খাতা', 'GariKhata');
  String get tagline => _('আপনার গাড়ির ব্যবসার পুরো হিসাব, এক জায়গায়', 'Your whole fleet business, in one ledger');

  // ── Navigation ─────────────────────────────────────────────────────────
  String get navHome => _('হোম', 'Home');
  String get navFleet => _('গাড়ি', 'Fleet');
  String get navLedger => _('খাতা', 'Ledger');
  String get navReport => _('রিপোর্ট', 'Reports');
  String get navSettings => _('সেটিংস', 'Settings');

  // ── Common ─────────────────────────────────────────────────────────────
  String get save => _('সেভ করুন', 'Save');
  String get cancel => _('বাতিল', 'Cancel');
  String get delete => _('মুছে ফেলুন', 'Delete');
  String get edit => _('এডিট', 'Edit');
  String get add => _('যোগ করুন', 'Add');
  String get done => _('সম্পন্ন', 'Done');
  String get next => _('পরবর্তী', 'Next');
  String get skip => _('বাদ দিন', 'Skip');
  String get seeAll => _('সব দেখুন', 'See all');
  String get note => _('নোট', 'Note');
  String get noteHint => _('কিছু লিখে রাখুন (ঐচ্ছিক)', 'Add a note (optional)');
  String get date => _('তারিখ', 'Date');
  String get today => _('আজ', 'Today');
  String get yesterday => _('গতকাল', 'Yesterday');
  String get amount => _('টাকার পরিমাণ', 'Amount');
  String get required => _('এটা দিতে হবে', 'Required');
  String get invalidNumber => _('সঠিক সংখ্যা দিন', 'Enter a valid number');
  String get saved => _('সেভ হয়েছে', 'Saved');
  String get deleted => _('মুছে ফেলা হয়েছে', 'Deleted');
  String get confirmDelete => _('নিশ্চিতভাবে মুছে ফেলবেন?', 'Delete this for sure?');
  String get confirmDeleteBody => _('এটা আর ফেরত আনা যাবে না।', 'This cannot be undone.');
  String get none => _('কেউ না', 'None');
  String get all => _('সব', 'All');
  String get phone => _('মোবাইল নম্বর', 'Phone');
  String get call => _('কল', 'Call');
  String get optional => _('ঐচ্ছিক', 'optional');
  String get active => _('চালু', 'Active');
  String get inactive => _('বন্ধ', 'Inactive');
  String get inGarage => _('গ্যারেজে', 'In garage');
  String get status => _('অবস্থা', 'Status');
  String get selectVehicle => _('গাড়ি বাছাই করুন', 'Pick a vehicle');
  String get noVehicleYet => _('আগে একটা গাড়ি যোগ করুন', 'Add a vehicle first');
  String get perDay => _('/দিন', '/day');
  String get days => _('দিন', 'days');
  String get total => _('মোট', 'Total');

  // ── Money words ────────────────────────────────────────────────────────
  String get income => _('আয়', 'Income');
  String get expense => _('খরচ', 'Expense');
  String get profit => _('লাভ', 'Profit');
  String get loss => _('লোকসান', 'Loss');
  String get netProfit => _('নিট লাভ', 'Net profit');
  String get collection => _('জমা', 'Collection');
  String get due => _('বাকি', 'Due');
  String get target => _('টার্গেট', 'Target');
  String get paid => _('দিয়েছে', 'Paid');

  // ── Home ───────────────────────────────────────────────────────────────
  String greeting(int hour) {
    if (hour < 5) return _('শুভ রাত্রি', 'Good night');
    if (hour < 12) return _('শুভ সকাল', 'Good morning');
    if (hour < 17) return _('শুভ দুপুর', 'Good afternoon');
    if (hour < 20) return _('শুভ সন্ধ্যা', 'Good evening');
    return _('শুভ রাত্রি', 'Good night');
  }

  String get todaysCollection => _('আজকের জমা', "Today's collection");
  String get ofTarget => _('টার্গেটের', 'of target');
  String get thisMonth => _('এই মাস', 'This month');
  String get lastMonth => _('গত মাস', 'Last month');
  String get thisYear => _('এই বছর', 'This year');
  String get allTime => _('শুরু থেকে', 'All time');
  String get yourFleet => _('আপনার গাড়িবহর', 'Your fleet');
  String get recentEntries => _('সাম্প্রতিক হিসাব', 'Recent entries');
  String get attention => _('নজর দিন', 'Needs attention');
  String get pendingToday => _('আজ জমা বাকি', 'Pending today');
  String get collectNow => _('এখন জমা নিন', 'Collect now');
  String get allCollected => _('আজকের সব জমা নেওয়া হয়েছে', "All of today's collection is in");
  String get driverDues => _('ড্রাইভারদের বাকি', 'Driver dues');
  String get paperExpiring => _('কাগজের মেয়াদ শেষ হচ্ছে', 'Papers expiring');
  String get welcomeTitle => _('চলুন শুরু করি', "Let's get rolling");
  String get welcomeBody => _('আপনার প্রথম গাড়ি যোগ করুন, অথবা ডেমো ডাটা দিয়ে অ্যাপটা ঘুরে দেখুন।', 'Add your first vehicle, or explore the app with demo data.');
  String get loadDemo => _('ডেমো ডাটা দেখুন', 'Load demo data');
  String get addFirstVehicle => _('প্রথম গাড়ি যোগ করুন', 'Add first vehicle');

  // ── Quick add ──────────────────────────────────────────────────────────
  String get quickAdd => _('নতুন হিসাব', 'New entry');
  String get dailyCollection => _('দৈনিক জমা', 'Daily collection');
  String get dailyCollectionSub => _('সব গাড়ির আজকের জমা একসাথে', "Every vehicle's collection at once");
  String get fuel => _('জ্বালানি', 'Fuel');
  String get fuelSub => _('গ্যাস, অকটেন, ডিজেল', 'CNG, octane, diesel');
  String get maintenance => _('মেরামত ও খরচ', 'Repairs & costs');
  String get maintenanceSub => _('সার্ভিসিং, পার্টস, কাগজপত্র', 'Servicing, parts, papers');
  String get tripIncome => _('ট্রিপ / ভাড়া আয়', 'Trip / hire income');
  String get tripIncomeSub => _('রিজার্ভ, ভাড়া, অন্যান্য আয়', 'Reserve hire, rentals, other');
  String get duePayment => _('বাকি আদায়', 'Due recovery');
  String get duePaymentSub => _('ড্রাইভারের পুরনো বাকি', "A driver's old dues");

  // ── Daily collection ───────────────────────────────────────────────────
  String get markFull => _('পুরো', 'Full');
  String get markOff => _('বন্ধ', 'Off');
  String get offDay => _('গাড়ি বন্ধ ছিল', 'Vehicle was off');
  String get alreadyCollected => _('আজ জমা নেওয়া হয়েছে', 'Already collected');
  String get saveCollection => _('জমা সেভ করুন', 'Save collection');
  String get noActiveVehicles => _('কোনো চালু গাড়ি নেই', 'No active vehicles');
  String collectedCount(int n, int total) => _('${this.n(n)}/${this.n(total)} টি জমা হয়েছে', '$n/$total collected');
  String shortBy(String amount) => _('$amount কম', '$amount short');
  String get noDriver => _('ড্রাইভার নেই', 'No driver');
  String get noVehicleAssigned => _('কোনো গাড়ি দেওয়া হয়নি', 'No vehicle assigned');

  // ── Entry ──────────────────────────────────────────────────────────────
  String get category => _('খাত', 'Category');
  String get liters => _('লিটার / m³', 'Litres / m³');
  String get odometer => _('মিটার (কিমি)', 'Odometer km');
  String get driver => _('ড্রাইভার', 'Driver');
  String get whoPaid => _('কোন ড্রাইভার দিল?', 'Which driver paid?');
  String get enterAmount => _('টাকার পরিমাণ লিখুন', 'Enter an amount');
  String get entrySaved => _('হিসাব সেভ হয়েছে', 'Entry saved');
  String get tripFrom => _('কোথা থেকে / কার জন্য', 'Client / route');

  // ── Fleet ──────────────────────────────────────────────────────────────
  String get vehicles => _('গাড়ি', 'Vehicles');
  String get drivers => _('ড্রাইভার', 'Drivers');
  String get addVehicle => _('গাড়ি যোগ করুন', 'Add vehicle');
  String get editVehicle => _('গাড়ি এডিট', 'Edit vehicle');
  String get addDriver => _('ড্রাইভার যোগ করুন', 'Add driver');
  String get editDriver => _('ড্রাইভার এডিট', 'Edit driver');
  String get vehicleName => _('গাড়ির নাম / ডাকনাম', 'Vehicle nickname');
  String get vehicleNameHint => _('যেমন: সবুজ সিএনজি', 'e.g. Green CNG');
  String get vehicleType => _('গাড়ির ধরন', 'Vehicle type');
  String get regNo => _('রেজিস্ট্রেশন নম্বর', 'Registration no.');
  String get regNoHint => _('ঢাকা মেট্রো-থ ১১-২২৩৩', 'Dhaka Metro-Tha 11-2233');
  String get model => _('মডেল', 'Model');
  String get modelHint => _('যেমন: বাজাজ RE, টয়োটা এক্সিও', 'e.g. Bajaj RE, Toyota Axio');
  String get purchasePrice => _('কেনা দাম', 'Purchase price');
  String get purchaseDate => _('কেনার তারিখ', 'Purchase date');
  String get dailyTarget => _('দৈনিক জমার টার্গেট', 'Daily collection target');
  String get dailyTargetHelp => _('ড্রাইভার প্রতিদিন যত টাকা জমা দেয়', 'What the driver hands over each day');
  String get assignedDriver => _('দায়িত্বপ্রাপ্ত ড্রাইভার', 'Assigned driver');
  String get noVehicles => _('এখনো কোনো গাড়ি নেই', 'No vehicles yet');
  String get noDrivers => _('এখনো কোনো ড্রাইভার নেই', 'No drivers yet');
  String get driverName => _('ড্রাইভারের নাম', "Driver's name");
  String get nid => _('এনআইডি নম্বর', 'NID number');
  String get licenseNo => _('লাইসেন্স নম্বর', 'Licence number');
  String get address => _('ঠিকানা', 'Address');
  String get joinDate => _('যোগদানের তারিখ', 'Joining date');
  String get openingDue => _('আগের বাকি (যদি থাকে)', 'Opening due (if any)');
  String get drivesVehicle => _('চালায়', 'Drives');
  String get deleteVehicleWarn => _('এই গাড়ির সব জমা ও খরচের হিসাবও মুছে যাবে।', "All of this vehicle's entries will be deleted too.");
  String get deleteDriverWarn => _('ড্রাইভার মুছে গেলেও পুরনো হিসাব থেকে যাবে।', "Old entries stay even after the driver is removed.");

  // ── Vehicle detail ─────────────────────────────────────────────────────
  String get payback => _('গাড়ির দাম উঠেছে', 'Payback progress');
  String paybackLeft(String amount) => _('আর $amount উঠলে দাম উঠে যাবে', '$amount more to recover the price');
  String get paybackDone => _('গাড়ির দাম উঠে গেছে, এখন সব লাভ', 'Price recovered — it is all profit now');
  String get avgDaily => _('দৈনিক গড় আয়', 'Avg. daily income');
  String get fuelCost => _('জ্বালানি খরচ', 'Fuel cost');
  String get repairCost => _('মেরামত খরচ', 'Repair cost');
  String get papers => _('কাগজপত্র', 'Papers');
  String get addPaper => _('কাগজ যোগ করুন', 'Add paper');
  String get paperType => _('কাগজের ধরন', 'Paper type');
  String get expiryDate => _('মেয়াদ শেষের তারিখ', 'Expiry date');
  String get noPapers => _('কোনো কাগজের মেয়াদ যোগ করা হয়নি', 'No paper expiry dates added');
  String expiresIn(int d) => d < 0
      ? _('${n(-d)} দিন আগে মেয়াদ শেষ', 'Expired ${-d} days ago')
      : d == 0
          ? _('আজ মেয়াদ শেষ', 'Expires today')
          : _('${n(d)} দিন বাকি', '$d days left');
  String get history => _('লেনদেন', 'History');
  String get monthlyTrend => _('মাসভিত্তিক আয়-খরচ', 'Monthly income vs expense');
  String get mileage => _('মাইলেজ', 'Mileage');
  String get kmPerUnit => _('কিমি/ইউনিট', 'km/unit');

  // ── Driver detail ──────────────────────────────────────────────────────
  String get currentDue => _('বর্তমান বাকি', 'Current due');
  String get noDue => _('কোনো বাকি নেই', 'No dues');
  String get advanceBalance => _('অগ্রিম জমা আছে', 'Paid in advance');
  String get last60Days => _('গত ৬০ দিনের জমা', 'Last 60 days');
  String get legendFull => _('পুরো', 'Full');
  String get legendPartial => _('আংশিক', 'Partial');
  String get legendNone => _('জমা নেই', 'Nothing');
  String get legendOff => _('বন্ধ', 'Off');
  String get collectDue => _('বাকি আদায় করুন', 'Collect due');
  String get totalGiven => _('মোট জমা দিয়েছে', 'Total paid');
  String get workingDays => _('কাজের দিন', 'Working days');

  // ── Ledger ─────────────────────────────────────────────────────────────
  String get ledger => _('হিসাবের খাতা', 'Ledger');
  String get noEntries => _('এখনো কোনো হিসাব নেই', 'No entries yet');
  String get noEntriesBody => _('নিচের + বোতাম চেপে প্রথম হিসাব লিখুন', 'Tap + below to record your first entry');
  String get filterAll => _('সব', 'All');
  String get filterIncome => _('আয়', 'Income');
  String get filterExpense => _('খরচ', 'Expense');
  String get deleteEntry => _('হিসাবটি মুছবেন?', 'Delete this entry?');

  // ── Reports ────────────────────────────────────────────────────────────
  String get reports => _('রিপোর্ট', 'Reports');
  String get whoEarnedMost => _('কোন গাড়ি কত লাভ দিল', 'Which vehicle earned what');
  String get expenseBreakdown => _('খরচ কোথায় যাচ্ছে', 'Where the money goes');
  String get sixMonths => _('গত ৬ মাস', 'Last 6 months');
  String get margin => _('মার্জিন', 'Margin');
  String get noData => _('এই সময়ে কোনো হিসাব নেই', 'Nothing recorded in this period');
  String get custom => _('নিজে বাছাই', 'Custom');

  // ── Settings ───────────────────────────────────────────────────────────
  String get settings => _('সেটিংস', 'Settings');
  String get profile => _('প্রোফাইল', 'Profile');
  String get ownerName => _('মালিকের নাম', "Owner's name");
  String get businessName => _('ব্যবসার নাম', 'Business name');
  String get language => _('ভাষা', 'Language');
  String get appearance => _('থিম', 'Appearance');
  String get themeSystem => _('ফোনের মতো', 'System');
  String get themeLight => _('লাইট', 'Light');
  String get themeDark => _('ডার্ক', 'Dark');
  String get banglaDigits => _('বাংলা সংখ্যা', 'Bangla numerals');
  String get banglaDigitsSub => _('১২৩ বনাম 123', '১২৩ vs 123');
  String get dataBackup => _('ডাটা ও ব্যাকআপ', 'Data & backup');
  String get backupRestore => _('ব্যাকআপ ও রিস্টোর', 'Backup & restore');
  String get documentsReminders => _('কাগজের মেয়াদ', 'Paper reminders');
  String get resetData => _('সব ডাটা মুছে ফেলুন', 'Erase all data');
  String get resetConfirm => _('সব গাড়ি, ড্রাইভার ও হিসাব মুছে যাবে। আগে ব্যাকআপ নিয়েছেন তো?', 'Every vehicle, driver and entry will be erased. Did you back up first?');
  String get about => _('অ্যাপ সম্পর্কে', 'About');
  String get version => _('ভার্সন', 'Version');

  // ── Backup ─────────────────────────────────────────────────────────────
  String get backup => _('ব্যাকআপ', 'Backup');
  String get googleDrive => _('গুগল ড্রাইভ', 'Google Drive');
  String get googleDriveSub => _('আপনার নিজের ড্রাইভে নিরাপদে রাখা হয়', 'Stored privately in your own Drive');
  String get connectDrive => _('গুগল অ্যাকাউন্ট যুক্ত করুন', 'Connect Google account');
  String get disconnect => _('সংযোগ বিচ্ছিন্ন', 'Disconnect');
  String get backupNow => _('এখনই ব্যাকআপ নিন', 'Back up now');
  String get restoreFromDrive => _('ড্রাইভ থেকে রিস্টোর', 'Restore from Drive');
  String get lastBackup => _('শেষ ব্যাকআপ', 'Last backup');
  String get never => _('কখনো না', 'Never');
  String get localFile => _('ফোনে / কম্পিউটারে ফাইল', 'Local file');
  String get localFileSub => _('SQLite ফাইল হিসেবে সেভ বা শেয়ার করুন', 'Save or share as an SQLite file');
  String get exportFile => _('ফাইল এক্সপোর্ট', 'Export file');
  String get importFile => _('ফাইল থেকে রিস্টোর', 'Restore from file');
  String get backupDone => _('ব্যাকআপ সম্পন্ন হয়েছে', 'Backup complete');
  String get restoreDone => _('রিস্টোর সম্পন্ন হয়েছে', 'Restore complete');
  String get restoreConfirm => _('এখনকার সব ডাটা এই ব্যাকআপ দিয়ে বদলে যাবে। চালিয়ে যাবেন?', 'Current data will be replaced by this backup. Continue?');
  String get restore => _('রিস্টোর', 'Restore');
  String get invalidBackup => _('ফাইলটা সঠিক ব্যাকআপ না', 'That file is not a valid backup');
  String get noDriveBackups => _('ড্রাইভে কোনো ব্যাকআপ পাওয়া যায়নি', 'No backups found in Drive');
  String get chooseBackup => _('কোন ব্যাকআপটা রিস্টোর করবেন?', 'Which backup to restore?');
  String get driveNotConfigured => _('গুগল ড্রাইভ এখনো কনফিগার করা হয়নি। README দেখুন।', 'Google Drive is not configured yet. See the README.');
  String get autoBackup => _('অটো ব্যাকআপ', 'Auto backup');
  String get autoBackupSub => _('দিনে একবার অ্যাপ খুললে ড্রাইভে ব্যাকআপ', 'Back up to Drive once a day on app open');
  String get dbStats => _('ডাটাবেসে আছে', 'In the database');
  String get records => _('টি এন্ট্রি', 'entries');
  String somethingWrong(Object e) => _('সমস্যা হয়েছে: $e', 'Something went wrong: $e');

  // ── Onboarding ─────────────────────────────────────────────────────────
  String get onb1Title => _('প্রতিদিনের জমা, এক ট্যাপে', "Daily collection, in one tap");
  String get onb1Body => _('সিএনজি, প্রাইভেট কার, পিকআপ — সব গাড়ির ড্রাইভার কত জমা দিল, কত বাকি রইল, সব লিখে রাখুন।', 'CNG, car, pickup — record what every driver handed over and what is still due.');
  String get onb2Title => _('কোন গাড়ি কত লাভ দিল', 'Know which vehicle pays');
  String get onb2Body => _('জ্বালানি, মেরামত, কাগজপত্রের খরচ বাদ দিয়ে প্রতিটা গাড়ির আসল লাভ দেখুন।', 'See the real profit of every vehicle after fuel, repairs and papers.');
  String get onb3Title => _('ডাটা থাকবে নিরাপদে', 'Your data stays safe');
  String get onb3Body => _('সব হিসাব ফোনেই থাকে, আর গুগল ড্রাইভে ব্যাকআপ নিতে পারবেন।', 'Everything lives on your phone, with backups to your Google Drive.');
  String get getStarted => _('শুরু করুন', 'Get started');
  String get whatsYourName => _('আপনার নাম কী?', "What's your name?");
}

const _bnDigitMap = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

String bnDigits(Object value) => toBnDigits(value.toString());

String toBnDigits(String s) {
  final b = StringBuffer();
  for (final c in s.codeUnits) {
    if (c >= 48 && c <= 57) {
      b.write(_bnDigitMap[c - 48]);
    } else {
      b.writeCharCode(c);
    }
  }
  return b.toString();
}
