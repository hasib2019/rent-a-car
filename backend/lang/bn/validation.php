<?php

/*
| Bangla messages for the rules the app's API uses. Anything missing falls
| back to English (APP_FALLBACK_LOCALE).
*/

return [
    'array' => ':attribute সঠিক নয়।',
    'confirmed' => ':attribute দুইবার একই হয়নি।',
    'date' => ':attribute সঠিক তারিখ নয়।',
    'digits' => ':attribute অবশ্যই :digits সংখ্যার হতে হবে।',
    'email' => 'সঠিক :attribute দিন।',
    'integer' => ':attribute পূর্ণ সংখ্যা হতে হবে।',
    'max' => [
        'array' => ':attribute-এ সর্বোচ্চ :max টি থাকতে পারে।',
        'numeric' => ':attribute :max-এর বেশি হতে পারবে না।',
        'string' => ':attribute সর্বোচ্চ :max অক্ষরের হতে পারে।',
    ],
    'min' => [
        'array' => ':attribute-এ অন্তত :min টি থাকতে হবে।',
        'numeric' => ':attribute অন্তত :min হতে হবে।',
        'string' => ':attribute অন্তত :min অক্ষরের হতে হবে।',
    ],
    'password' => [
        'letters' => ':attribute-এ অন্তত একটি অক্ষর থাকতে হবে।',
        'mixed' => ':attribute-এ বড় ও ছোট হাতের অক্ষর থাকতে হবে।',
        'numbers' => ':attribute-এ অন্তত একটি সংখ্যা থাকতে হবে।',
        'symbols' => ':attribute-এ অন্তত একটি চিহ্ন থাকতে হবে।',
        'uncompromised' => 'এই :attribute ফাঁস হওয়া পাসওয়ার্ডের তালিকায় আছে, অন্যটি দিন।',
    ],
    'regex' => ':attribute-এর ফরম্যাট সঠিক নয়।',
    'required' => ':attribute দিতে হবে।',
    'string' => ':attribute লেখা হতে হবে।',
    'unique' => 'এই :attribute দিয়ে আগেই অ্যাকাউন্ট খোলা হয়েছে।',
    'custom' => [
        'phone' => ['regex' => 'সঠিক মোবাইল নম্বর দিন (01XXXXXXXXX)।'],
        'username' => ['regex' => 'ইউজারনেমে শুধু ছোট হাতের ইংরেজি অক্ষর, সংখ্যা, _ ও . ব্যবহার করুন।'],
    ],
    'attributes' => [],
];
