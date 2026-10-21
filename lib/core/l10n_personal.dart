import 'l10n.dart';

/// Strings for picking a mode and for the owner's own (personal) cars.
extension PersonalStrings on S {
  String _t(String b, String e) => bn ? b : e;

  // ── Mode ─────────────────────────────────────────────────────────────────
  String get modeTitle => _t('কোন হিসাব রাখবেন?', 'What do you want to track?');
  String get modeBody => _t('পরে যেকোনো সময় ড্যাশবোর্ড থেকে বদলাতে পারবেন।', 'You can switch any time from the dashboard.');
  String get modeFleet => _t('গাড়ির মালিকের হিসাব', 'Fleet owner');
  String get modeFleetBody =>
      _t('ভাড়ার গাড়ির ব্যবসা — দৈনিক জমা, ড্রাইভারের বাকি, ট্রিপ, পার্টি ও লাভ-ক্ষতি।', 'Rental business — daily collection, driver dues, trips, parties and profit.');
  String get modePersonal => _t('শুধু নিজের গাড়ির হিসাব', 'My own car');
  String get modePersonalBody =>
      _t('নিজের গাড়ির পুরো খরচ — জ্বালানি ও মাইলেজ, সার্ভিসিং, পার্টস, কাগজপত্র।', 'Everything your car costs — fuel and mileage, servicing, parts, papers.');
  String get modeFleetShort => _t('ভাড়ার গাড়ি', 'Fleet');
  String get modeSwitch => _t('হিসাব বদলান', 'Switch books');
  String get modeCurrent => _t('এখন চলছে', 'Current');
  String get modeSeparate => _t('দুই হিসাবের ডাটা আলাদা থাকে — একটার খরচ আরেকটায় যায় না।', 'The two books keep separate data — nothing mixes.');

  // ── Personal dashboard ───────────────────────────────────────────────────
  String get myCars => _t('আমার গাড়ি', 'My cars');
  String get myCar => _t('আমার গাড়ি', 'My car');
  String get addCar => _t('গাড়ি যোগ করুন', 'Add a car');
  String get personalWelcomeTitle => _t('নিজের গাড়ির পুরো হিসাব', 'Your car, fully accounted');
  String get personalWelcomeBody => _t(
      'জ্বালানি লিখলেই মাইলেজ ও প্রতি কিমি খরচ বের হবে। সার্ভিসিং, পার্টস আর কাগজের মেয়াদও মনে করিয়ে দেবে।',
      'Log fuel and see mileage and cost per km. Servicing, parts and paper expiry get reminders too.');
  String get spentThisMonth => _t('এই মাসের খরচ', 'Spent this month');
  String get vsLastMonth => _t('গত মাসের তুলনায়', 'vs last month');
  String get runningCost => _t('চালানোর খরচ', 'Running cost');
  String get totalOwnership => _t('মোট খরচ (শুরু থেকে)', 'Total spent (all time)');
  String get perDayCost => _t('প্রতিদিন গড়ে', 'Per day on average');
  String get allCostPerKm => _t('সব মিলিয়ে প্রতি কিমি', 'All-in per km');
  String get fuelPerKm => _t('জ্বালানি প্রতি কিমি', 'Fuel per km');
  String get spendTrend => _t('মাসিক খরচ', 'Monthly spend');
  String get whereMoneyGoes => _t('টাকা কোথায় যাচ্ছে', 'Where the money goes');
  String get costBook => _t('খরচের খাতা', 'Cost book');
  String get totalSpend => _t('মোট খরচ', 'Total spent');
  String get costShort => _t('খরচ', 'Cost');
  String get otherCostPersonal => _t('অন্য খরচ', 'Other cost');
  String get otherCostPersonalSub => _t('পার্কিং, টোল, ধোয়া, মেরামত', 'Parking, tolls, wash, repairs');
  String get carDetails => _t('গাড়ির তথ্য', 'Car details');
  String get noCostYet => _t('এখনো কোনো খরচ লেখা হয়নি', 'No costs recorded yet');

