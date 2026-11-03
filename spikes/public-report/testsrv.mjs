import { startServer } from './static-server.mjs';
const s=await startServer('./ssr',8093);
console.log('started');
setTimeout(()=>{s.close();},10000);