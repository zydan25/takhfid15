import React, { useState, useEffect } from 'react';
import { X, User, Phone, MapPin, ShieldCheck, ArrowRight, LogOut, CheckCircle2, RefreshCw, KeyRound, MessageSquare } from 'lucide-react';
import type { User as UserType } from '../types';
import { ALL_GOVERNORATES } from '../data/governorates';
import { sendWhatsAppOtp, verifyWhatsAppOtp } from '../auth';
import { normalizePhone } from '../api';

interface AuthModalProps {
  isOpen: boolean;
  user: UserType | null;
  onClose: () => void;
  onOpenAdmin?: () => void;
  onLogin: (user: UserType) => void;
  onLogout: () => void;
  onShowToast: (msg: string, type?: 'success' | 'info' | 'error') => void;
}

export const AuthModal: React.FC<AuthModalProps> = ({
  isOpen,
  user,
  onClose,
  onOpenAdmin,
  onLogin,
  onLogout,
  onShowToast,
}) => {
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [firstName, setFirstName] = useState('');
  const [secondName, setSecondName] = useState('');
  const [thirdName, setThirdName] = useState('');
  const [lastName, setLastName] = useState('');
  const [governorate, setGovernorate] = useState('أمانة العاصمة');
  const [step, setStep] = useState<'phone' | 'otp'>('phone');
  const [busy, setBusy] = useState(false);
  const [cooldown, setCooldown] = useState(0);

  useEffect(() => {
    if (cooldown <= 0) return;
    const timer = window.setInterval(() => setCooldown((v) => Math.max(0, v - 1)), 1000);
    return () => window.clearInterval(timer);
  }, [cooldown]);

  useEffect(() => {
    if (!isOpen) {
      setStep('phone');
      setOtp('');
      setCooldown(0);
      setBusy(false);
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleRequestOtp = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const clean = normalizePhone(phone);
    if (!/^\d{8,15}$/.test(clean)) {
      onShowToast('رقم الهاتف غير صالح. يرجى إدخال رقم هاتف صحيح (مثال: 771234567)', 'error');
      return;
    }

    setBusy(true);
    try {
      const result = await sendWhatsAppOtp({ phoneNumber: clean });
      setPhone(clean);
      setStep('otp');
      setCooldown(result.data.retryAfterSeconds || 60);
      onShowToast('تم إرسال كود التحقق عبر واتساب بنجاح 📲', 'success');
    } catch (err: any) {
      console.error('sendOtp error:', err);
      onShowToast(err?.message || 'تعذر إرسال رمز التحقق. يرجى المحاولة مرة أخرى', 'error');
    } finally {
      setBusy(false);
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!/^\d{6}$/.test(otp.trim())) {
      onShowToast('كود التحقق يجب أن يتكون من 6 أرقام', 'error');
      return;
    }

    setBusy(true);
    try {
      const clean = normalizePhone(phone);
      const result = await verifyWhatsAppOtp({
        phoneNumber: clean,
        otp: otp.trim(),
        firstName: firstName.trim() || 'عميل',
        secondName: secondName.trim() || undefined,
        thirdName: thirdName.trim() || undefined,
        lastName: lastName.trim() || undefined,
        governorate: governorate || 'أمانة العاصمة',
      });

      const loggedUser = result.data.user as UserType;
      try {
        localStorage.setItem('user_profile', JSON.stringify(loggedUser));
      } catch {
        // ignore
      }

      onLogin(loggedUser);
      onClose();

      if (loggedUser.isAdmin || loggedUser.role === 'admin') {
        onShowToast('مرحباً بك يا مدير النظام! تم تسجيل الدخول بصلاحيات الإدارة 👑', 'success');
      } else {
        onShowToast(`أهلاً بك يا ${loggedUser.firstName || 'مستخدم'}! تم تسجيل الدخول بنجاح ✨`, 'success');
      }
    } catch (err: any) {
      console.error('verifyOtp error:', err);
      onShowToast(err?.message || 'كود التحقق غير صحيح أو منتهي الصلاحية', 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div
      id="auth-modal-overlay"
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs animate-fadeIn"
      onClick={onClose}
    >
      <div
        id="auth-modal-card"
        className="bg-white w-full max-w-md rounded-3xl shadow-2xl overflow-hidden text-right"
        dir="rtl"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 bg-slate-950 text-white">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center">
              <User className="w-4 h-4 text-amber-300" />
            </div>
            <div>
              <h3 className="font-extrabold text-sm sm:text-base">
                {user ? 'الملف الشخصي' : 'تسجيل الدخول برقم الهاتف'}
              </h3>
              <p className="text-[10px] text-slate-300">متجر التخفيض الصح</p>
            </div>
          </div>
          <button
            id="auth-modal-close-btn"
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-full hover:bg-white/10 transition-colors text-slate-300 hover:text-white cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6">
          {user ? (
            /* Logged in state */
            <div className="space-y-4">
              <div className="flex items-center gap-3.5 bg-slate-50 p-4 rounded-2xl border border-slate-200">
                <div className="w-12 h-12 rounded-full bg-slate-950 text-white flex items-center justify-center font-black text-lg shrink-0">
                  {user.firstName?.[0] || 'ت'}
                </div>
                <div className="min-w-0 flex-1">
                  <h4 className="font-bold text-slate-900 text-sm truncate">
                    {user.firstName} {user.secondName || ''} {user.lastName || ''}
                  </h4>
                  <span className="text-xs text-slate-500 font-mono block mt-0.5" dir="ltr">
                    {user.phone}
                  </span>
                  {user.governorate && (
                    <span className="text-[11px] text-slate-600 block mt-0.5">
                      📍 {user.governorate}
                    </span>
                  )}
                  {(user.isAdmin || user.role === 'admin') && (
                    <div className="inline-flex items-center gap-1 text-[11px] text-amber-700 bg-amber-50 px-2 py-0.5 rounded-md mt-1.5 font-bold border border-amber-200">
                      <ShieldCheck className="w-3.5 h-3.5" /> مدير النظام
                    </div>
                  )}
                </div>
              </div>

              {(user.isAdmin || user.role === 'admin') && onOpenAdmin && (
                <button
                  id="auth-open-admin-btn"
                  type="button"
                  onClick={() => {
                    onClose();
                    onOpenAdmin();
                  }}
                  className="w-full py-3 rounded-2xl bg-gradient-to-r from-purple-700 via-purple-800 to-indigo-800 hover:from-purple-850 hover:to-indigo-850 text-white text-xs font-black flex items-center justify-center gap-2 shadow-md hover:shadow-lg transition-all cursor-pointer"
                >
                  <ShieldCheck className="w-4 h-4 text-amber-400" />
                  <span>الدخول إلى لوحة التحكم والإدارة 👑</span>
                </button>
              )}

              <button
                id="auth-logout-btn"
                type="button"
                onClick={onLogout}
                className="w-full py-3 rounded-2xl border border-rose-200 bg-rose-50/50 hover:bg-rose-100/50 text-rose-700 text-xs font-bold flex items-center justify-center gap-2 cursor-pointer transition-colors"
              >
                <LogOut className="w-4 h-4" />
                تسجيل الخروج من الحساب
              </button>
            </div>
          ) : step === 'phone' ? (
            /* Step 1: Phone input */
            <form onSubmit={handleRequestOtp} className="space-y-4">
              <div className="text-center pb-2">
                <div className="w-12 h-12 rounded-2xl bg-amber-50 border border-amber-200 text-amber-600 flex items-center justify-center mx-auto mb-2.5">
                  <MessageSquare className="w-6 h-6 stroke-[2]" />
                </div>
                <h4 className="text-base font-black text-slate-900">أدخل رقم الهاتف</h4>
                <p className="text-xs text-slate-500 mt-1 leading-relaxed max-w-xs mx-auto">
                  سيصلك كود تحقق مكوّن من 6 أرقام عبر واتساب لتأكيد تسجيل الدخول فوراً
                </p>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5">
                  رقم الهاتف (واتساب)
                </label>
                <div className="relative">
                  <div className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400">
                    <Phone className="w-4 h-4" />
                  </div>
                  <input
                    id="auth-phone-input"
                    type="tel"
                    dir="ltr"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="77XXXXXXX"
                    className="w-full h-12 bg-slate-50 rounded-xl pr-10 pl-4 text-sm font-semibold border border-slate-200 focus:bg-white focus:border-slate-950 focus:ring-1 focus:ring-slate-950 outline-hidden transition-all text-left font-mono"
                    autoFocus
                    required
                  />
                </div>
                <span className="text-[10px] text-slate-400 mt-1 block">
                  مثال: 771234567 أو 782996982
                </span>
              </div>

              <button
                id="auth-send-otp-btn"
                type="submit"
                disabled={busy || !phone.trim()}
                className="w-full h-12 rounded-2xl bg-slate-950 hover:bg-black disabled:opacity-50 text-white font-bold text-sm flex items-center justify-center gap-2 shadow-md hover:shadow-lg transition-all cursor-pointer active:scale-98"
              >
                {busy ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    <span>جاري إرسال الكود...</span>
                  </>
                ) : (
                  <>
                    <span>إرسال كود التحقق عبر واتساب</span>
                    <ArrowRight className="w-4 h-4 rotate-180" />
                  </>
                )}
              </button>
            </form>
          ) : (
            /* Step 2: OTP verification */
            <form onSubmit={handleVerifyOtp} className="space-y-4">
              <div className="text-center pb-1">
                <div className="w-12 h-12 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-600 flex items-center justify-center mx-auto mb-2">
                  <KeyRound className="w-6 h-6 stroke-[2]" />
                </div>
                <h4 className="text-base font-black text-slate-900">أدخل كود التحقق</h4>
                <p className="text-xs text-slate-500 mt-1">
                  تم إرسال الكود المكون من 6 أرقام إلى الرقم:
                </p>
                <div className="inline-flex items-center gap-2 mt-1 px-3 py-1 bg-slate-100 rounded-full text-xs font-mono font-bold text-slate-800" dir="ltr">
                  <span>{phone}</span>
                  <button
                    type="button"
                    onClick={() => setStep('phone')}
                    className="text-indigo-600 hover:text-indigo-800 text-[11px] underline cursor-pointer font-sans"
                  >
                    تعديل
                  </button>
                </div>
              </div>

              {/* OTP Input */}
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1.5 text-center">
                  كود التحقق (6 أرقام)
                </label>
                <input
                  id="auth-otp-input"
                  type="text"
                  inputMode="numeric"
                  maxLength={6}
                  autoComplete="one-time-code"
                  dir="ltr"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  placeholder="------"
                  className="w-full h-14 text-center tracking-[0.4em] text-2xl font-black rounded-2xl border-2 border-slate-300 focus:border-slate-950 focus:bg-slate-50 outline-hidden font-mono transition-all"
                  autoFocus
                  required
                />
              </div>

              {/* Optional Profile Info if new */}
              <div className="pt-2 border-t border-slate-100 space-y-2.5">
                <span className="text-[11px] font-bold text-slate-600 block">
                  بيانات العميل (اختياري / للتوصيل):
                </span>
                <div className="grid grid-cols-2 gap-2">
                  <input
                    id="auth-firstname-input"
                    type="text"
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    placeholder="الاسم الأول"
                    className="h-10 bg-slate-50 rounded-xl px-3 text-xs font-semibold border border-slate-200 focus:bg-white focus:border-slate-950 outline-hidden"
                  />
                  <input
                    id="auth-lastname-input"
                    type="text"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    placeholder="اللقب / العائلة"
                    className="h-10 bg-slate-50 rounded-xl px-3 text-xs font-semibold border border-slate-200 focus:bg-white focus:border-slate-950 outline-hidden"
                  />
                </div>

                <div className="relative">
                  <div className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none">
                    <MapPin className="w-3.5 h-3.5" />
                  </div>
                  <select
                    id="auth-gov-select"
                    value={governorate}
                    onChange={(e) => setGovernorate(e.target.value)}
                    className="w-full h-10 bg-slate-50 rounded-xl pr-8 pl-3 text-xs font-semibold border border-slate-200 focus:bg-white focus:border-slate-950 outline-hidden"
                  >
                    {ALL_GOVERNORATES.map((gov) => (
                      <option key={gov} value={gov}>
                        {gov}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Submit verify */}
              <button
                id="auth-verify-submit-btn"
                type="submit"
                disabled={busy || otp.trim().length !== 6}
                className="w-full h-12 rounded-2xl bg-slate-950 hover:bg-black disabled:opacity-50 text-white font-bold text-sm flex items-center justify-center gap-2 shadow-md hover:shadow-lg transition-all cursor-pointer active:scale-98"
              >
                {busy ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    <span>جاري التحقق...</span>
                  </>
                ) : (
                  <>
                    <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                    <span>تأكيد وتسجيل الدخول</span>
                  </>
                )}
              </button>

              {/* Resend button with cooldown */}
              <button
                id="auth-resend-btn"
                type="button"
                disabled={cooldown > 0 || busy}
                onClick={handleRequestOtp}
                className="w-full py-2.5 rounded-xl border border-slate-200 text-xs font-bold text-slate-600 hover:bg-slate-50 disabled:opacity-50 flex items-center justify-center gap-2 cursor-pointer transition-colors"
              >
                <RefreshCw className={`w-3.5 h-3.5 ${busy ? 'animate-spin' : ''}`} />
                {cooldown > 0 ? `إعادة الإرسال بعد ${cooldown} ثانية` : 'لم يصلك الرمز؟ إعادة إرسال كود التحقق'}
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};