  // ── Fuel log ─────────────────────────────────────────────────────────────
  String get fuelLog => _t('জ্বালানির খাতা', 'Fuel log');
  String get addFuel => _t('জ্বালানি নিলাম', 'Add fill-up');
  String get addFuelSub => _t('মিটার, লিটার, দাম — মাইলেজ নিজেই হিসাব হবে', 'Odometer, litres, price — mileage works itself out');
  String get editFuel => _t('জ্বালানি এডিট', 'Edit fill-up');
  String get avgMileage => _t('গড় মাইলেজ', 'Average mileage');
  String get lastMileage => _t('শেষ ফিলের মাইলেজ', 'Last fill mileage');
  String get bestMileage => _t('সেরা', 'Best');
  String get worstMileage => _t('সবচেয়ে কম', 'Worst');
  String get avgPrice => _t('গড় দাম', 'Average price');
  String get lastPrice => _t('শেষ দাম', 'Last price');
  String get fillsCount => _t('কতবার নেওয়া', 'Fill-ups');
  String get everyDays => _t('গড়ে প্রতি', 'Every');
  String get kmDriven => _t('চালানো হয়েছে', 'Driven');
  String get totalFuel => _t('মোট জ্বালানি', 'Total fuel');
  String get fuelSpend => _t('জ্বালানি খরচ', 'Fuel spend');
  String get mileageTrend => _t('মাইলেজের ধারা', 'Mileage trend');
  String get priceTrend => _t('দামের ধারা', 'Price trend');
  String get monthlyFuel => _t('মাসিক জ্বালানি', 'Fuel per month');
  String get fillHistory => _t('সব ফিল', 'All fill-ups');
  String get noFuelTitle => _t('এখনো জ্বালানি লেখা হয়নি', 'No fill-ups yet');
  String get noFuelBody => _t(
      'প্রতিবার ট্যাংক ফুল করে মিটার রিডিং লিখুন — দুইবার ফুল করলেই মাইলেজ দেখা যাবে।',
      'Fill the tank and note the odometer each time — two full tanks and you see the mileage.');
  String get needTwoFull => _t('মাইলেজ দেখতে আরেকবার ফুল ট্যাংক করে লিখুন', 'Log one more full tank to see mileage');
  String get fullTank => _t('ফুল ট্যাংক', 'Full tank');
  String get fullTankSub => _t('একদম ভরে নিয়েছেন — মাইলেজ এটা থেকেই মাপা হয়', 'Filled to the brim — mileage is measured from full tanks');
  String get partialFill => _t('আংশিক', 'Partial');
  String get missedFill => _t('আগের একটা ফিল লেখা হয়নি', 'Missed logging a fill-up');
  String get missedFillSub => _t('চালু করলে এই ফিলের মাইলেজ বাদ যাবে, ভুল হিসাব হবে না', 'Skips this stretch so a gap does not skew mileage');
  String get missedShort => _t('মিস', 'Missed');
  String get quantity => _t('পরিমাণ', 'Quantity');
  String get unitPrice => _t('দাম / ইউনিট', 'Price / unit');
  String get totalBill => _t('মোট বিল', 'Total bill');
  String get autoCalc => _t('যেকোনো দুইটা দিলে তৃতীয়টা নিজেই হবে', 'Fill any two — the third is worked out');
  String get station => _t('পাম্প / স্টেশন', 'Pump / station');
  String get stationHint => _t('যেমন: মেঘনা পেট্রোলিয়াম, বনানী', 'e.g. Meghna Petroleum, Banani');
  String get paidBy => _t('কিভাবে দিলেন', 'Paid by');
  String get odometerReq => _t('মিটার রিডিং (কিমি)', 'Odometer (km)');
  String lastOdo(String v) => _t('শেষ রিডিং: $v', 'Last reading: $v');
  String get odoBelowLast => _t('আগের রিডিং থেকে কম — ঠিক আছে তো?', 'Lower than the last reading — is that right?');
  String get previewMileage => _t('এই ফিলে মাইলেজ', 'Mileage this fill');
  String get previewCostKm => _t('প্রতি কিমি', 'Per km');
  String get enterAmountOrQty => _t('মোট বিল অথবা পরিমাণ ও দাম দিন', 'Enter the bill, or quantity and price');
  String mileageUnit(String unit) => _t('কিমি/$unit', 'km/$unit');

