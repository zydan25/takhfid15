import React from 'react';
import { Heart, ShoppingCart, Flame, Star } from 'lucide-react';
import type { Product } from '../types';
import { formatCurrencyPrice } from '../utils/pricing';

interface Props {
  product: Product;
  currency: 'YER' | 'SAR';
  isWishlisted: boolean;
  onSelect: (product: Product) => void;
  onAddToCart: (product: Product, quantity?: number, color?: string, size?: string) => void;
  onToggleWishlist: (productId: string) => void;
  onOpenTrendHashtag?: (tag: string) => void;
}

export const ProductCard: React.FC<Props> = ({product,currency,isWishlisted,onSelect,onAddToCart,onToggleWishlist,onOpenTrendHashtag}) => {
  const discount = Number(product.discount || 0);
  const tags = Array.isArray(product.tags) ? product.tags : [];
  return (
    <article className="bg-white rounded-2xl border border-slate-200/80 overflow-hidden shadow-xs hover:shadow-md transition-all min-w-0">
      <div className="relative aspect-[3/4] bg-slate-100 cursor-pointer" onClick={() => onSelect(product)}>
        <img src={product.image} alt={product.name} className="w-full h-full object-cover" loading="lazy" />
        {discount > 0 && <span className="absolute top-2 right-2 bg-rose-600 text-white text-[10px] font-black px-2 py-1 rounded-full">-{discount}%</span>}
        <button type="button" aria-label="إضافة للمفضلة" onClick={(e) => {e.stopPropagation(); onToggleWishlist(product.id);}} className="absolute top-2 left-2 w-8 h-8 rounded-full bg-white/90 flex items-center justify-center shadow-sm">
          <Heart className={isWishlisted ? "w-4 h-4 fill-rose-500 text-rose-500" : "w-4 h-4 text-slate-600"} />
        </button>
        {product.featured && <span className="absolute bottom-2 right-2 inline-flex items-center gap-1 bg-amber-400 text-slate-950 text-[9px] font-black px-2 py-1 rounded-full"><Flame className="w-3 h-3" /> مميز</span>}
      </div>
      <div className="p-3 space-y-2">
        <button type="button" className="block w-full text-right" onClick={() => onSelect(product)}>
          <h3 className="text-xs font-extrabold text-slate-800 line-clamp-2 min-h-[2rem]">{product.name}</h3>
        </button>
        <div className="flex items-center justify-between gap-2">
          <div>
            <div className="text-sm font-black text-purple-700">{formatCurrencyPrice(product.price || 0, currency)}</div>
            {product.originalPrice && product.originalPrice > product.price && <div className="text-[10px] text-slate-400 line-through">{formatCurrencyPrice(product.originalPrice, currency)}</div>}
          </div>
          <div className="flex items-center gap-1 text-amber-500 text-[10px]"><Star className="w-3 h-3 fill-current" />{Number(product.rating || 0).toFixed(1)}</div>
        </div>
        {tags[0] && <button type="button" onClick={() => onOpenTrendHashtag?.(tags[0])} className="text-[10px] font-bold text-slate-500 hover:text-purple-700 truncate max-w-full">#{String(tags[0]).replace(/^#/,'')}</button>}
        <button type="button" onClick={() => onAddToCart(product,1)} className="w-full h-9 rounded-xl bg-purple-600 text-white text-[11px] font-extrabold flex items-center justify-center gap-1.5 active:scale-[.98]"><ShoppingCart className="w-4 h-4"/>إضافة للسلة</button>
      </div>
    </article>
  );
};
