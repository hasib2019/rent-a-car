<?php

/*
| App capabilities that packages can grant. The keys must match
| lib/services/access.dart in the Flutter app. Seeded by FeatureSeeder.
*/

return [
    ['key' => 'daily_collection', 'name' => 'Daily collection', 'name_bn' => 'দৈনিক জমা', 'group' => 'core', 'description' => "Record every vehicle's daily hand-over and off days."],
    ['key' => 'driver_dues', 'name' => 'Driver dues', 'name_bn' => 'ড্রাইভারের বাকি আদায়', 'group' => 'core', 'description' => 'Track shortfalls and collect old dues from drivers.'],
    ['key' => 'fuel_expense', 'name' => 'Fuel & expenses', 'name_bn' => 'জ্বালানি ও খরচ', 'group' => 'core', 'description' => 'Fuel, repairs and other vehicle costs.'],
    ['key' => 'trips', 'name' => 'Trips & hires', 'name_bn' => 'ট্রিপ / ভাড়া', 'group' => 'business', 'description' => 'Rent-a-car trips with clients, advances and balances.'],
    ['key' => 'parties', 'name' => 'Parties / clients', 'name_bn' => 'পার্টি / ক্লায়েন্ট', 'group' => 'business', 'description' => 'Client ledgers and collections.'],
    ['key' => 'service_visits', 'name' => 'Garage visits', 'name_bn' => 'গ্যারেজ / সার্ভিসিং', 'group' => 'maintenance', 'description' => 'Servicing visits with parts and labour.'],
    ['key' => 'parts_tracking', 'name' => 'Parts tracking', 'name_bn' => 'পার্টস ট্র্যাকিং', 'group' => 'maintenance', 'description' => 'Oil, filters, tyres — when they are due again.'],
    ['key' => 'papers', 'name' => 'Paper reminders', 'name_bn' => 'কাগজের মেয়াদ', 'group' => 'maintenance', 'description' => 'Tax token, fitness, route permit and insurance expiry alerts.'],
    ['key' => 'reports', 'name' => 'Reports', 'name_bn' => 'রিপোর্ট', 'group' => 'insights', 'description' => 'Profit per vehicle, trends and breakdowns.'],
    ['key' => 'backup_drive', 'name' => 'Google Drive backup', 'name_bn' => 'গুগল ড্রাইভ ব্যাকআপ', 'group' => 'data', 'description' => 'Back up and restore through Google Drive.'],
    ['key' => 'backup_file', 'name' => 'File export / import', 'name_bn' => 'ফাইল এক্সপোর্ট / ইমপোর্ট', 'group' => 'data', 'description' => 'Save or restore the database as a file.'],
];
