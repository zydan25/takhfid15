import React,{useState} from 'react';
import { X, Heart, ShoppingCart, Minus, Plus, Flame } from 'lucide-react';
import type { Product } from '../types';
import { formatCurrencyPrice } from '../utils/pricing';

interface Props {
 product: Product | null;
 currency:'YER'|'SAR';
 isWishlisted:boolean;
 onClose:()=>void;
 onAddToCart:(product:Product,quantity?:number,color?:string,size?:string)=>void;
 onToggleWishlist:(productId:string)=>void;
 onOpenTrendHashtag?:(tag:string)=>void;
 onShowToast:(msg:string,type?:'success'|'info'|'error')=>void;
}
export const ProductDetailsModal:React.FC<Props>=({product,currency,isWishlisted,onClose,onAddToCart,onToggleWishlist,onOpenTrendHashtag,onShowToast})=>{
 const [qty,setQty]=useState(1); const [color,setColor]=useState<string|undefined>(); const [size,setSize]=useState<string|undefined>();
 if(!product) return null;
 const colors=Array.isArray(product.colors)?product.colors:[]; const sizes=Array.isArray(product.sizes)?product.sizes:[]; const tags=Array.isArray(product.tags)?product.tags:[];
 return <div className="fixed inset-0 z-[90] bg-black/60 flex items-center justify-center p-3" onClick={onClose}>
   <div className="bg-white w-full max-w-lg max-h-[92vh] overflow-y-auto rounded-3xl" onClick={e=>e.stopPropagation()}>
     <div className="relative aspect-[3/4] max-h-[52vh] bg-slate-100"><img src={product.image} alt={product.name} className="w-full h-full object-contain"/><button id="product-editor-close" aria-label="إغلاق" type="button" onClick={onClose} className="absolute top-3 right-3 w-9 h-9 rounded-full bg-white/90 flex items-center justify-center shadow"><X className="w-5 h-5"/></button></div>
     <div className="p-4 space-y-4">
       <div className="flex items-start justify-between gap-3"><div><h2 className="text-base font-black text-slate-900">{product.name}</h2><p className="text-sm text-purple-700 font-black mt-1">{formatCurrencyPrice(product.price||0,currency)}</p></div><button type="button" onClick={()=>onToggleWishlist(product.id)}><Heart className={isWishlisted?"w-6 h-6 fill-rose-500 text-rose-500":"w-6 h-6 text-slate-500"}/></button></div>
       {product.description && <p className="text-xs text-slate-600 leading-6">{product.description}</p>}
       {colors.length>0 && <div><div className="text-xs font-bold text-slate-700 mb-2">اللون</div><div className="flex flex-wrap gap-2">{colors.map((c)=><button key={c.name} type="button" onClick={()=>setColor(c.name)} className={color===c.name?"ring-2 ring-purple-600":"border border-slate-200"} title={c.name}><span className="w-8 h-8 rounded-full block" style={{backgroundColor:c.hex}}/></button>)}</div></div>}
       {sizes.length>0 && <div><div className="text-xs font-bold text-slate-700 mb-2">المقاس</div><div className="flex flex-wrap gap-2">{sizes.map(s=><button key={s} type="button" onClick={()=>setSize(s)} className={size===s?"px-3 py-1.5 rounded-lg bg-purple-600 text-white text-xs font-bold":"px-3 py-1.5 rounded-lg bg-slate-100 text-slate-700 text-xs font-bold"}>{s}</button>)}</div></div>}
       {tags.length>0 && <div className="flex flex-wrap gap-2">{tags.map(t=><button key={t} type="button" onClick={()=>onOpenTrendHashtag?.(String(t))} className="text-[10px] text-purple-700 font-bold">#{String(t).replace(/^#/,'')}</button>)}</div>}
       <div className="flex items-center justify-between gap-3"><div className="inline-flex items-center rounded-xl border border-slate-200 overflow-hidden"><button type="button" className="p-2" onClick={()=>setQty(q=>Math.max(1,q-1))}><Minus className="w-4 h-4"/></button><span className="px-3 text-sm font-black">{qty}</span><button type="button" className="p-2" onClick={()=>setQty(q=>q+1)}><Plus className="w-4 h-4"/></button></div><button type="button" onClick={()=>{onAddToCart(product,qty,color,size); onShowToast('تمت إضافة المنتج إلى السلة','success'); onClose();}} className="flex-1 h-11 rounded-xl bg-purple-600 text-white text-sm font-extrabold flex items-center justify-center gap-2"><ShoppingCart className="w-5 h-5"/>إضافة للسلة</button></div>
     </div>
   </div>
 </div>;
};
