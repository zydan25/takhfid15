import React, { useState, useEffect } from 'react';
import type { Product, Category, Banner, TrendCampaign, CartItem, Order, User, PricingSettings, StoreSettings } from './types';
import { initialStoreSettings } from './types';
import { INITIAL_CATEGORIES } from './data/categories';
import { INITIAL_PRODUCTS } from './data/products';
import { INITIAL_BANNERS } from './data/banners';
import { INITIAL_TREND_CAMPAIGNS, INITIAL_TREND_HASHTAGS } from './data/trends';
import {
  fetchProductsApi,
  fetchContentApi,
  fetchPricingSettingsApi,
  fetchStoreSettingsApi,
  fetchOrdersApi,
  autoMigrateDataToServer,
} from './api';
import { initialPricingSettings } from './utils/pricing';
import { Header } from './components/Header';
import { BottomNavigation } from './components/BottomNavigation';
import { ProductCard } from './components/ProductCard';
import { ProductDetailsModal } from './components/ProductDetailsModal';
import { CartModal } from './components/CartModal';
import { WishlistModal } from './components/WishlistModal';
import { TrendsView } from './components/TrendsView';
import { CategoryModal } from './components/CategoryModal';
import { AdminModal } from './components/AdminModal';
import { OrdersModal } from './components/OrdersModal';
import { SearchModal } from './components/SearchModal';
import { AuthModal } from './components/AuthModal';
import { CustomerChatModal } from './components/CustomerChatModal';
import { Toast } from './components/Toast';
import { Flame, Sparkles, MessageCircle, ChevronLeft } from 'lucide-react';

