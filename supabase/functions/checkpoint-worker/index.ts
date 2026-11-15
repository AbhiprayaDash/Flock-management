import {createClient} from 'npm:@supabase/supabase-js@2.57.0';
import webpush from 'npm:web-push@3.6.7';
Deno.serve(async(req:Request)=>{
 const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false}});
 const {data:settings,error}=await db.from('cp_private_settings').select('value').eq('id',true).single();if(error||!settings)return new Response('Worker not configured',{status:503});
 const expected=settings.value.workerSecret,actual=req.headers.get('x-checkpoint-worker')??'';let diff=expected.length^actual.length;for(let i=0;i<expected.length;i++)diff|=expected.charCodeAt(i)^(actual.charCodeAt(i)||0);if(diff)return new Response('Unauthorized',{status:401});
 webpush.setVapidDetails('https://flockwise-beige.vercel.app',settings.value.vapidPublic,settings.value.vapidPrivate);
 await db.from('cp_notifications').update({push_status:'retry'}).eq('push_status','sending').lt('push_attempted_at',new Date(Date.now()-300000).toISOString());
 const {data:items}=await db.from('cp_notifications').select('*').in('push_status',['not_enabled','retry']).lt('push_attempts',3).order('created_at').limit(30);let accepted=0,failed=0,disabled=0;
 await Promise.all((items??[]).map(async(n:any)=>{
 const {data:claim}=await db.from('cp_notifications').update({push_status:'sending',push_attempted_at:new Date().toISOString()}).eq('id',n.id).in('push_status',['not_enabled','retry']).select('id');if(!claim?.length)return;
 const {data:canRead}=await db.rpc('cp_access',{o:n.org_id,b:n.batch_id,u:n.user_id});if(!canRead){await db.from('cp_notifications').update({push_status:'access_revoked'}).eq('id',n.id);return}
 if(Date.parse(n.created_at)<Date.now()-86400000){await db.from('cp_notifications').update({push_status:'expired_in_app_retained',push_attempts:3}).eq('id',n.id);return}
 const {data:subs}=await db.from('cp_push_subscriptions').select('*').eq('user_id',n.user_id).eq('enabled',true).limit(8);if(!subs?.length){await db.from('cp_notifications').update({push_status:'not_enabled',push_attempts:3}).eq('id',n.id);disabled++;return}
 let anyAccepted=false,retry=false;await Promise.all(subs.map(async(sub:any)=>{const endpoint=sub.subscription.endpoint;if(!/^https:\/\/(fcm.googleapis.com|updates.push.services.mozilla.com|web.push.apple.com|[a-zA-Z0-9.-]+\.notify.windows.com)\//.test(endpoint))return;try{await webpush.sendNotification(sub.subscription,JSON.stringify({title:n.kind==='critical'?'FlockWise: critical shed alert':'FlockWise: shed checkpoint',body:n.message,url:`/?view=checkpoints&batch=${n.batch_id}`,tag:n.id}),{TTL:3600,timeout:5000});anyAccepted=true}catch(e:any){if([404,410].includes(e.statusCode))await db.from('cp_push_subscriptions').update({enabled:false}).eq('id',sub.id);else retry=true}}));
 const state=anyAccepted?'push_service_accepted':retry&&n.push_attempts<2?'retry':'failed';await db.from('cp_notifications').update({push_status:state,push_attempts:n.push_attempts+1,push_error:anyAccepted?null:'Push service unavailable; in-app reminder retained.'}).eq('id',n.id);if(anyAccepted)accepted++;else failed++;
 }));
 return new Response(JSON.stringify({accepted,failed,disabled,deviceDelivery:'unconfirmed'}),{headers:{'Content-Type':'application/json'}});
});
