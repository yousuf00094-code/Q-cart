class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _s = {
    // Navigation
    'home':        {'en': 'Home',        'ar': 'الرئيسية'},
    'categories':  {'en': 'Categories',  'ar': 'التصنيفات'},
    'cart':        {'en': 'Cart',        'ar': 'السلة'},
    'wishlist':    {'en': 'Wishlist',    'ar': 'المفضلة'},
    'profile':     {'en': 'Profile',     'ar': 'حسابي'},

    // Home
    'search_hint':    {'en': 'Search products...', 'ar': 'ابحث عن منتجات...'},
    'see_all':        {'en': 'See all',    'ar': 'عرض الكل'},
    'best_selling':   {'en': 'Best Selling', 'ar': 'الأكثر مبيعاً'},
    'new_arrivals':   {'en': 'New Arrivals', 'ar': 'وصل حديثاً'},
    'featured':       {'en': 'Featured',     'ar': 'مميز'},
    'limited_offer':  {'en': 'Limited Offer','ar': 'عرض محدود'},
    'shop_now':       {'en': 'Shop Now',     'ar': 'تسوق الآن'},
    'promo_title':    {'en': 'Get 20% Off\nYour First Order', 'ar': 'احصل على خصم 20%\nعلى طلبك الأول'},

    // Products
    'products':           {'en': 'Products',        'ar': 'المنتجات'},
    'sort_by':            {'en': 'Sort by',          'ar': 'ترتيب حسب'},
    'filters':            {'en': 'Filters',          'ar': 'تصفية'},
    'price_range':        {'en': 'Price Range',      'ar': 'نطاق السعر'},
    'min_rating':         {'en': 'Min. Rating',      'ar': 'أقل تقييم'},
    'apply':              {'en': 'Apply',            'ar': 'تطبيق'},
    'reset':              {'en': 'Reset',            'ar': 'إعادة'},
    'in_stock':           {'en': 'In Stock',         'ar': 'متوفر'},
    'out_of_stock':       {'en': 'Out of Stock',     'ar': 'نفد المخزون'},
    'add_to_cart':        {'en': 'Add to Cart',      'ar': 'أضف للسلة'},
    'buy_now':            {'en': 'Buy Now',          'ar': 'اشتر الآن'},
    'description':        {'en': 'Description',      'ar': 'الوصف'},
    'specifications':     {'en': 'Specifications',   'ar': 'المواصفات'},
    'reviews':            {'en': 'Reviews',          'ar': 'التقييمات'},
    'write_review':       {'en': 'Write a Review',   'ar': 'اكتب تقييماً'},
    'no_reviews':         {'en': 'No reviews yet',   'ar': 'لا توجد تقييمات بعد'},
    'related_products':   {'en': 'Related Products', 'ar': 'منتجات مشابهة'},
    'sold_by':            {'en': 'Sold by',          'ar': 'يباع بواسطة'},
    'no_products':        {'en': 'No products found','ar': 'لا توجد منتجات'},

    // Sort options
    'newest':         {'en': 'Newest First',     'ar': 'الأحدث أولاً'},
    'price_asc':      {'en': 'Price: Low to High','ar': 'السعر: من الأقل'},
    'price_desc':     {'en': 'Price: High to Low','ar': 'السعر: من الأعلى'},
    'top_rated':      {'en': 'Top Rated',         'ar': 'الأعلى تقييماً'},
    'best_seller':    {'en': 'Best Seller',        'ar': 'الأكثر مبيعاً'},

    // Cart
    'my_cart':          {'en': 'My Cart',          'ar': 'سلتي'},
    'items':            {'en': 'items',            'ar': 'منتجات'},
    'item':             {'en': 'item',             'ar': 'منتج'},
    'clear_all':        {'en': 'Clear All',        'ar': 'مسح الكل'},
    'empty_cart':       {'en': 'Your cart is empty','ar': 'سلتك فارغة'},
    'start_shopping':   {'en': 'Start Shopping',   'ar': 'ابدأ التسوق'},
    'order_summary':    {'en': 'Order Summary',    'ar': 'ملخص الطلب'},
    'subtotal':         {'en': 'Subtotal',         'ar': 'المجموع الفرعي'},
    'delivery':         {'en': 'Delivery',         'ar': 'التوصيل'},
    'discount':         {'en': 'Discount',         'ar': 'الخصم'},
    'total':            {'en': 'Total',            'ar': 'الإجمالي'},
    'free':             {'en': 'Free',             'ar': 'مجاني'},
    'checkout':         {'en': 'Proceed to Checkout','ar': 'إتمام الشراء'},
    'coupon_code':      {'en': 'Coupon Code',      'ar': 'رمز الخصم'},
    'apply_coupon':     {'en': 'Apply',            'ar': 'تطبيق'},
    'invalid_coupon':   {'en': 'Invalid coupon code','ar': 'رمز خصم غير صحيح'},
    'free_delivery_hint':{'en': 'more for free delivery','ar': 'للحصول على توصيل مجاني'},

    // Wishlist
    'my_wishlist':       {'en': 'My Wishlist',     'ar': 'مفضلتي'},
    'empty_wishlist':    {'en': 'Your wishlist is empty','ar': 'قائمة مفضلتك فارغة'},
    'move_to_cart':      {'en': 'Move to Cart',    'ar': 'نقل إلى السلة'},
    'remove':            {'en': 'Remove',          'ar': 'إزالة'},

    // Checkout
    'delivery_address':  {'en': 'Delivery Address', 'ar': 'عنوان التسليم'},
    'payment_method':    {'en': 'Payment Method',   'ar': 'طريقة الدفع'},
    'add_new_address':   {'en': 'Add New Address',  'ar': 'إضافة عنوان جديد'},
    'place_order':       {'en': 'Place Order',      'ar': 'تأكيد الطلب'},
    'cash_on_delivery':  {'en': 'Cash on Delivery', 'ar': 'الدفع عند الاستلام'},
    'credit_card':       {'en': 'Credit / Debit Card','ar': 'بطاقة ائتمانية'},
    'default_label':     {'en': 'Default',          'ar': 'افتراضي'},
    'no_addresses':      {'en': 'No saved addresses','ar': 'لا توجد عناوين محفوظة'},

    // Order confirmation
    'order_placed':         {'en': 'Order Placed!',       'ar': 'تم تقديم الطلب!'},
    'order_placed_msg':     {'en': 'Your order has been placed successfully.', 'ar': 'تم تقديم طلبك بنجاح.'},
    'estimated_delivery':   {'en': 'Estimated delivery: 1-3 business days', 'ar': 'وقت التوصيل المتوقع: 1-3 أيام عمل'},
    'track_order':          {'en': 'Track Order',        'ar': 'تتبع الطلب'},
    'continue_shopping':    {'en': 'Continue Shopping',  'ar': 'متابعة التسوق'},

    // Orders
    'my_orders':     {'en': 'My Orders',    'ar': 'طلباتي'},
    'active':        {'en': 'Active',       'ar': 'نشطة'},
    'history':       {'en': 'History',      'ar': 'السابقة'},
    'reorder':       {'en': 'Reorder',      'ar': 'إعادة الطلب'},
    'track':         {'en': 'Track',        'ar': 'تتبع'},
    'cancel_order':  {'en': 'Cancel',       'ar': 'إلغاء'},
    'no_orders':     {'en': 'No orders yet','ar': 'لا توجد طلبات بعد'},
    'order_detail':  {'en': 'Order Details','ar': 'تفاصيل الطلب'},
    'order_tracking':{'en': 'Order Tracking','ar': 'تتبع الطلب'},
    'order_placed_step': {'en': 'Order Placed',    'ar': 'تم الطلب'},
    'processing_step':   {'en': 'Processing',       'ar': 'جاري التجهيز'},
    'out_for_delivery_step': {'en': 'Out for Delivery', 'ar': 'في الطريق إليك'},
    'delivered_step':    {'en': 'Delivered',        'ar': 'تم التسليم'},

    // Status labels
    'pending':          {'en': 'Pending',          'ar': 'قيد الانتظار'},
    'confirmed':        {'en': 'Confirmed',         'ar': 'مؤكد'},
    'processing':       {'en': 'Processing',        'ar': 'جاري التجهيز'},
    'out_for_delivery': {'en': 'Out for Delivery',  'ar': 'في الطريق'},
    'delivered':        {'en': 'Delivered',         'ar': 'تم التسليم'},
    'cancelled':        {'en': 'Cancelled',         'ar': 'ملغي'},

    // Profile
    'personal_info':    {'en': 'Personal Information', 'ar': 'المعلومات الشخصية'},
    'my_addresses':     {'en': 'My Addresses',         'ar': 'عناوين التسليم'},
    'language':         {'en': 'Language',             'ar': 'اللغة'},
    'english':          {'en': 'English',              'ar': 'الإنجليزية'},
    'arabic':           {'en': 'العربية',              'ar': 'العربية'},
    'notifications':    {'en': 'Notifications',        'ar': 'الإشعارات'},
    'help_support':     {'en': 'Help & Support',       'ar': 'المساعدة والدعم'},
    'about':            {'en': 'About Q Cart',         'ar': 'عن كيو كارت'},
    'logout':           {'en': 'Log Out',              'ar': 'تسجيل الخروج'},
    'account':          {'en': 'Account',              'ar': 'الحساب'},
    'orders_label':     {'en': 'Orders',               'ar': 'الطلبات'},
    'settings':         {'en': 'Settings',             'ar': 'الإعدادات'},
    'member_since':     {'en': 'Member since',         'ar': 'عضو منذ'},
    'loyalty_points':   {'en': 'Points',               'ar': 'نقاط'},

    // Auth
    'welcome_back':     {'en': 'Welcome back!',        'ar': 'مرحباً بعودتك!'},
    'sign_in_to_continue': {'en': 'Sign in to continue shopping', 'ar': 'تسجيل الدخول للمتابعة'},
    'email':            {'en': 'Email Address',        'ar': 'البريد الإلكتروني'},
    'password':         {'en': 'Password',             'ar': 'كلمة المرور'},
    'remember_me':      {'en': 'Remember me',          'ar': 'تذكرني'},
    'forgot_password':  {'en': 'Forgot password?',     'ar': 'نسيت كلمة المرور؟'},
    'login':            {'en': 'Login',                'ar': 'تسجيل الدخول'},
    'no_account':       {'en': "Don't have an account? ", 'ar': 'ليس لديك حساب؟ '},
    'register':         {'en': 'Register',             'ar': 'إنشاء حساب'},
    'create_account':   {'en': 'Create Account',       'ar': 'إنشاء حساب'},
    'full_name':        {'en': 'Full Name',            'ar': 'الاسم الكامل'},
    'phone':            {'en': 'Phone Number',         'ar': 'رقم الهاتف'},
    'confirm_password': {'en': 'Confirm Password',     'ar': 'تأكيد كلمة المرور'},
    'already_account':  {'en': 'Already have an account? ', 'ar': 'لديك حساب بالفعل؟ '},
    'sign_in':          {'en': 'Sign in',              'ar': 'تسجيل الدخول'},
    'agree_terms':      {'en': 'I agree to the Terms & Privacy Policy', 'ar': 'أوافق على الشروط وسياسة الخصوصية'},
    'or_continue_with': {'en': 'or continue with',    'ar': 'أو المتابعة عبر'},

    // General
    'retry':          {'en': 'Retry',          'ar': 'إعادة المحاولة'},
    'loading':        {'en': 'Loading...',     'ar': 'جاري التحميل...'},
    'error_generic':  {'en': 'Something went wrong. Please try again.', 'ar': 'حدث خطأ ما. حاول مرة أخرى.'},
    'qar':            {'en': 'QAR',            'ar': 'ر.ق'},
    'cancel':         {'en': 'Cancel',         'ar': 'إلغاء'},
    'confirm':        {'en': 'Confirm',        'ar': 'تأكيد'},
    'save':           {'en': 'Save',           'ar': 'حفظ'},
    'edit':           {'en': 'Edit',           'ar': 'تعديل'},
    'delete':         {'en': 'Delete',         'ar': 'حذف'},
    'back':           {'en': 'Back',           'ar': 'رجوع'},
    'done':           {'en': 'Done',           'ar': 'تم'},
    'search':         {'en': 'Search',         'ar': 'بحث'},
  };

  static String t(String key, String langCode) =>
      _s[key]?[langCode] ?? _s[key]?['en'] ?? key;
}
