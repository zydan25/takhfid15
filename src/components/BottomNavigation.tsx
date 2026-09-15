import React from 'react';
import { Home, Grid, Flame, Heart, User, ShoppingBag } from 'lucide-react';

interface BottomNavigationProps {
  activeTab: 'home' | 'categories' | 'deals' | 'wishlist' | 'orders' | 'profile';
  cartCount: number;
  wishlistCount: number;
  onSelectTab: (tab: 'home' | 'categories' | 'deals' | 'wishlist' | 'orders' | 'profile') => void;
  onOpenCart: () => void;
}

export const BottomNavigation: React.FC<BottomNavigationProps> = ({
  activeTab,
  cartCount,
  wishlistCount,
  onSelectTab,
  onOpenCart,
}) => {
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-md border-t border-slate-200/80 shadow-lg sm:hidden pb-safe">
      <div className="flex items-center justify-around py-1 px-2">
        {/* Home */}
        <button
          onClick={() => onSelectTab('home')}
          className={`flex flex-col items-center justify-center py-1 px-2.5 rounded-xl transition-all ${
            activeTab === 'home' ? 'text-purple-700 font-bold' : 'text-slate-500 font-medium'
          }`}
        >
          <Home className={`w-5 h-5 ${activeTab === 'home' ? 'stroke-[2.5]' : 'stroke-2'}`} />
          <span className="text-[10px] mt-0.5">الرئيسية</span>
        </button>

        {/* Categories */}
        <button
          onClick={() => onSelectTab('categories')}
          className={`flex flex-col items-center justify-center py-1 px-2.5 rounded-xl transition-all ${
            activeTab === 'categories' ? 'text-purple-700 font-bold' : 'text-slate-500 font-medium'
          }`}
        >
          <Grid className={`w-5 h-5 ${activeTab === 'categories' ? 'stroke-[2.5]' : 'stroke-2'}`} />
          <span className="text-[10px] mt-0.5">الأقسام</span>
        </button>

        {/* Trends / Deals */}
        <button
          onClick={() => onSelectTab('deals')}
          className={`flex flex-col items-center justify-center py-1 px-2.5 rounded-xl transition-all ${
            activeTab === 'deals' ? 'text-purple-700 font-bold' : 'text-slate-500 font-medium'
          }`}
        >
          <div className="relative">
            <Flame className={`w-5 h-5 ${activeTab === 'deals' ? 'stroke-[2.5] text-amber-500' : 'stroke-2 text-slate-500'}`} />
            <span className="absolute -top-1 -right-1.5 px-1 py-0.2 bg-gradient-to-r from-red-500 to-amber-500 text-white text-[8px] font-black rounded-full">
              HOT
            </span>
          </div>
          <span className="text-[10px] mt-0.5">ترندات</span>
        </button>

        {/* Cart */}
        <button
          onClick={onOpenCart}
          className="flex flex-col items-center justify-center py-1 px-2.5 rounded-xl transition-all text-slate-500 font-medium relative"
        >
          <div className="relative">
            <ShoppingBag className="w-5 h-5 stroke-2 text-purple-700" />
            {cartCount > 0 && (
              <span className="absolute -top-1 -right-2 w-4 h-4 bg-purple-700 text-white text-[9px] font-bold rounded-full flex items-center justify-center">
                {cartCount}
              </span>
            )}
          </div>
          <span className="text-[10px] mt-0.5 text-purple-700 font-bold">السلة</span>
        </button>

        {/* Wishlist */}
        <button
          onClick={() => onSelectTab('wishlist')}
          className={`flex flex-col items-center justify-center py-1 px-2.5 rounded-xl transition-all ${
            activeTab === 'wishlist' ? 'text-purple-700 font-bold' : 'text-slate-500 font-medium'
          }`}
        >
          <div className="relative">
            <Heart className={`w-5 h-5 ${activeTab === 'wishlist' ? 'stroke-[2.5] fill-rose-500 text-rose-500' : 'stroke-2'}`} />
            {wishlistCount > 0 && (
              <span className="absolute -top-1 -right-2 w-4 h-4 bg-rose-500 text-white text-[9px] font-bold rounded-full flex items-center justify-center">
                {wishlistCount}
              </span>
            )}
          </div>
          <span className="text-[10px] mt-0.5">المفضلة</span>
        </button>

        {/* Profile / Orders */}
        <button
          onClick={() => onSelectTab('orders')}
          className={`flex flex-col items-center justify-center py-1 px-2.5 rounded-xl transition-all ${
            activeTab === 'orders' ? 'text-purple-700 font-bold' : 'text-slate-500 font-medium'
          }`}
        >
          <User className={`w-5 h-5 ${activeTab === 'orders' ? 'stroke-[2.5]' : 'stroke-2'}`} />
          <span className="text-[10px] mt-0.5">طلباتي</span>
        </button>
      </div>
    </nav>
  );
};
