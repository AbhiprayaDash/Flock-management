create or replace function public.cp_submit(b uuid,p jsonb) returns uuid language plpgsql security definer set search_path=public as $$
declare i cp_instances; r cp_readings; old_ cp_readings; rid uuid; k text; v jsonb; n numeric; measured_ timestamptz; existing uuid; profile_ jsonb; approvedage int;request_hash text;prior_request cp_requests;
begin
 select * into i from cp_instances where id=(p->>'instanceId')::uuid and batch_id=b;if not found or not cp_staff(i.org_id,b) or org_role(i.org_id)='veterinarian' then raise exception 'Checkpoint is not accessible for recording';end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text||(p->>'requestId'),717));
 request_hash=encode(extensions.digest(p::text,'sha256'),'hex');select * into prior_request from cp_requests where user_id=auth.uid() and request_id=(p->>'requestId')::uuid;if found then if prior_request.payload_hash<>request_hash then raise exception 'Request identifier reused with changed content; review draft before retrying';end if;return prior_request.reading_id;end if;
 perform pg_advisory_xact_lock(hashtextextended(b::text,716));
 select id into existing from cp_readings where actor=auth.uid() and request_id=(p->>'requestId')::uuid;if existing is not null then return existing;end if;
 if i.status='cancelled' or exists(select 1 from records where id=b and data->>'status'='Completed') then raise exception 'Schedule changed or batch is completed. Keep draft and review with the manager.';end if;
 measured_=(p->>'measuredAt')::timestamptz;if measured_>now()+interval '5 minutes' or (measured_ at time zone i.timezone)::date<(select (data->>'placement')::date from records where id=b) or measured_<i.scheduled_at-make_interval(mins=>(i.snapshot->>'leadMinutes')::int) then raise exception 'Measurement time is in the future or before the checkpoint opens';end if;
 if p->>'access' not in ('accessible','unable_to_access') or p->>'access'='unable_to_access' and nullif(trim(p->>'accessReason'),'') is null then raise exception 'Record access status and reason';end if;
 if jsonb_typeof(p->'values')<>'object' or jsonb_typeof(p->'states')<>'object' then raise exception 'Readings required';end if;
 for k,v in select * from jsonb_each(p->'values') loop
 if k not in ('temperature','humidity','ammonia','co2','waterTemperature','waterPh','waterAmount','feedAmount','deaths','culls','lux') then raise exception 'Unknown measurement';end if;
 if v->>'state' not in ('measured','not_measured','instrument_unavailable','estimated') or v->>'method' not in ('manual','sensor','estimated') then raise exception 'Measurement provenance required';end if;
 if v->>'value' is not null then n=(v->>'value')::numeric;if n<0 and k<>'temperature' or k='temperature' and n not between -10 and 60 or k='humidity' and n>100 or k='waterPh' and n>14 or k='ammonia' and n>500 or k='co2' and n>100000 or k in ('deaths','culls') and mod(n,1)<>0 then raise exception 'Invalid numeric reading';end if;end if;
 if v->>'state'='measured' and v->>'value' is null or v->>'state' in ('not_measured','instrument_unavailable') and v->>'value' is not null then raise exception 'Missing is not zero';end if;
 if k='ammonia' and (v->>'state'='estimated' or v->>'method'='estimated') then raise exception 'Ammonia must not be estimated from smell or images';end if;
 end loop;
 for k in select jsonb_array_elements_text(i.snapshot->'required') loop if k in ('temperature','humidity','ammonia','co2','waterTemperature','waterPh','waterAmount','feedAmount','deaths','culls','lux') and cp_num(p,k) is null and nullif(trim(coalesce(p#>>array['values',k,'reason'],'')),'') is null and p->>'access'<>'unable_to_access' then if k<>'waterPh' or not exists(select 1 from cp_readings x where x.batch_id=b and x.measured_at<measured_ and x.measured_at>measured_-make_interval(hours=>coalesce((i.snapshot->>'phEveryHours')::int,24)) and cp_num(x.payload,'waterPh') is not null) then raise exception 'Explain missing required measurement: %',k;end if;end if;end loop;
 if jsonb_array_length(coalesce(p->'photos','[]'))>6 then raise exception 'Maximum six evidence photos';end if;
 for k in select jsonb_array_elements_text(coalesce(p->'photos','[]')) loop if k not like i.org_id::text||'/'||b::text||'/%' or k like '%..%' or array_length(string_to_array(k,'/'),1)<>3 then raise exception 'Photo outside authorized batch';end if;if not exists(select 1 from storage.objects where bucket_id='flock-photos' and name=k) then raise exception 'Private photo evidence not found';end if;end loop;
 if nullif(p->>'intervalStart','')::timestamptz>=measured_ then raise exception 'Invalid interval';end if;
 profile_=i.snapshot->'profile';
 if p->>'readingId' is not null then
 select * into old_ from cp_readings where id=(p->>'readingId')::uuid and batch_id=b and instance_id=i.id;if not found or old_.revision<>(p->>'revision')::int or not(cp_admin(i.org_id) or old_.actor=auth.uid()) then raise exception 'Reading changed or correction is not permitted';end if;
 update cp_readings set payload=p,measured_at=measured_,revision=revision+1,updated_at=now() where id=old_.id returning id into rid;
 else insert into cp_readings(org_id,batch_id,instance_id,request_id,measured_at,payload,profile_snapshot) values(i.org_id,b,i.id,(p->>'requestId')::uuid,measured_,p,profile_) returning id into rid;end if;
 perform cp_evaluate(rid);
 -- A correction invalidates downstream rate derivations; recalculate in actual measurement order.
 for r in select * from cp_readings where batch_id=b and measured_at>measured_ order by measured_at loop update cp_readings set derived=cp_derive(r) where id=r.id;end loop;
 insert into cp_requests(user_id,request_id,batch_id,reading_id,payload_hash) values(auth.uid(),(p->>'requestId')::uuid,b,rid,request_hash);return rid;
end $$;
