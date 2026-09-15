import React from 'react';
import { Search, Heart, ShoppingBag, ShieldCheck, User, Smartphone } from 'lucide-react';
import type { User as UserType } from '../types';

interface HeaderProps {
  cartCount: number;
  wishlistCount: number;
  currency: 'YER' | 'SAR';
  user: UserType | null;
  onOpenSearch: () => void;
  onOpenCart: () => void;
  onOpenWishlist: () => void;
  onOpenAdmin: () => void;
  onOpenAuth: () => void;
  onToggleCurrency: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  cartCount,
  wishlistCount,
  currency,
  user,
  onOpenSearch,
  onOpenCart,
  onOpenWishlist,
  onOpenAdmin,
  onOpenAuth,
  onToggleCurrency,
}) => {
  return (
    <header className="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-slate-100 shadow-xs">
      <div className="max-w-7xl mx-auto px-3.5 py-2.5 flex items-center justify-between gap-2 sm:gap-4">
        {/* Brand Logo & Name */}
        <div className="flex items-center gap-2 cursor-pointer" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-purple-700 via-purple-600 to-indigo-600 flex items-center justify-center text-white font-black text-lg shadow-sm shadow-purple-500/20">
            <span className="text-[#F0A717] ml-0.5">ص</span>
          </div>
          <div className="flex flex-col">
            <div className="flex items-center gap-1 leading-tight">
              <span className="text-slate-900 font-extrabold text-base tracking-tight">التخفيض</span>
              <span className="text-[#F0A717] font-black text-base">الصح</span>
            </div>
            <span className="text-[10px] text-slate-400 font-semibold tracking-wider">FASHION & DEALS</span>
          </div>
        </div>

        {/* Quick Search Bar Trigger */}
        <button
          onClick={onOpenSearch}
          className="flex-1 max-w-md hidden sm:flex items-center gap-2 bg-slate-100/80 hover:bg-slate-100 text-slate-400 px-3.5 py-2 rounded-full text-xs font-medium transition-all border border-slate-200/50"
        >
          <Search className="w-4 h-4 text-slate-400" />
          <span>ابحث عن فساتين، أحذية، ملابس كاجوال، أو عروض...</span>
        </button>

        {/* Action Buttons */}
        <div className="flex items-center gap-1 sm:gap-2">
          {/* Mobile Search Icon */}
          <button
            onClick={onOpenSearch}
            className="sm:hidden p-2 rounded-full text-slate-600 hover:bg-slate-100 active:scale-95 transition-all"
            aria-label="بحث"
          >
            <Search className="w-5 h-5" />
          </button>

          {/* Download APK Button */}
          <a
            href="/downloads/altakhfeed-alsh.apk"
            download="altakhfeed-alsh.apk"
            className="hidden sm:flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-200/80 text-xs font-bold transition-all active:scale-95"
            title="تنزيل تطبيق أندرويد APK"
          >
            <Smartphone className="w-3.5 h-3.5 text-emerald-600" />
            <span className="text-[11px]">تحميل التطبيق (APK)</span>
          </a>

          {/* Currency Switcher */}
          <button
            onClick={onToggleCurrency}
            className="text-[11px] font-bold px-2 py-1 rounded-lg bg-purple-50 hover:bg-purple-100 text-purple-700 border border-purple-200/60 transition-all active:scale-95"
            title="تبديل العملة"
          >
            {currency === 'YER' ? 'ريال يمني' : 'ريال سعودي'}
          </button>

          {/* Wishlist Button */}
          <button
            onClick={onOpenWishlist}
            className="relative p-2 rounded-full text-slate-700 hover:bg-slate-100 active:scale-95 transition-all"
            aria-label="المفضلة"
          >
            <Heart className="w-5 h-5" />
            {wishlistCount > 0 && (
              <span className="absolute top-1 right-1 w-4 h-4 bg-rose-500 text-white text-[9px] font-bold rounded-full flex items-center justify-center">
                {wishlistCount}
              </span>
            )}
          </button>

          {/* Cart Button */}
          <button
            onClick={onOpenCart}
            className="relative p-2 rounded-full text-slate-700 hover:bg-slate-100 active:scale-95 transition-all"
            aria-label="سلة التسوق"
          >
            <ShoppingBag className="w-5 h-5 text-purple-700" />
            {cartCount > 0 && (
              <span className="absolute top-1 right-1 w-4 h-4 bg-purple-700 text-white text-[9px] font-bold rounded-full flex items-center justify-center animate-pulse-subtle">
                {cartCount}
              </span>
            )}
          </button>

          {/* Admin Quick Entry Button if user is Admin */}
          {(user?.isAdmin || user?.role === 'admin') && (
            <button
              onClick={onOpenAdmin}
              className="flex items-center gap-1.5 bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-600 hover:to-amber-700 text-slate-950 font-black px-2.5 py-1.5 rounded-xl text-xs shadow-xs transition-all active:scale-95 cursor-pointer"
              title="فتح لوحة التحكم"
            >
              <ShieldCheck className="w-4 h-4 text-slate-950" />
              <span className="text-[11px] font-black">لوحة الإدارة</span>
            </button>
          )}

          {/* User Account / Profile Button */}
          <button
            onClick={onOpenAuth}
            className="p-2 rounded-full text-slate-700 hover:bg-slate-100 active:scale-95 transition-all relative"
            aria-label="الحساب"
            title={user ? `${user.firstName || 'المستخدم'}` : 'تسجيل الدخول'}
          >
            <User className="w-5 h-5" />
            {user && (
              <span className="absolute bottom-1 right-1 w-2 h-2 bg-emerald-500 rounded-full border border-white" />
            )}
          </button>
        </div>
      </div>
    </header>
  );
};
