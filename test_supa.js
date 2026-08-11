const url = 'https://cwbenhuiextfoiyfboxo.supabase.co/rest/v1/';
const key = 'sb_publishable_ejzonFzRvs2cILpTRUoNEA_3dcdbtb-';

fetch(url, {
  method: 'GET',
  headers: {
    apikey: key,
    Authorization: `Bearer ${key}`
  }
}).then(res => res.text()).then(console.log).catch(console.error);
