import React,{useMemo,useState} from 'react';
import { X, Search } from 'lucide-react';
import type { Product } from '../types';
import { formatCurrencyPrice } from '../utils/pricing';

interface Props{isOpen:boolean;products:Product[];currency:'YER'|'SAR';onClose:()=>void;onSelectProduct:(p:Product)=>void;}
export const SearchModal:React.FC<Props>=({isOpen,products,currency,onClose,onSelectProduct})=>{
 const [q,setQ]=useState('');
 const filtered=useMemo(()=>{const s=q.trim().toLowerCase();if(!s)return products;return products.filter(p=>[p.name,p.category,p.subCategory||'',...(p.tags||[])].join(' ').toLowerCase().includes(s));},[q,products]);
 if(!isOpen)return null;
 return <div className="fixed inset-0 z-[85] bg-black/50 flex items-start justify-center p-3 pt-16"><div className="bg-white w-full max-w-lg max-h-[80vh] rounded-2xl flex flex-col"><header className="p-3 border-b flex items-center gap-2"><Search className="w-4 h-4 text-slate-400"/><input autoFocus value={q} onChange={e=>setQ(e.target.value)} className="flex-1 text-sm outline-none" placeholder="ابحث عن منتج..." /><button aria-label="إغلاق" onClick={onClose}><X/></button></header><div className="p-3 overflow-auto space-y-2">{filtered.slice(0,100).map(p=><button key={p.id} onClick={()=>{onSelectProduct(p);onClose();}} className="w-full flex items-center gap-3 p-2 rounded-xl hover:bg-slate-50 text-right"><img src={p.image} alt={p.name} className="w-12 h-12 rounded-lg object-cover"/><span className="flex-1 text-xs font-bold">{p.name}</span><span className="text-[10px] font-black text-purple-700">{formatCurrencyPrice(p.price||0,currency)}</span></button>)}{filtered.length===0&&<div className="py-10 text-center text-xs text-slate-500">لا توجد نتائج</div>}</div></div></div>;
};
