import {RecordRow,flockDay} from './domain';
export function batchStatus(batch:RecordRow){return batch.data.status==='Completed'?'Completed':'Active'}
export function browseWorkspace(rows:RecordRow[],farmId:string,shedId:string,batchId:string,status='All'){
 const batches=rows.filter(r=>r.kind==='batch');
 const farms=[...rows.filter(r=>r.kind==='farm')];
 for(const b of batches)if(b.data.farm&&!farms.some(f=>f.id===b.data.farm))farms.push({id:b.data.farm,kind:'farm',data:{name:'Assigned farm'}});
 const requested=batches.find(b=>b.id===batchId);
 const farm=farms.find(f=>f.id===farmId)??farms.find(f=>f.id===requested?.data.farm)??farms[0];
 const sheds=rows.filter(r=>r.kind==='shed'&&r.data.farm===farm?.id);
 for(const b of batches.filter(b=>b.data.farm===farm?.id))if(b.data.shed&&!sheds.some(s=>s.id===b.data.shed))sheds.push({id:b.data.shed,kind:'shed',data:{name:'Assigned shed',farm:farm?.id}});
 const shed=sheds.find(s=>s.id===shedId)??sheds.find(s=>s.id===requested?.data.shed)??sheds[0];
 const matching=batches.filter(b=>b.data.farm===farm?.id&&b.data.shed===shed?.id&&(status==='All'||batchStatus(b)===status)).sort((a,b)=>b.data.placement.localeCompare(a.data.placement));
 return {farms,farm,sheds,shed,batches:matching,batch:matching.find(b=>b.id===batchId)??matching[0]};
}
export const sopTasks=[
 {key:'biosecurity',title:'Check entry biosecurity',detail:'Check footbaths, dedicated footwear and the visitor record.',from:1},
 {key:'feed-water',title:'Check feed and drinking water',detail:'Inspect supply, feeder access, drinker height, leaks and interruptions.',from:1},
 {key:'environment',title:'Check temperature and ventilation',detail:'Check EC sensors, fans, inlets and controller alarms; record readings and observe panting or huddling. Recheck through the day.',from:1},
 {key:'litter',title:'Inspect litter and ammonia',detail:'Check wet patches, leaks and air quality; follow the approved limits.',from:1},
 {key:'mortality',title:'Count mortality and culls separately',detail:'Record losses and follow the farm’s approved disposal procedure.',from:1},
 {key:'health',title:'Observe flock health and review due tasks',detail:'Perform an afternoon flock walk: activity, droppings, heat stress, water access and veterinary reminders. Escalate concerning signs.',from:1},
 {key:'records',title:'Complete daily records and company report',detail:'Enter measured feed, water, losses and notes. Share the report through your agreed company channel.',from:1},
 {key:'lighting',title:'Check lighting and uninterrupted darkness',detail:'Follow the integrator’s approved program and local welfare rules.',from:1},
 {key:'brooding',title:'Review chick comfort and brooding equipment',detail:'Check heat distribution, chick access and crop fill; test generator readiness and backup water using approved procedures.',from:1,to:7},
 {key:'pickup',title:'Review company pickup readiness',detail:'Confirm the company plan and veterinarian-verified withdrawal status. Follow approved catching and transport procedures.',from:29}
];
export function dailySop(batch:RecordRow,date:string,rows:RecordRow[]){const day=flockDay(batch.data.placement,date);return sopTasks.filter(t=>day>=t.from&&(!t.to||day<=t.to)).map(task=>({...task,record:rows.find(r=>r.kind==='checkpoint'&&r.batch_id===batch.id&&r.data.source==='daily_sop'&&r.data.sopKey===task.key&&r.data.due===date)}))}
export function isCompanyPickup(row:RecordRow){return row.kind==='inventory'&&['company_pickup','sale'].includes(row.data.type)}