  // ── Fuel alerts ──────────────────────────────────────────────────────────
  String get mileageDropTitle => _t('মাইলেজ কমে গেছে', 'Mileage dropped');
  String mileageDropBody(String pct) => _t(
      'শেষ ফিলে আগের চেয়ে $pct কম মাইলেজ। টায়ারের হাওয়া, এয়ার ফিল্টার বা ইঞ্জিন দেখিয়ে নিন।',
      'Last fill gave $pct less than before. Check tyre pressure, the air filter or the engine.');
  String get fuelReminderTitle => _t('জ্বালানি লেখা বাকি?', 'Forgot a fill-up?');
  // ── Costs to come / conversion ──────────────────────────────────────────
  String get renewalCost => _t('নবায়ন খরচ', 'Renewal cost');
  String get renewalCostHelp => _t('ফি / প্রিমিয়াম — খরচের পূর্বাভাসে যোগ হবে', 'Fee / premium — used in the cost forecast');
  String get conversionCost => _t('সিএনজি কনভার্শন খরচ', 'CNG conversion cost');
  String get conversionCostHelp => _t('দিলে দেখাবে সাশ্রয় দিয়ে কবে উঠে আসবে', 'Shows when the savings pay it back');

  String savedThisYear(String fuel) => _t('এই বছর $fuel-তে চালিয়ে সাশ্রয়', 'Saved this year by running on $fuel');
  String perKmCompare(String a) => _t('প্রতি কিমি: $a', 'Per km: $a');
  String savedAllTime(String v) => _t('শুরু থেকে মোট সাশ্রয় $v', '$v saved in total');
  String paybackProgress(String cost, String pct) => _t('কনভার্শনের $cost এর $pct উঠে এসেছে', '$pct of the $cost conversion paid back');
  String paybackBy(String date) => _t('এই হারে পুরোটা উঠবে $date নাগাদ', 'Fully paid back by $date at this pace');
  String get paybackDoneBody => _t('কনভার্শনের খরচ পুরো উঠে গেছে — এখন থেকে পুরোটাই লাভ', 'The conversion has paid for itself — it is all profit now');
  String savingPerMonth(String v) => _t('মাসে গড়ে $v বাঁচছে', 'About $v saved a month');

  // ── Forecast ─────────────────────────────────────────────────────────────
  String get forecastTitle => _t('আগামী ১২ মাসের খরচ', 'Next 12 months');
  String get forecastSub => _t('কাগজ, সার্ভিসিং, পার্টস, জ্বালানি — আগে থেকেই জানুন', 'Papers, servicing, parts, fuel — know ahead');
  String avgPerMonth(String v) => _t('মাসে গড়ে $v', '$v a month on average');
  String get comingUp => _t('সামনে যা আসছে', 'Coming up');
  String heaviestMonth(String month, String v) =>
      _t('$month মাসে বাড়তি $v লাগবে — আগে থেকে রেখে দিন', '$month needs an extra $v — set it aside early');
  String get costUnknown => _t('খরচ জানা নেই', 'Cost unknown');
  String unknownHint(int c) => _t(
      '${n(c)}টা খরচের পরিমাণ জানা নেই — কাগজপত্রে নবায়ন খরচ দিলে হিসাব আরো ঠিক হবে।',
      '$c costs have no amount yet — add renewal costs to papers for a sharper forecast.');
  String get renewal => _t('নবায়ন', 'renewal');
  String get serviceForecast => _t('সার্ভিসিং (আগের গড়)', 'Service (past average)');
  String get fuelForecast => _t('জ্বালানি (গত ৩ মাসের গড়)', 'Fuel (last 3 months\' pace)');
  String get regularForecast => _t('নিয়মিত খরচ (পার্কিং, বেতন, টোল…)', 'Everyday costs (parking, salary, tolls…)');
  String get overdueNow => _t('বাকি পড়ে আছে', 'Overdue');
  String get forecastEmpty => _t(
      'জ্বালানি, সার্ভিসিং আর কাগজের মেয়াদ লিখলেই সামনের খরচ এখানে দেখা যাবে।',
      'Log fuel, services and paper expiry and your upcoming costs appear here.');
  String kmPerDayText(String v) => _t('গাড়ি দিনে গড়ে $v কিমি চলে', 'The car does $v km a day');

