// Dragon Hub - VIP Key Validator
// Server-side key validation endpoint

export default function handler(req, res) {
    // قائمة المفاتيح الصالحة
    // كل مفتاح له مدة صلاحية بالثواني
    const VALID_KEYS = {
        "DRAGON-1HOUR":   { duration: 3600,    label: "ساعة تجريبية" },
        "DRAGON-1DAY":    { duration: 86400,   label: "يوم كامل" },
        "DRAGON-1WEEK":   { duration: 604800,  label: "أسبوع" },
        "DRAGON-1MONTH":  { duration: 2592000, label: "شهر" },
        "DRAGON-LIFETIME":{ duration: 31536000,label: "مدى الحياة" },
        "DRAGON-TEST":    { duration: 600,     label: "تجريبي 10 دقائق" },
    };

    // نستقبل المفتاح من السكريبت
    const key = req.query.key;

    // لو مفيش مفتاح مرسل
    if (!key) {
        return res.status(200).json({
            valid: false,
            message: "لم يتم إرسال مفتاح"
        });
    }

    // لو المفتاح مش موجود في القائمة
    if (!VALID_KEYS[key]) {
        return res.status(200).json({
            valid: false,
            message: "مفتاح غير صالح"
        });
    }

    // نجيب بيانات المفتاح
    const keyData = VALID_KEYS[key];
    
    // نحسب وقت الانتهاء (الوقت الحالي + المدة)
    const expireTime = Math.floor(Date.now() / 1000) + keyData.duration;

    // نرد بالنجاح
    return res.status(200).json({
        valid: true,
        expire: expireTime,
        label: keyData.label,
        remaining: keyData.duration
    });
}
