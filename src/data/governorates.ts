export const ALL_GOVERNORATES = [
  'صنعاء','أمانة العاصمة','عدن','تعز','إب','الحديدة','حضرموت','المكلا','مأرب','الجوف','صعدة','حجة','ذمار','البيضاء','لحج','أبين','شبوة','الضالع','ريمة','المحويت','عمران','البيضاء'
];

export const GOVERNORATE_RATES: Record<string,{shippingFee?:number}> = Object.fromEntries(
  ALL_GOVERNORATES.map(name => [name,{shippingFee:2500}])
);