  // ── Budget ───────────────────────────────────────────────────────────────
  String get budget => _t('মাসিক বাজেট', 'Monthly budget');
  String get setBudget => _t('মাসিক বাজেট ঠিক করুন', 'Set a monthly budget');
  String get setBudgetSub => _t('মাসে কত খরচ করবেন ঠিক করুন — ছাড়িয়ে যাওয়ার আগেই জানিয়ে দেবে', 'Decide what to spend a month — get warned before you go over');
  String budgetUsed(String spent, String budget) => _t('$spent খরচ হয়েছে $budget এর মধ্যে', '$spent of $budget spent');
  String budgetLeft(String v, int d) => _t('বাকি $v · আর ${n(d)} দিন', '$v left · $d days to go');
  String budgetPerDay(String v) => _t('দিনে সর্বোচ্চ $v', 'Up to $v a day');
  String budgetProjected(String v) => _t('এই হারে মাস শেষে হবে $v', 'At this pace: $v by month-end');
  String budgetOver(String v) => _t('বাজেট $v ছাড়িয়ে গেছে', 'Over budget by $v');
  String get budgetOnTrack => _t('ঠিক পথে আছেন', 'On track');
  String get budgetWatch => _t('সাবধান — বাজেট ছাড়াতে পারে', 'Careful — heading over');
  String get budgetHint => _t('জ্বালানি, সার্ভিসিং, বেতন — সব খরচ মিলিয়ে', 'Fuel, servicing, salary — everything together');
  String get removeBudget => _t('বাজেট বাদ দিন', 'Remove budget');

  // ── Value ────────────────────────────────────────────────────────────────
  String get carValue => _t('গাড়ির দাম কত কমলো', 'What the car has lost');
  String get boughtAt => _t('কেনা দাম', 'Bought for');
  String get worthNow => _t('এখনকার দাম', 'Worth now');
  String get estimatedTag => _t('আনুমানিক', 'estimated');
  String lostSince(String v, String pct) => _t('কমেছে $v ($pct)', 'Lost $v ($pct)');
  String lostPerMonth(String v) => _t('মাসে গড়ে $v দাম কমছে — এটাও খরচ', '$v of value lost a month — a cost too');
  String get trueCostPerKm => _t('দাম কমা সহ আসল খরচ / কিমি', 'True cost per km (with value loss)');
  String get setMarketValue => _t('বাজার দর দিন', 'Enter market value');
  String get marketValueHelp => _t('এখন বিক্রি করলে কত পেতেন — না দিলে বছরে ১০% কমে ধরা হয়', 'What it would sell for now — else 10 % a year is assumed');
  String get needPurchase => _t('কেনা দাম ও তারিখ দিলে দেখাবে গাড়ির দাম কত কমলো আর আসল খরচ কত', 'Add the purchase price and date to see value lost and the true cost');

  // ── Driver salary ────────────────────────────────────────────────────────
  String get myDriver => _t('ড্রাইভার', 'Driver');
  String get addSalariedDriver => _t('ড্রাইভার যোগ করুন', 'Add your driver');
  String get addSalariedDriverSub => _t('মাসিক বেতন, অগ্রিম, বোনাস — কত বাকি সব হিসাব থাকবে', 'Salary, advances, bonuses — always know what is owed');
  String get monthlySalary => _t('মাসিক বেতন', 'Monthly salary');
  String get openingSalaryDue => _t('আগের বকেয়া বেতন', 'Salary owed before');
  String salaryOwed(String v) => _t('বেতন বাকি $v', '$v salary owed');
  String salaryAdvance(String v) => _t('অগ্রিম নিয়েছে $v', '$v taken in advance');
  String get salaryClear => _t('কোনো বাকি নেই', 'All settled');
  String nextPayDay(String d) => _t('পরের বেতন $d', 'Next salary $d');
  String get paySalary => _t('বেতন দিন', 'Pay');
  String get salaryPayment => _t('বেতন / অগ্রিম দেওয়া', 'Pay salary / advance');
  String get kindSalary => _t('বেতন', 'Salary');
  String get kindAdvance => _t('অগ্রিম', 'Advance');
  String get kindBonus => _t('বোনাস / বকশিশ', 'Bonus / tip');
  String get bonusNote => _t('বোনাস বেতনের হিসাব থেকে কাটা হয় না', 'A bonus does not count against salary');
  String get salaryStatement => _t('বেতনের হিসাব', 'Salary statement');
  String monthSalaryLine(String paid, String salary) => _t('দেওয়া $paid · বেতন $salary', 'Paid $paid · salary $salary');
  String get runningMonth => _t('চলতি মাস', 'This month');
  String get totalPaid => _t('মোট দেওয়া', 'Total paid');
  String get totalBonus => _t('মোট বোনাস', 'Total bonuses');
  String get salaryDriverQuick => _t('ড্রাইভারের বেতন', 'Driver salary');
  String get salaryDriverQuickSub => _t('বেতন, অগ্রিম, বোনাস', 'Salary, advance, bonus');

