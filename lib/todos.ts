import {z} from 'zod';
import {RecordRow} from './domain';
export const todoSchema=z.object({source:z.literal('dashboard_todo'),name:z.string().trim().min(1,'Enter a reminder.').max(200),due:z.union([z.string().date(),z.literal('')]).default(''),status:z.enum(['Pending','Completed']),archived:z.boolean().default(false)});
export function batchTodos(rows:RecordRow[],batchId:string){return rows.filter(r=>r.kind==='checkpoint'&&r.batch_id===batchId&&r.data.source==='dashboard_todo'&&!r.data.archived).sort((a,b)=>(a.data.status==='Completed'?1:0)-(b.data.status==='Completed'?1:0)||(a.data.due||'9999').localeCompare(b.data.due||'9999')||(b.created_at??'').localeCompare(a.created_at??''))}