export const App: React.FC = () => {
  // Store Data States
  const [products, setProducts] = useState<Product[]>(() => {
    try {
      const saved = localStorage.getItem('altakhfid_products');
      if (saved) {
        const parsed = JSON.parse(saved);
        if (Array.isArray(parsed) && parsed.length > 0) {
          return parsed.map((p: any) => {
            const price = typeof p.price === 'number' ? p.price : (typeof p.discountPrice === 'number' ? p.discountPrice : (typeof p.originalPrice === 'number' ? p.originalPrice : 0));
            return {
              ...p,
              price,
              originalPrice: typeof p.originalPrice === 'number' ? p.originalPrice : price,
              discountPrice: typeof p.discountPrice === 'number' ? p.discountPrice : price,
              discount: typeof p.discount === 'number' ? p.discount : (typeof p.discountPercentage === 'number' ? p.discountPercentage : 0),
              categoryId: p.categoryId || p.category || (p.categories && p.categories[1]) || 'all',
            };
          });
        }
      }
    } catch (e) {
      console.warn('Failed to parse cached products:', e);
    }
    return INITIAL_PRODUCTS;
  });
  const [categories, setCategories] = useState<Category[]>(INITIAL_CATEGORIES);
  const [banners, setBanners] = useState<Banner[]>(INITIAL_BANNERS);
  const [campaigns, setCampaigns] = useState<TrendCampaign[]>(INITIAL_TREND_CAMPAIGNS);
  const [hashtags] = useState<string[]>(INITIAL_TREND_HASHTAGS);
  const [pricingSettings, setPricingSettings] = useState<PricingSettings>(() => {
    try {
      const saved = localStorage.getItem('altakhfid_pricing_settings');
      return saved ? { ...initialPricingSettings, ...JSON.parse(saved) } : initialPricingSettings;
    } catch {
      return initialPricingSettings;
    }
  });

  // User & Commerce States
  const [user, setUser] = useState<User | null>(() => {
    try {
      const saved = localStorage.getItem('altakhfid_user');
      return saved ? JSON.parse(saved) : null;
    } catch {
      return null;
    }
  });
  const [currency, setCurrency] = useState<'YER' | 'SAR'>('YER');
  const [cartItems, setCartItems] = useState<CartItem[]>(() => {
    try {
      const saved = localStorage.getItem('altakhfid_cart');
      if (saved) {
        const parsed = JSON.parse(saved);
        if (Array.isArray(parsed)) {
          return parsed.map((item: any) => ({
            ...item,
            price: typeof item.price === 'number' ? item.price : (typeof item.product?.price === 'number' ? item.product.price : (typeof item.product?.discountPrice === 'number' ? item.product.discountPrice : 0)),
            quantity: typeof item.quantity === 'number' && item.quantity > 0 ? item.quantity : 1,
            product: item.product ? {
              ...item.product,
              price: typeof item.product.price === 'number' ? item.product.price : (typeof item.product.discountPrice === 'number' ? item.product.discountPrice : (typeof item.product.originalPrice === 'number' ? item.product.originalPrice : 0)),
            } : item.product,
          }));
        }
      }
    } catch (e) {
      console.warn('Failed to parse cached cart:', e);
    }
    return [];
  });
  const [wishlistIds, setWishlistIds] = useState<string[]>(() => {
    try {
      const saved = localStorage.getItem('altakhfid_wishlist');
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });
  const [orders, setOrders] = useState<Order[]>(() => {
    try {
      const saved = localStorage.getItem('altakhfid_orders');
      if (saved) {
        const parsed = JSON.parse(saved);
        if (Array.isArray(parsed)) {
          return parsed.map((ord: any) => ({
            ...ord,
            total: typeof ord.total === 'number' ? ord.total : (typeof ord.subtotal === 'number' ? ord.subtotal : 0),
            items: Array.isArray(ord.items) ? ord.items.map((it: any) => ({
              ...it,
              price: typeof it.price === 'number' ? it.price : 0,
              quantity: typeof it.quantity === 'number' ? it.quantity : 1,
            })) : [],
          }));
        }
      }
    } catch (e) {
      console.warn('Failed to parse cached orders:', e);
    }
    return [];
  });
  const [storeSettings, setStoreSettings] = useState<StoreSettings>(() => {
    try {
      const saved = localStorage.getItem('altakhfid_store_settings');
      return saved ? JSON.parse(saved) : initialStoreSettings;
    } catch {
      return initialStoreSettings;
    }
  });

  // Navigation & View States
  const [activeTab, setActiveTab] = useState<'home' | 'categories' | 'deals' | 'wishlist' | 'orders' | 'profile'>('home');
  const [selectedCategoryId, setSelectedCategoryId] = useState<string>('all');
  const [selectedTrendTag, setSelectedTrendTag] = useState<string | null>(null);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);

  // Modals
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [isWishlistOpen, setIsWishlistOpen] = useState(false);
  const [isCategoryModalOpen, setIsCategoryModalOpen] = useState(false);
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [isAdminOpen, setIsAdminOpen] = useState(false);
  const [isAuthOpen, setIsAuthOpen] = useState(false);
  const [isOrdersOpen, setIsOrdersOpen] = useState(false);
  const [isSupportOpen, setIsSupportOpen] = useState(false);

  // Toast
  const [toast, setToast] = useState<{ message: string; type?: 'success' | 'info' | 'error' } | null>(null);

  const showToast = (message: string, type: 'success' | 'info' | 'error' = 'success') => {
    setToast({ message, type });
    setTimeout(() => {
      setToast(null);
    }, 3500);
  };

  // Sync to LocalStorage
  useEffect(() => {
    localStorage.setItem('altakhfid_cart', JSON.stringify(cartItems));
  }, [cartItems]);

  useEffect(() => {
    localStorage.setItem('altakhfid_wishlist', JSON.stringify(wishlistIds));
  }, [wishlistIds]);

  useEffect(() => {
    localStorage.setItem('altakhfid_orders', JSON.stringify(orders));
  }, [orders]);

  useEffect(() => {
    localStorage.setItem('altakhfid_store_settings', JSON.stringify(storeSettings));
  }, [storeSettings]);

  useEffect(() => {
    if (user) {
      localStorage.setItem('altakhfid_user', JSON.stringify(user));
    } else {
      localStorage.removeItem('altakhfid_user');
    }
  }, [user]);

  // Initial Load & Gradual Migration from Firebase/local to whats.alattab.site
  const refreshProductsFromServer = async () => {
    try {
      const srvProducts = await fetchProductsApi();
      if (Array.isArray(srvProducts) && srvProducts.length > 0) {
        setProducts(srvProducts);
      }
    } catch (e) {
      console.warn('Refresh products error:', e);
    }
  };

  useEffect(() => {
    let isMounted = true;

    async function initAppBackend() {
      // 1. Products: Fetch from server with first-run auto-migration fallback
      try {
        const srvProducts = await fetchProductsApi();
        if (isMounted && Array.isArray(srvProducts) && srvProducts.length > 0) {
          setProducts(srvProducts);
        } else {
          const res = await autoMigrateDataToServer(
            INITIAL_PRODUCTS,
            INITIAL_CATEGORIES,
            INITIAL_BANNERS,
            INITIAL_TREND_CAMPAIGNS
          );
          if (res.serverSynced && isMounted) {
            const recheck = await fetchProductsApi();
            if (recheck.length > 0) setProducts(recheck);
          }
        }
      } catch (err) {
        console.warn('Server product initialization note:', err);
      }

      // 2. Content: Categories, Banners, Campaigns
      try {
        const content = await fetchContentApi();
        if (isMounted) {
          if (content.categories && content.categories.length > 0) {
            setCategories(content.categories);
          }
          if (content.banners && content.banners.length > 0) {
            setBanners(content.banners);
          }
          if (content.campaigns && content.campaigns.length > 0) {
            setCampaigns(content.campaigns);
          }
        }
      } catch (e) {
        console.warn('Server content fetch note:', e);
      }

      // 3. Pricing & Currency Settings
      try {
        const pricing = await fetchPricingSettingsApi();
        if (isMounted && pricing) {
          setPricingSettings(pricing);
        }
      } catch (e) {
        console.warn('Server pricing fetch note:', e);
      }

      // 4. Store & Contact Settings
      try {
        const storeSet = await fetchStoreSettingsApi();
        if (isMounted && storeSet) {
          setStoreSettings(storeSet);
        }
      } catch (e) {
        console.warn('Server store settings fetch note:', e);
      }

      // 5. Orders: Fetch from Server
      try {
        const srvOrders = await fetchOrdersApi();
        if (isMounted && Array.isArray(srvOrders) && srvOrders.length > 0) {
          setOrders(srvOrders);
        }
      } catch (e) {
        console.warn('Server orders fetch note:', e);
      }
    }

    initAppBackend();

    return () => {
      isMounted = false;
    };
  }, []);

  // Global helper to open trends with a specific hashtag
  useEffect(() => {
    const openTrendTag = (tag: string) => {
      setSelectedTrendTag(tag);
      setActiveTab('deals');
      window.scrollTo({ top: 0, behavior: 'smooth' });
      window.dispatchEvent(new CustomEvent('selectTrendTag', { detail: tag }));
    };

    (window as any).openTrendHashtag = openTrendTag;

    return () => {
      delete (window as any).openTrendHashtag;
    };
  }, []);

  // Cart operations
  const handleAddToCart = (product: Product, quantity = 1, color?: string, size?: string) => {
    setCartItems((prev) => {
      const existingIdx = prev.findIndex(
        (item) =>
          item.product.id === product.id &&
          item.selectedColor === color &&
          item.selectedSize === size
      );
      if (existingIdx > -1) {
        const updated = [...prev];
        updated[existingIdx].quantity += quantity;
        return updated;
      }
      const safePrice = typeof product.price === 'number' ? product.price : (typeof product.discountPrice === 'number' ? product.discountPrice : (typeof product.originalPrice === 'number' ? product.originalPrice : 0));
      return [...prev, { product, quantity, selectedColor: color, selectedSize: size, price: safePrice }];
    });
    showToast(`تمت إضافة "${product.name}" إلى السلة ✨`, 'success');
  };

  const handleUpdateCartQuantity = (productId: string, quantity: number) => {
    setCartItems((prev) =>
      prev
        .map((item) => (item.product.id === productId ? { ...item, quantity } : item))
        .filter((item) => item.quantity > 0)
    );
  };

  const handleRemoveCartItem = (productId: string) => {
    setCartItems((prev) => prev.filter((item) => item.product.id !== productId));
    showToast('تم حذف المنتج من السلة', 'info');
  };

  // Wishlist operations
  const handleToggleWishlist = (productId: string) => {
    setWishlistIds((prev) => {
      if (prev.includes(productId)) {
        showToast('تمت الإزالة من المفضلة', 'info');
        return prev.filter((id) => id !== productId);
      } else {
        showToast('تمت الإضافة إلى المفضلة ❤️', 'success');
        return [...prev, productId];
      }
    });
  };

  const wishlistProducts = products.filter((p) => wishlistIds.includes(p.id));

  // Category filter
  const displayedProducts =
    selectedCategoryId === 'all'
      ? products
      : products.filter((p) => p.categoryId === selectedCategoryId);

  return (
    <div className="min-h-screen flex flex-col bg-slate-50 text-slate-900 pb-20 sm:pb-8 selection:bg-purple-600 selection:text-white">
      {/* App Header */}
      <Header
        cartCount={cartItems.reduce((s, i) => s + i.quantity, 0)}
        wishlistCount={wishlistIds.length}
        currency={currency}
        user={user}
        onOpenSearch={() => setIsSearchOpen(true)}
        onOpenCart={() => setIsCartOpen(true)}
        onOpenWishlist={() => setIsWishlistOpen(true)}
        onOpenAdmin={() => setIsAdminOpen(true)}
        onOpenAuth={() => setIsAuthOpen(true)}
        onToggleCurrency={() => setCurrency((c) => (c === 'YER' ? 'SAR' : 'YER'))}
      />

      {/* Main View Container */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-3 sm:px-6 pt-3 sm:pt-6">
        {/* VIEW 1: HOME PAGE */}
        {activeTab === 'home' && (
          <div className="space-y-6">
            {/* Hero Banner Carousel */}
            {banners.length > 0 && (
              <div className="relative rounded-3xl overflow-hidden bg-gradient-to-r from-purple-900 via-indigo-900 to-slate-900 shadow-lg text-white">
                <div className="flex overflow-x-auto no-scrollbar snap-x snap-mandatory">
                  {banners.map((banner) => (
                    <div
                      key={banner.id}
                      className="min-w-full snap-center relative aspect-16/7 sm:aspect-21/8 flex items-center p-6 sm:p-10 cursor-pointer overflow-hidden"
                      onClick={() => {
                        if (banner.badge) (window as any).openTrendHashtag(banner.badge);
                      }}
                    >
                      <img
                        src={banner.image}
                        alt={banner.title}
                        className="absolute inset-0 w-full h-full object-cover object-center opacity-40 mix-blend-luminosity"
                      />
                      <div className="absolute inset-0 bg-gradient-to-r from-black/80 via-black/40 to-transparent" />
                      <div className="relative z-10 max-w-lg space-y-2">
                        {banner.badge && (
                          <span className="inline-flex items-center gap-1 text-[11px] font-black bg-amber-500 text-slate-950 px-2.5 py-0.5 rounded-full shadow-xs">
                            <Flame className="w-3 h-3" />
                            {banner.badge}
                          </span>
                        )}
                        <h2 className="text-xl sm:text-3xl font-black leading-tight tracking-tight">
                          {banner.title}
                        </h2>
                        {banner.subtitle && (
                          <p className="text-xs sm:text-sm text-slate-200 line-clamp-2">
                            {banner.subtitle}
                          </p>
                        )}
                        {banner.code && (
                          <div className="pt-2">
                            <span className="text-xs font-mono font-bold bg-white/20 backdrop-blur-md px-3 py-1 rounded-xl border border-white/30">
                              كوبون: {banner.code}
                            </span>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Categories Circle Chips */}
            <div className="space-y-2.5">
              <div className="flex items-center justify-between px-1">
                <h2 className="text-sm sm:text-base font-extrabold text-slate-800">الأقسام الرئيسية</h2>
                <button
                  onClick={() => setIsCategoryModalOpen(true)}
                  className="text-xs text-purple-700 font-bold flex items-center hover:underline"
                >
                  <span>عرض الكل</span>
                  <ChevronLeft className="w-3.5 h-3.5 mr-0.5" />
                </button>
              </div>

              <div className="flex gap-3 overflow-x-auto no-scrollbar py-1">
                <button
                  onClick={() => setSelectedCategoryId('all')}
                  className={`flex flex-col items-center gap-1.5 shrink-0 transition-all ${
                    selectedCategoryId === 'all' ? 'scale-105' : 'opacity-80 hover:opacity-100'
                  }`}
                >
                  <div
                    className={`w-14 h-14 rounded-2xl flex items-center justify-center font-black text-xs transition-all shadow-xs ${
                      selectedCategoryId === 'all'
                        ? 'bg-purple-600 text-white shadow-purple-600/30'
                        : 'bg-white border border-slate-200 text-slate-700'
                    }`}
                  >
                    الكل
                  </div>
                  <span className="text-[11px] font-bold text-slate-700">جميع الأصناف</span>
                </button>

                {categories.map((cat) => (
                  <button
                    key={cat.id}
                    onClick={() => setSelectedCategoryId(cat.id)}
                    className={`flex flex-col items-center gap-1.5 shrink-0 transition-all ${
                      selectedCategoryId === cat.id ? 'scale-105' : 'opacity-80 hover:opacity-100'
                    }`}
                  >
                    <div
                      className={`w-14 h-14 rounded-2xl overflow-hidden p-0.5 border transition-all shadow-xs ${
                        selectedCategoryId === cat.id
                          ? 'border-purple-600 ring-2 ring-purple-500/30'
                          : 'border-slate-200 bg-white'
                      }`}
                    >
                      <img
                        src={cat.image}
                        alt={cat.name}
                        className="w-full h-full object-cover rounded-xl"
                      />
                    </div>
                    <span className="text-[11px] font-bold text-slate-700 max-w-16 truncate">
                      {cat.name}
                    </span>
                  </button>
                ))}
              </div>
            </div>

            {/* Flash Deals Banner Trigger */}
            <div
              onClick={() => {
                setActiveTab('deals');
                (window as any).openTrendHashtag('#تخفيضات_كبرى');
              }}
              className="bg-gradient-to-r from-amber-500 via-orange-500 to-rose-600 text-white rounded-2xl p-4 sm:p-5 flex items-center justify-between cursor-pointer shadow-md active:scale-98 transition-transform"
            >
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-white/20 backdrop-blur-md flex items-center justify-center">
                  <Flame className="w-6 h-6 text-white" />
                </div>
                <div>
                  <h3 className="font-black text-sm sm:text-base leading-snug">
                    تخفيضات كبرى وعروض حصرية
                  </h3>
                  <p className="text-xs text-amber-100 mt-0.5">
                    خصومات تصل حتى 70% على تشكيلة واسعة من الملابس والأحذية
                  </p>
                </div>
              </div>
              <span className="text-xs font-black bg-white text-rose-600 px-3 py-1.5 rounded-xl shadow-xs shrink-0">
                تصفح الآن
              </span>
            </div>

            {/* Products Grid */}
            <div className="space-y-3">
              <div className="flex items-center justify-between px-1">
                <h2 className="text-sm sm:text-base font-extrabold text-slate-800 flex items-center gap-1.5">
                  <Sparkles className="w-4 h-4 text-purple-600" />
                  <span>
                    {selectedCategoryId === 'all'
                      ? 'أحدث التشكيلات المعروضة'
                      : categories.find((c) => c.id === selectedCategoryId)?.name}
                  </span>
                  <span className="text-xs font-medium text-slate-400">
                    ({displayedProducts.length})
                  </span>
                </h2>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3 sm:gap-4">
                {displayedProducts.map((product) => (
                  <ProductCard
                    key={product.id}
                    product={product}
                    currency={currency}
                    isWishlisted={wishlistIds.includes(product.id)}
                    onSelect={setSelectedProduct}
                    onAddToCart={handleAddToCart}
                    onToggleWishlist={handleToggleWishlist}
                    onOpenTrendHashtag={(tag) => {
                      if ((window as any).openTrendHashtag) {
                        (window as any).openTrendHashtag(tag);
                      }
                    }}
                  />
                ))}
              </div>
            </div>
          </div>
        )}

        {/* VIEW 2: CATEGORIES TAB */}
        {activeTab === 'categories' && (
          <div className="space-y-6 pb-12">
            <h1 className="text-lg sm:text-xl font-extrabold text-slate-900 px-1">
              تصفح كافة الأقسام والتصنيفات
            </h1>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {categories.map((cat) => (
                <div
                  key={cat.id}
                  onClick={() => {
                    setSelectedCategoryId(cat.id);
                    setActiveTab('home');
                  }}
                  className="bg-white rounded-2xl p-4 border border-slate-200/80 shadow-xs hover:shadow-md transition-all cursor-pointer flex items-center gap-4"
                >
                  <img
                    src={cat.image}
                    alt={cat.name}
                    className="w-20 h-20 object-cover rounded-xl shrink-0"
                  />
                  <div className="flex-1 min-w-0">
                    <h3 className="font-extrabold text-sm text-slate-800">{cat.name}</h3>
                    <p className="text-xs text-slate-500 mt-0.5">{cat.itemCount || 100}+ منتج متاح</p>
                    <span className="text-[11px] font-bold text-purple-700 mt-2 block">
                      عرض المنتجات ←
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* VIEW 3: TRENDS TAB */}
        {activeTab === 'deals' && (
          <TrendsView
            products={products}
            campaigns={campaigns}
            hashtags={hashtags}
            wishlistIds={wishlistIds}
            currency={currency}
            selectedHashtag={selectedTrendTag}
            onSelectProduct={setSelectedProduct}
            onAddToCart={handleAddToCart}
            onToggleWishlist={handleToggleWishlist}
            onShowToast={showToast}
          />
        )}

        {/* VIEW 4: WISHLIST TAB */}
        {activeTab === 'wishlist' && (
          <div className="space-y-4 pb-12">
            <h1 className="text-lg sm:text-xl font-extrabold text-slate-900 px-1">
              قائمة المفضلة ({wishlistProducts.length})
            </h1>
            {wishlistProducts.length === 0 ? (
              <div className="bg-white rounded-3xl p-12 text-center border border-slate-100">
                <p className="text-sm text-slate-500">لا توجد منتجات بالمفضلة حالياً</p>
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3 sm:gap-4">
                {wishlistProducts.map((p) => (
                  <ProductCard
                    key={p.id}
                    product={p}
                    currency={currency}
                    isWishlisted={true}
                    onSelect={setSelectedProduct}
                    onAddToCart={handleAddToCart}
                    onToggleWishlist={handleToggleWishlist}
                  />
                ))}
              </div>
            )}
          </div>
        )}

        {/* VIEW 5: ORDERS TAB */}
        {activeTab === 'orders' && (
          <div className="space-y-4 pb-12">
            <h1 className="text-lg sm:text-xl font-extrabold text-slate-900 px-1">
              طلباتي ومشترياتي
            </h1>

            {/* Admin Banner if user is Admin */}
            {(user?.isAdmin || user?.role === 'admin') && (
              <div className="bg-gradient-to-r from-purple-900 via-indigo-900 to-slate-900 text-white rounded-2xl p-5 shadow-sm border border-purple-800/50 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-amber-400 text-slate-950 flex items-center justify-center font-black shrink-0 shadow-sm">
                    👑
                  </div>
                  <div>
                    <h3 className="text-sm font-black text-white">حساب مسؤول ومدير المتجر</h3>
                    <p className="text-xs text-purple-200 mt-0.5">
                      لديك صلاحيات إدارة المنتجات، الأقسام، الأسعار، الطلبات، والترحيل إلى الخادم
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => setIsAdminOpen(true)}
                  className="px-4 py-2 bg-gradient-to-r from-amber-400 to-amber-500 hover:from-amber-500 hover:to-amber-600 text-slate-950 rounded-xl text-xs font-black shadow-sm transition-all cursor-pointer shrink-0"
                >
                  الدخول إلى لوحة التحكم ←
                </button>
              </div>
            )}

            <div className="bg-white rounded-2xl p-6 border border-slate-100 space-y-3">
              <p className="text-xs text-slate-500">
                تصفح كافة طلباتك السابقة وتتبع حالة الشحن والتوصيل مباشرة
              </p>
              <button
                onClick={() => setIsOrdersOpen(true)}
                className="px-4 py-2 bg-purple-600 text-white rounded-xl text-xs font-bold shadow-xs hover:bg-purple-700 transition-all"
              >
                عرض سجل الطلبات ({orders.length})
              </button>
            </div>
          </div>
        )}
      </main>

      {/* Floating Customer Support Button */}
      <button
        onClick={() => setIsSupportOpen(true)}
        className="fixed bottom-18 sm:bottom-6 left-4 z-40 bg-emerald-600 hover:bg-emerald-700 text-white p-3 sm:px-4 sm:py-3 rounded-full shadow-lg shadow-emerald-600/30 flex items-center gap-2 font-bold text-xs active:scale-95 transition-all"
        title="خدمة العملاء والدعم الفني"
      >
        <MessageCircle className="w-5 h-5" />
        <span className="hidden sm:inline">خدمة العملاء</span>
      </button>

      {/* Mobile Bottom Navigation */}
      <BottomNavigation
        activeTab={activeTab}
        cartCount={cartItems.reduce((s, i) => s + i.quantity, 0)}
        wishlistCount={wishlistIds.length}
        onSelectTab={(tab) => {
          setActiveTab(tab);
          if (tab === 'orders') setIsOrdersOpen(true);
        }}
        onOpenCart={() => setIsCartOpen(true)}
      />

      {/* Modals & Dialogs */}
      <ProductDetailsModal
        product={selectedProduct}
        currency={currency}
        isWishlisted={selectedProduct ? wishlistIds.includes(selectedProduct.id) : false}
        onClose={() => setSelectedProduct(null)}
        onAddToCart={handleAddToCart}
        onToggleWishlist={handleToggleWishlist}
        onOpenTrendHashtag={(tag) => {
          if ((window as any).openTrendHashtag) {
            (window as any).openTrendHashtag(tag);
          }
        }}
        onShowToast={showToast}
      />

      <CartModal
        isOpen={isCartOpen}
        cartItems={cartItems}
        currency={currency}
        storeSettings={storeSettings}
        onClose={() => setIsCartOpen(false)}
        onUpdateQuantity={handleUpdateCartQuantity}
        onRemoveItem={handleRemoveCartItem}
        onClearCart={() => setCartItems([])}
        onOrderPlaced={(newOrder) => {
          setOrders((prev) => [newOrder, ...prev]);
        }}
        onShowToast={showToast}
      />

      <WishlistModal
        isOpen={isWishlistOpen}
        wishlistProducts={wishlistProducts}
        currency={currency}
        onClose={() => setIsWishlistOpen(false)}
        onToggleWishlist={handleToggleWishlist}
        onAddToCart={handleAddToCart}
        onSelectProduct={(p) => {
          setIsWishlistOpen(false);
          setSelectedProduct(p);
        }}
      />

      <CategoryModal
        isOpen={isCategoryModalOpen}
        categories={categories}
        selectedCategoryId={selectedCategoryId}
        onClose={() => setIsCategoryModalOpen(false)}
        onSelectCategory={(catId) => {
          setSelectedCategoryId(catId);
          setActiveTab('home');
        }}
      />

      <SearchModal
        isOpen={isSearchOpen}
        products={products}
        currency={currency}
        onClose={() => setIsSearchOpen(false)}
        onSelectProduct={(p) => {
          setSelectedProduct(p);
        }}
      />

      <AdminModal
        isOpen={isAdminOpen}
        orders={orders}
        products={products}
        campaigns={campaigns}
        pricingSettings={pricingSettings}
        storeSettings={storeSettings}
        onClose={() => setIsAdminOpen(false)}
        onUpdateOrderStatus={(orderId, status, isPaid) => {
          setOrders((prev) =>
            prev.map((ord) => (ord.id === orderId ? { ...ord, status, isPaid: isPaid ?? ord.isPaid } : ord))
          );
        }}
        onSaveProduct={(prod) => {
          setProducts((prev) => {
            const exists = prev.some((p) => p.id === prod.id);
            if (exists) return prev.map((p) => (p.id === prod.id ? prod : p));
            return [prod, ...prev];
          });
          showToast('تمت إضافة المنتج وحفظه في الخادم بنجاح', 'success');
        }}
        onDeleteProduct={(prodId) => {
          setProducts((prev) => prev.filter((p) => p.id !== prodId));
          showToast('تم حذف المنتج بنجاح', 'info');
        }}
        onUpdateCampaigns={setCampaigns}
        onSavePricingSettings={(newPricing) => {
          setPricingSettings(newPricing);
          showToast('تم تحديث وتطبيق إعدادات التسعير بنجاح', 'success');
        }}
        onSaveStoreSettings={(newSettings) => {
          setStoreSettings(newSettings);
          showToast('تم تحديث وتطبيق بيانات الإدارة والأرقام بنجاح', 'success');
        }}
        onRefreshProductsFromServer={refreshProductsFromServer}
        onShowToast={showToast}
      />

      <OrdersModal
        isOpen={isOrdersOpen}
        orders={orders}
        currency={currency}
        onClose={() => setIsOrdersOpen(false)}
        onOpenSupport={() => {
          setIsOrdersOpen(false);
          setIsSupportOpen(true);
        }}
      />

      <AuthModal
        isOpen={isAuthOpen}
        user={user}
        onClose={() => setIsAuthOpen(false)}
        onOpenAdmin={() => setIsAdminOpen(true)}
        onLogin={setUser}
        onLogout={() => setUser(null)}
        onShowToast={showToast}
      />

      <CustomerChatModal
        isOpen={isSupportOpen}
        storeSettings={storeSettings}
        onClose={() => setIsSupportOpen(false)}
      />

      {/* Global Toast */}
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  );
};

export default App;
