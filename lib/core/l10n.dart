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
  String get navTrips => _('ট্রিপ', 'Trips');
  String get navParts => _('পার্টস ও মেইনটেন্যান্স', 'Parts & upkeep');

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
  String get partFittedSub => _('কোন পার্টস কবে লাগালেন', 'What was fitted, and when');
  String get paperExpirySub => _('ট্যাক্স টোকেন, ফিটনেস', 'Tax token, fitness');
  String get otherCost => _('অন্যান্য খরচ', 'Other costs');
  String get otherCostSub => _('পার্কিং, ধোয়া, মামলা, কিস্তি', 'Parking, wash, fines, loans');
  String get visitQuick => _('সার্ভিসিং / মেরামত', 'Service / repair');
  String get visitQuickSub => _('পার্টস, দাম, দোকান, মজুরি', 'Parts, prices, shops, labour');
  String get partyCollectQuick => _('পার্টির টাকা আদায়', 'Collect from client');
  String get partyCollectQuickSub => _('বাকি থাকা ট্রিপের ভাড়া', 'Unpaid trip fares');

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
  String get vehicleInfo => _('গাড়ির তথ্য', 'Vehicle details');
  String get moreDetails => _('আরও তথ্য: চেসিস, ইঞ্জিন, রং…', 'More: chassis, engine, colour…');
  String get chassisNo => _('চেসিস নম্বর', 'Chassis no.');
  String get engineNo => _('ইঞ্জিন নম্বর', 'Engine no.');
  String get color => _('রং', 'Colour');
  String get modelYear => _('মডেল বছর', 'Model year');
  String get fuelType => _('জ্বালানির ধরন', 'Fuel type');
  String get capacity => _('ধারণক্ষমতা', 'Capacity');
  String get capacityHint => _('যেমন: ৪ সিট, ১.৫ টন', 'e.g. 4 seats, 1.5 t');
  String get licenseExpiry => _('লাইসেন্সের মেয়াদ শেষ', 'Licence expires');
  String get licensesExpiring => _('লাইসেন্সের মেয়াদ', 'Licences expiring');
  String get docNo => _('নম্বর (টোকেন / পলিসি)', 'Number (token / policy)');
  String get provider => _('অফিস / কোম্পানি', 'Office / company');
  String get providerHint => _('যেমন: বিআরটিএ মিরপুর', 'e.g. BRTA Mirpur');
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

  // ── Trips ──────────────────────────────────────────────────────────────
  String get trips => _('ট্রিপ', 'Trips');
  String get newTrip => _('নতুন ট্রিপ', 'New trip');
  String get newTripSub => _('রুট, ভাড়া ও রাস্তার খরচ', 'Route, fare, road costs');
  String get editTrip => _('ট্রিপ এডিট', 'Edit trip');
  String get trip => _('ট্রিপ', 'Trip');
  String get tripOrigin => _('কোথা থেকে', 'From');
  String get tripOriginHint => _('যেমন: ঢাকা', 'e.g. Dhaka');
  String get tripDestination => _('কোথায়', 'To');
  String get tripDestinationHint => _('যেমন: চট্টগ্রাম', 'e.g. Chattogram');
  String get route => _('রুট', 'Route');
  String get startDate => _('যাওয়ার তারিখ', 'Start date');
  String get endDate => _('ফেরার তারিখ (ঐচ্ছিক)', 'Return date (optional)');
  String get client => _('পার্টি / যাত্রী (ঐচ্ছিক)', 'Client / passenger (optional)');
  String get fare => _('ভাড়া', 'Fare');
  String get fareHelp => _('পার্টি মোট কত ভাড়া দিল', 'What the client paid in total');
  String get startKm => _('শুরুর মিটার (কিমি)', 'Start odometer (km)');
  String get endKm => _('শেষের মিটার (কিমি)', 'End odometer (km)');
  String get distance => _('দূরত্ব', 'Distance');
  String get km => _('কিমি', 'km');
  String get roadCosts => _('রাস্তার খরচ', 'Road costs');
  String get addCost => _('খরচ যোগ করুন', 'Add cost');
  String get editCost => _('খরচ এডিট', 'Edit cost');
  String get noCostsYet => _('এখনো কোনো খরচ যোগ করা হয়নি। তেল, মবিল, টোল — যা খরচ হলো নিচ থেকে যোগ করুন।', 'No costs yet. Add fuel, oil, tolls and other road costs below.');
  String get place => _('কোথায় খরচ হলো', 'Where');
  String get placeHint => _('যেমন: মেঘনা ব্রিজ, কুমিল্লা', 'e.g. Meghna bridge, Cumilla');
  String get quantityOptional => _('পরিমাণ (লিটার / m³)', 'Quantity (litres / m³)');
  String get tripCost => _('ট্রিপের খরচ', 'Trip cost');
  String get tripProfit => _('ট্রিপের লাভ', 'Trip profit');
  String get costPerKm => _('প্রতি কিমি খরচ', 'Cost per km');
  String get noTrips => _('এই সময়ে কোনো ট্রিপ নেই', 'No trips in this period');
  String get noTripsBody => _('নতুন ট্রিপ যোগ করে কোথায় গেল, কত ভাড়া পেলেন আর রাস্তায় কত খরচ হলো লিখে রাখুন', 'Add a trip to record where it went, the fare and the road costs');
  String tripCount(int c) => _('${n(c)} টি ট্রিপ', '$c trips');
  String get deleteTrip => _('ট্রিপটি মুছবেন?', 'Delete this trip?');
  String get deleteTripBody => _('এই ট্রিপের ভাড়া ও সব খরচের হিসাবও মুছে যাবে।', 'Its fare and every cost will be deleted too.');
  String get endKmTooLow => _('শুরুর মিটারের চেয়ে কম হতে পারে না', 'Cannot be less than the start reading');
  String get endBeforeStart => _('ফেরার তারিখ যাওয়ার তারিখের আগে হতে পারে না', 'Return date cannot be before the start date');
  String get tripSaved => _('ট্রিপ সেভ হয়েছে', 'Trip saved');
  String get recentTrips => _('সাম্প্রতিক ট্রিপ', 'Recent trips');
  String get tripSummary => _('ট্রিপের হিসাব', 'Trip summary');
  String dayCount(int c) => _('${n(c)} দিন', c == 1 ? '1 day' : '$c days');
  String get costShare => _('খরচ কোথায় গেল', 'Where the cost went');
  String get tripStatus => _('ট্রিপের অবস্থা', 'Trip status');
  String get clientPhone => _('পার্টির মোবাইল', "Client's phone");
  String get goods => _('মালামাল / যাত্রী', 'Cargo / passengers');
  String get goodsHint => _('যেমন: ২০০ বস্তা সিমেন্ট', 'e.g. 200 bags of cement');
  String get challanNo => _('চালান / বুকিং নম্বর', 'Challan / booking no.');
  String get businessDetails => _('ব্যবসার তথ্য', 'Business details');
  String get payments => _('পার্টির পেমেন্ট', 'Payments from client');
  String get addPayment => _('অগ্রিম / আদায় যোগ করুন', 'Add advance / payment');
  String get received => _('আদায় হয়েছে', 'Received');
  String get partyDue => _('পার্টির কাছে পাওনা', 'Due from client');
  String get paidInFull => _('পুরো টাকা পাওয়া গেছে', 'Paid in full');
  String get collectPayment => _('টাকা আদায় করুন', 'Collect payment');
  String get payMethod => _('কীভাবে দিল', 'Paid by');
  String get noPayments => _('এখনো কোনো টাকা পাওয়া যায়নি', 'Nothing received yet');
  String get paymentSaved => _('আদায় সেভ হয়েছে', 'Payment saved');
  String get deletePayment => _('এই আদায়টি মুছবেন?', 'Delete this payment?');
  String get parties => _('পার্টির হিসাব', 'Clients');
  String get partiesSub => _('কোন পার্টির কাছে কত পাওনা', 'Who owes how much');
  String get noParties => _('এখনো কোনো পার্টি নেই', 'No clients yet');
  String get noPartiesBody => _('ট্রিপে পার্টির নাম লিখলে এখানে তাদের হিসাব দেখাবে', 'Clients named on trips show up here');
  String get totalDue => _('মোট পাওনা', 'Total due');
  String get lastTrip => _('শেষ ট্রিপ', 'Last trip');
  String get partyDues => _('পার্টির পাওনা', 'Client dues');
  String get unpaidTrips => _('টাকা বাকি আছে এমন ট্রিপ', 'Trips with money due');

  // ── Garage / service visits ────────────────────────────────────────────
  String get visit => _('সার্ভিসিং / মেরামত', 'Service / repair');
  String get newVisit => _('নতুন সার্ভিসিং / মেরামত', 'New garage visit');
  String get editVisit => _('সার্ভিসিং এডিট', 'Edit visit');
  String get whereServiced => _('কোথায় করালেন', 'Where');
  String get workshop => _('গ্যারেজ / সার্ভিস সেন্টারের নাম', 'Garage / service centre');
  String get workshopHint => _('যেমন: মায়ের দোয়া অটো গ্যারেজ', 'e.g. City Auto Garage');
  String get mechanic => _('মিস্ত্রি / অ্যাডভাইজার', 'Mechanic / advisor');
  String get jobNo => _('জব কার্ড / বিল নম্বর', 'Job card / bill no.');
  String get workDone => _('কী কাজ হলো', 'Work done');
  String get workDoneHint => _('যেমন: ১০,০০০ কিমি সার্ভিস, ২য় ফ্রি সার্ভিস', 'e.g. 10,000 km service, 2nd free service');
  String get labour => _('মজুরি / সার্ভিস চার্জ', 'Labour / service charge');
  String get labourShort => _('মজুরি', 'Labour');
  String get serviceShort => _('সার্ভিসিং', 'Service');
  String get partsFitted => _('যে পার্টস লাগানো হলো', 'Parts fitted');
  String get noPartsInVisit => _('এই ভিজিটে কোনো পার্টস যোগ করা হয়নি', 'No parts added to this visit');
  String get nextService => _('পরবর্তী সার্ভিসিং', 'Next service');
  String get serviceAfterKm => _('কত কিমি পর আবার', 'Again after (km)');
  String get serviceAfterMonths => _('কত মাস পর আবার', 'Again after (months)');
  String get visitTotal => _('মোট বিল', 'Total bill');
  String get partsCost => _('পার্টসের দাম', 'Parts');
  String get serviceBook => _('সার্ভিস বই', 'Service book');
  String get noVisits => _('এখনো কোনো সার্ভিসিংয়ের হিসাব নেই', 'No garage visits yet');
  String get noVisitsBody => _('গ্যারেজে গেলে কোন পার্টস লাগালেন, দাম, দোকান আর মিস্ত্রির বিল এক জায়গায় লিখে রাখুন', 'Record each garage visit: parts, prices, shops and labour in one place');
  String get visitsIn => _('সার্ভিসিং ও মেরামত', 'Garage visits');
  String get serviceDue => _('সার্ভিসিংয়ের সময়', 'Service due');
  String get deleteVisit => _('এই সার্ভিসিংয়ের হিসাব মুছবেন?', 'Delete this visit?');
  String get deleteVisitBody => _('এর পার্টস আর বিলও খাতা থেকে মুছে যাবে।', 'Its parts and bill will be removed from the ledger too.');
  String get visitSaved => _('সার্ভিসিং সেভ হয়েছে', 'Visit saved');
  String get whatToAdd => _('কী যোগ করবেন?', 'What do you want to add?');
  String get singlePart => _('শুধু একটা পার্টস', 'Just one part');
  String get singlePartSub => _('গ্যারেজ ছাড়া নিজে লাগালে', 'Fitted without a garage visit');
  String get shop => _('কোন দোকান থেকে কিনলেন', 'Bought from (shop)');
  String get shopHint => _('যেমন: হাজী অটো পার্টস, বংশাল', 'e.g. Haji Auto Parts, Bangshal');
  String get qty => _('পরিমাণ', 'Qty');
  String get priceTotal => _('দাম (মোট)', 'Price (total)');
  String get each => _('প্রতিটি', 'each');
  String get warrantyUntil => _('ওয়ারেন্টি শেষ (ঐচ্ছিক)', 'Warranty until (optional)');
  String warrantyLeft(int d) => d < 0 ? _('ওয়ারেন্টি শেষ', 'Out of warranty') : _('ওয়ারেন্টি ${n(d)} দিন বাকি', 'Warranty: $d days left');

  // ── Parts & maintenance ────────────────────────────────────────────────
  String get maintenanceCost => _('মেইনটেন্যান্স খরচ', 'Maintenance cost');
  String get maintenanceHelp => _('সার্ভিসিং, পার্টস, মবিল, টায়ার, মেরামত ও ধোয়া-মোছা', 'Servicing, parts, oil, tyres, repairs and washing');
  String get byVehicle => _('কোন গাড়িতে কত খরচ', 'By vehicle');
  String get last6Months => _('গত ৬ মাস', 'Last 6 months');
  String get partsDue => _('পার্টস বদলানোর সময়', 'Parts due for a change');
  String get partsDueShort => _('পার্টস বদলাতে হবে', 'Parts due');
  String get installedParts => _('এখন লাগানো পার্টস', 'Currently fitted');
  String get partsFittedIn => _('যে পার্টস লাগানো হয়েছে', 'Parts fitted');
  String get addPart => _('পার্টস যোগ করুন', 'Add part');
  String get partFitted => _('পার্টস লাগানো', 'Part fitted');
  String get partsShort => _('পার্টস', 'Parts');
  String get editPart => _('পার্টস এডিট', 'Edit part');
  String get whichPart => _('কোন পার্টস', 'Which part');
  String get partDetail => _('ব্র্যান্ড / বিবরণ (ঐচ্ছিক)', 'Brand / detail (optional)');
  String get partDetailHint => _('যেমন: Shell 20W-50', 'e.g. Shell 20W-50');
  String get partName => _('পার্টসের নাম', 'Part name');
  String get fittedOn => _('লাগানোর তারিখ', 'Fitted on');
  String get kmAtFitting => _('লাগানোর সময় মিটার (কিমি)', 'Odometer when fitted (km)');
  String get partCost => _('দাম (মজুরিসহ)', 'Cost (with labour)');
  String get changeAfterKm => _('কত কিমি পর বদলাবেন', 'Change after (km)');
  String get changeAfterMonths => _('কত মাস পর বদলাবেন', 'Change after (months)');
  String get nextChange => _('পরবর্তী বদলানো', 'Next change');
  String get whicheverFirst => _('যেটা আগে আসে', 'whichever comes first');
  String get or => _('অথবা', 'or');
  String get noSchedule => _('বদলানোর সময় দেওয়া নেই', 'No change schedule');
  String get noParts => _('এখনো কোনো পার্টসের হিসাব নেই', 'No parts recorded yet');
  String get noPartsBody => _('মবিল, ফিল্টার, টায়ার — কবে লাগালেন লিখে রাখুন, বদলানোর সময় হলে অ্যাপ মনে করিয়ে দেবে', 'Record oil, filters and tyres — the app reminds you when they are due');
  String get noPartsThisMonth => _('এই মাসে কোনো পার্টস লাগানো হয়নি', 'Nothing fitted this month');
  String get allPartsOk => _('সব পার্টস ঠিক আছে', 'All parts are fine');
  String partOverdueDays(int d) => _('${n(d)} দিন পেরিয়ে গেছে', '$d days overdue');
  String partOverdueKm(String k) => _('$k কিমি বেশি চলেছে', '$k km overdue');
  String partDaysLeft(int d) => d == 0 ? _('আজ বদলাতে হবে', 'Change today') : _('${n(d)} দিন বাকি', '$d days left');
  String partKmLeft(String k) => _('$k কিমি বাকি', '$k km left');
  String get fitted => _('লাগানো', 'Fitted');
  String get odometerNow => _('এখন মিটার', 'Odometer now');
  String get deletePart => _('পার্টসের হিসাবটি মুছবেন?', 'Delete this part record?');
  String get deletePartBody => _('এর খরচের হিসাবও খাতা থেকে মুছে যাবে।', 'Its cost will be removed from the ledger too.');
  String get months => _('মাস', 'months');
  String partsDueCount(int c) => _('${n(c)} টি বদলাতে হবে', '$c due');

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
