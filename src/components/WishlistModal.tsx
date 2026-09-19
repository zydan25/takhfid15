import React from 'react';
import { X, Heart, ShoppingCart } from 'lucide-react';
import type { Product } from '../types';
import { formatCurrencyPrice } from '../utils/pricing';

interface Props{isOpen:boolean;wishlistProducts:Product[];currency:'YER'|'SAR';onClose:()=>void;onToggleWishlist:(id:string)=>void;onAddToCart:(p:Product)=>void;onSelectProduct:(p:Product)=>void;}
export const WishlistModal:React.FC<Props>=({isOpen,wishlistProducts,currency,onClose,onToggleWishlist,onAddToCart,onSelectProduct})=>{
 if(!isOpen)return null;
 return <div className="fixed inset-0 z-80 bg-black/50 flex justify-end"><aside className="bg-white w-full max-w-md h-full flex flex-col"><header className="p-4 border-b flex items-center justify-between"><h2 className="font-black">المفضلة ({wishlistProducts.length})</h2><button aria-label="إغلاق" onClick={onClose}><X/></button></header><div className="p-3 space-y-3 overflow-auto">{wishlistProducts.length===0?<div className="text-center text-sm text-slate-500 py-16">لا توجد منتجات في المفضلة</div>:wishlistProducts.map(p=><div key={p.id} className="flex gap-3 p-2 border rounded-xl"><img src={p.image} className="w-20 h-20 object-cover rounded-lg" alt={p.name}/><div className="min-w-0 flex-1"><button className="text-right w-full font-bold text-xs line-clamp-2" onClick={()=>onSelectProduct(p)}>{p.name}</button><div className="text-xs font-black text-purple-700 mt-1">{formatCurrencyPrice(p.price||0,currency)}</div><div className="flex gap-2 mt-2"><button onClick={()=>onAddToCart(p)} className="px-3 py-1.5 rounded-lg bg-purple-600 text-white text-[10px] font-bold flex items-center gap-1"><ShoppingCart className="w-3.5 h-3.5"/>السلة</button><button onClick={()=>onToggleWishlist(p.id)} className="px-3 py-1.5 rounded-lg bg-rose-50 text-rose-600 text-[10px] font-bold flex items-center gap-1"><Heart className="w-3.5 h-3.5 fill-current"/>حذف</button></div></div></div>)}</div></aside></div>;
};
