import React, { useState } from 'react';
import { AdminModal } from '../components/AdminModal';
import { INITIAL_PRODUCTS } from '../data/products';
import { INITIAL_CATEGORIES } from '../data/categories';
import { INITIAL_BANNERS } from '../data/banners';
import { INITIAL_TREND_CAMPAIGNS } from '../data/trends';
import { initialPricingSettings } from '../utils/pricing';
import { Toast } from '../components/Toast';
import type { Product, Category, Banner, TrendCampaign, PricingSettings } from '../types';
import { ShieldCheck, ExternalLink, RefreshCw } from 'lucide-react';

export default function AdminApp() {
  const [isAdminOpen, setIsAdminOpen] = useState(true);
  const [products, setProducts] = useState<Product[]>(INITIAL_PRODUCTS);
  const [categories, setCategories] = useState<Category[]>(INITIAL_CATEGORIES);
  const [banners, setBanners] = useState<Banner[]>(INITIAL_BANNERS);
  const [trendCampaigns, setTrendCampaigns] = useState<TrendCampaign[]>(INITIAL_TREND_CAMPAIGNS);
  const [trendHashtags, setTrendHashtags] = useState<string[]>(['#أناقة_للجميع', '#عروض_الصيف']);
  const [pricingSettings, setPricingSettings] = useState<PricingSettings>(initialPricingSettings);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);

  const showToast = (message: string, type: 'success' | 'error' | 'info' = 'info') => {
    setToast({ message, type });
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-['Cairo',sans-serif]" dir="rtl">
      {/* Header Bar */}
      <header className="px-6 py-4 bg-slate-900 border-b border-slate-800 flex items-center justify-between shadow-md">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-amber-400 text-slate-950 flex items-center justify-center font-black shadow-md">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-base font-black text-white">تطبيق لوحة تحكم الإدارة المستقل</h1>
            <p className="text-xs text-slate-400">إدارة المنتجات، الطلبات، البانرات، الكوبونات والتسعير</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setIsAdminOpen(true)}
            className="px-4 py-2 bg-amber-400 hover:bg-amber-300 text-slate-950 text-xs font-black rounded-xl transition-all shadow-sm flex items-center gap-1.5 cursor-pointer"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span>فتح لوحة التحكم الكاملة</span>
          </button>
          <a
            href="/"
            target="_blank"
            rel="noreferrer"
            className="px-3 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-bold rounded-xl transition-all flex items-center gap-1.5 cursor-pointer"
          >
            <ExternalLink className="w-3.5 h-3.5" />
            <span>معاينة تطبيق العميل</span>
          </a>
        </div>
      </header>

      {/* Main Admin Content Canvas */}
      <main className="flex-1 p-6 max-w-6xl w-full mx-auto flex flex-col items-center justify-center">
        {!isAdminOpen ? (
          <div className="bg-slate-900 border border-slate-800 p-8 rounded-3xl text-center max-w-md w-full shadow-2xl space-y-4">
            <div className="w-16 h-16 rounded-2xl bg-amber-400/20 text-amber-400 flex items-center justify-center mx-auto">
              <ShieldCheck className="w-8 h-8" />
            </div>
            <h2 className="text-lg font-black text-white">لوحة تحكم المشرف والمدير</h2>
            <p className="text-xs text-slate-400">انقر على الزر أدناه لإعادة فتح نافذة الإدارة والتحكم الكاملة.</p>
            <button
              onClick={() => setIsAdminOpen(true)}
              className="w-full py-3.5 bg-amber-400 hover:bg-amber-300 text-slate-950 font-black rounded-2xl transition-all shadow-md cursor-pointer"
            >
              فتح لوحة التحكم
            </button>
          </div>
        ) : (
          <AdminModal
            isOpen={isAdminOpen}
            onClose={() => setIsAdminOpen(false)}
            onShowToast={showToast}
            products={products}
            onAddProduct={(newProd) => {
              setProducts((prev) => [newProd, ...prev]);
              showToast(`تمت إضافة "${newProd.name}" بنجاح ✨`, 'success');
            }}
            onUpdateProduct={(updated) => {
              setProducts((prev) => prev.map((p) => (p.id === updated.id ? updated : p)));
              showToast(`تم تحديث "${updated.name}" بنجاح ✨`, 'success');
            }}
            onDeleteProduct={(prodId) => {
              setProducts((prev) => prev.filter((p) => p.id !== prodId));
              showToast('تم حذف الصنف بنجاح', 'info');
            }}
            categories={categories}
            onAddCategory={(cat) => setCategories((prev) => [...prev, cat])}
            onUpdateCategory={(cat) => setCategories((prev) => prev.map((c) => (c.id === cat.id ? cat : c)))}
            onDeleteCategory={(catId) => setCategories((prev) => prev.filter((c) => c.id !== catId))}
            banners={banners}
            onAddBanner={(ban) => setBanners((prev) => [...prev, ban])}
            onUpdateBanner={(ban) => setBanners((prev) => prev.map((b) => (b.id === ban.id ? ban : b)))}
            onDeleteBanner={(banId) => setBanners((prev) => prev.filter((b) => b.id !== banId))}
            pricingSettings={pricingSettings}
            onSavePricingSettings={(settings) => {
              setPricingSettings(settings);
              showToast('تم حفظ إعدادات التسعير والعملات بنجاح', 'success');
            }}
          />
        )}
      </main>

      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  );
}
