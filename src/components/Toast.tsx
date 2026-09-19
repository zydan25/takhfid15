import React from 'react';
import { CheckCircle2, AlertCircle, Info, X } from 'lucide-react';

interface Props{message:string;type?:'success'|'info'|'error';onClose:()=>void;}
export const Toast:React.FC<Props>=({message,type='success',onClose})=>{
 const Icon=type==='success'?CheckCircle2:type==='error'?AlertCircle:Info;
 return <div className="fixed bottom-4 left-1/2 -translate-x-1/2 z-[1000] max-w-[calc(100vw-24px)]"><div className={type==='error'?"bg-rose-600":type==='info'?"bg-slate-800":"bg-emerald-600"} className="text-white rounded-2xl shadow-lg px-4 py-3 flex items-center gap-2"><Icon className="w-4 h-4"/><span className="text-xs font-bold">{message}</span><button aria-label="إغلاق" onClick={onClose}><X className="w-4 h-4"/></button></div></div>;
};
