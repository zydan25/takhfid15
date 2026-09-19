import React from 'react';
import type { Product, TrendCampaign } from '../types';
import { ProductCard } from './ProductCard';

interface Props{products:Product[];campaigns:TrendCampaign[];hashtags:string[];wishlistIds:string[];currency:'YER'|'SAR';selectedHashtag:string|null;onSelectProduct:(p:Product)=>void;onAddToCart:(p:Product,q?:number,color?:string,size?:string)=>void;onToggleWishlist:(id:string)=>void;onShowToast:(msg:string,type?:'success'|'info'|'error')=>void;}
export const TrendsView:React.FC<Props>=({products,campaigns,hashtags,wishlistIds,currency,selectedHashtag,onSelectProduct,onAddToCart,onToggleWishlist,onShowToast})=>{
 const filtered=selectedHashtag?products.filter(p=>(p.tags||[]).some(t=>String(t).replace(/^#/,'')===selectedHashtag.replace(/^#/,'')||String(t)===selectedHashtag)):products;
 return <div className="space-y-5 pb-12">
  <div className="flex gap-2 overflow-x-auto no-scrollbar">{hashtags.map(h=><span key={h} className="px-3 py-1.5 rounded-full bg-purple-50 text-purple-700 text-xs font-bold">{h}</span>)}</div>
  {campaigns.length>0&&<div className="space-y-3">{campaigns.map(c=><div key={c.id} className="rounded-2xl overflow-hidden border bg-white"><img src={c.image} alt={c.title} className="w-full aspect-[16/7] object-cover"/><div className="p-3"><div className="font-black text-sm">{c.title}</div>{c.subtitle&&<div className="text-xs text-slate-500 mt-1">{c.subtitle}</div>}{c.tag&&<div className="text-[11px] text-purple-700 font-bold mt-2">{c.tag}</div>}</div></div>)}</div>}
  <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">{filtered.map(p=><ProductCard key={p.id} product={p} currency={currency} isWishlisted={wishlistIds.includes(p.id)} onSelect={onSelectProduct} onAddToCart={onAddToCart} onToggleWishlist={onToggleWishlist}/>)}</div>
  {filtered.length===0&&<div className="text-center py-16 text-sm text-slate-500">لا توجد منتجات لهذا الترند حالياً</div>}
 </div>;
};