  // ── Office claim ─────────────────────────────────────────────────────────
  String get officeUse => _t('অফিসের কাজে', 'For office work');
  String get officeUseSub => _t('মাস শেষে অফিসে জমা দেওয়ার রিপোর্টে আসবে', 'Goes into the monthly claim for your office');
  String get officeReport => _t('অফিসের খরচের রিপোর্ট', 'Office expense claim');
  String get officeReportSub => _t('অফিসের কাজের খরচ — PDF বানিয়ে জমা দিন', 'Office-work costs — make a PDF to submit');
  String officeThisMonth(String v) => _t('এই মাসে অফিসের খরচ $v', '$v of office costs this month');
  String get claimTitle => _t('গাড়ির খরচের দাবি', 'Vehicle expense claim');
  String get claimant => _t('দাবিদার', 'Claimed by');
  String get approvedBy => _t('অনুমোদনকারী', 'Approved by');
  String get claimPeriod => _t('সময়কাল', 'Period');
  String get claimVehicle => _t('গাড়ি', 'Vehicle');
  String get claimItem => _t('বিবরণ', 'Description');
  String get claimDate => _t('তারিখ', 'Date');
  String get claimAmount => _t('টাকা', 'Amount');
  String get claimTotal => _t('মোট দাবি', 'Total claimed');
  String get signature => _t('স্বাক্ষর ও তারিখ', 'Signature & date');
  String claimPage(int a, int b) => _t('পাতা ${n(a)} / ${n(b)}', 'Page $a of $b');
  String get claimMadeWith => _t('গাড়ির খাতা অ্যাপে তৈরি', 'Made with GariKhata');
  String get sharePdf => _t('PDF শেয়ার / প্রিন্ট', 'Share / print PDF');
  String get noOfficeCosts => _t('এই মাসে কোনো খরচ "অফিসের কাজে" চিহ্ন দেওয়া নেই', 'No costs marked "for office work" this month');
  String get noOfficeCostsBody => _t(
      'জ্বালানি বা অন্য খরচ লেখার সময় "অফিসের কাজে" চালু করুন — সেগুলো এখানে রিপোর্ট হয়ে আসবে।',
      'Turn on "For office work" when logging fuel or a cost — they gather here as a claim.');
  String get allCars => _t('সব গাড়ি', 'All cars');
  String get makingPdf => _t('PDF তৈরি হচ্ছে…', 'Making the PDF…');

  // ── Pumps ────────────────────────────────────────────────────────────────
  String get pumpCompare => _t('পাম্প তুলনা', 'Pump comparison');
  String get pumpCompareSub => _t('কোন পাম্পের তেলে গাড়ি কতদূর যায়', 'How far each pump\'s fuel takes you');
  String get pumpNeedData => _t(
      'প্রতিবার পাম্পের নাম লিখুন — একই পাম্প থেকে দুইবার ফুল ট্যাংক করলেই তুলনা দেখা যাবে।',
      'Note the pump each time — two full tanks from one pump and it shows up here.');
  String stretches(int c) => _t('${n(c)} বার মাপা', c == 1 ? 'measured once' : 'measured $c times');
  String pumpBelow(String pct) => _t('অন্য পাম্পের চেয়ে $pct কম', '$pct below other pumps');
  String pumpAbove(String pct) => _t('অন্য পাম্পের চেয়ে $pct বেশি', '$pct above other pumps');
  String get pumpSuspectTitle => _t('এই পাম্পে কম তেল পাচ্ছেন?', 'Short measure at this pump?');
  String pumpSuspectBody(String pump, String pct) => _t(
      '$pump থেকে নেওয়া তেলে অন্য পাম্পের চেয়ে $pct কম মাইলেজ। অন্য পাম্প চেষ্টা করুন, বা মিটার শূন্য থেকে শুরু হচ্ছে কিনা দেখুন।',
      'Fuel from $pump gives $pct less mileage than other pumps. Try another pump, or check the meter starts at zero.');
  String get pumpOnlyClean => _t('শুধু যে বার পুরো ট্যাংক একই পাম্প থেকে নিয়েছেন সেগুলো গোনা হয়েছে।', 'Only stretches filled entirely at one pump are counted.');

  String fuelReminderBody(int d) => _t('${n(d)} দিন কোনো জ্বালানি লেখা হয়নি।', 'No fuel logged for ${n(d)} days.');
}
