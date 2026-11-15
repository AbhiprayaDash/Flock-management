begin;
-- Test fixtures are rolled back; no real organization records are read or changed.
insert into auth.users(id,email) values('10000000-0000-4000-8000-000000000001','cp-owner@example.invalid'),('10000000-0000-4000-8000-000000000002','cp-worker@example.invalid'),('10000000-0000-4000-8000-000000000003','cp-other@example.invalid');
insert into organizations(id,name) values('20000000-0000-4000-8000-000000000001','CP test org'),('20000000-0000-4000-8000-000000000002','Other CP org');
insert into memberships values('20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','owner'),('20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002','worker'),('20000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000003','owner');
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',true);
insert into records(id,org_id,kind,data) values('30000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','farm','{"name":"Test farm","timezone":"Asia/Kolkata"}'),('30000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000001','shed','{"name":"Test shed","farm":"30000000-0000-4000-8000-000000000001"}'),('30000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000001','batch',jsonb_build_object('name','Test batch','farm','30000000-0000-4000-8000-000000000001','shed','30000000-0000-4000-8000-000000000002','placement',(now() at time zone 'Asia/Kolkata')::date,'placed',10000,'timezone','Asia/Kolkata','status','Active'));
insert into assignments values('20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002','30000000-0000-4000-8000-000000000002');
-- The fixture sets test data only; runtime functions perform actual rules.
do $$ declare r cp_readings;p uuid;s uuid;i cp_instances;rid uuid;payload jsonb; baseline_instance uuid;cmp cp_readings;baseline_time timestamptz; result_count int; aid uuid; original uuid; next_read uuid; n uuid; j int; accepted_ boolean;begin
 p=cp_save_profile('20000000-0000-4000-8000-000000000001','{"name":"Test approved","source":"Synthetic test protocol, not farm advice","context":"Synthetic rollback-only integration protocol","version":"test","approved":true,"effectiveDate":"2026-11-15","rules":{"responseMinutes":5,"escalateMinutes":5,"persistenceCount":2,"recoveryCount":2,"rapidWindowMinutes":120,"rapidTemperatureDelta":4,"intakeDropPct":25,"mortalityCriticalPct":0.5},"bands":[{"from":1,"to":null,"temperature":{"desiredMin":29,"desiredMax":31,"warningMin":28,"warningMax":32,"criticalMin":26,"criticalMax":34,"recoveryMin":29.5,"recoveryMax":30.5},"humidity":{"desiredMin":50,"desiredMax":70,"warningMin":45,"warningMax":75,"criticalMin":30,"criticalMax":85,"recoveryMin":55,"recoveryMax":65}}],"limits":{"ammoniaWarning":10,"ammoniaCritical":25,"ammoniaRecovery":8,"co2Warning":3000,"co2Critical":5000,"co2Recovery":2500,"phMin":6.5,"phMax":8}}');
 s=cp_save_schedule('20000000-0000-4000-8000-000000000001',jsonb_build_object('scope','batch','scopeId','30000000-0000-4000-8000-000000000003','profileId',p,'worker','10000000-0000-4000-8000-000000000002','manager','10000000-0000-4000-8000-000000000001','timezone','Asia/Kolkata','times',jsonb_build_array(to_char(now() at time zone 'Asia/Kolkata','HH24:MI')),'intervalMinutes',null,'startDate',(now() at time zone 'Asia/Kolkata')::date,'endDate',null,'fromDay',1,'toDay',null,'leadMinutes',15,'windowMinutes',30,'escalateMinutes',5,'enabled',true,'required',jsonb_build_array('temperature','humidity','ammonia'),'phEveryHours',24));
 perform cp_refresh('30000000-0000-4000-8000-000000000003');select * into i from cp_instances where schedule_id=s order by scheduled_at limit 1;
 if i.id is null then raise exception 'No scheduled instances generated';end if;
 payload=jsonb_build_object('requestId',gen_random_uuid(),'instanceId',i.id,'measuredAt',now(),'access','accessible','values',jsonb_build_object('temperature',jsonb_build_object('value',36,'state','measured','method','manual'),'humidity',jsonb_build_object('value',80,'state','measured','method','manual'),'ammonia',jsonb_build_object('value',30,'state','measured','method','manual')),'states',jsonb_build_object('fans','ok','ventilation','ok','cooling','ok','heating','off_not_required','waterSupply','available','feedSupply','available','litter','dry','distribution','even','lights','on','lightDeviation','no'),'signs','[]'::jsonb,'photos','[]'::jsonb,'openingBirds',10000,'waterMode','not_measured');
 rid=cp_submit(i.batch_id,payload);if rid is null then raise exception 'Submission failed';end if;
 if (select count(*) from cp_alerts where batch_id=i.batch_id and severity='critical')<2 then raise exception 'Critical threshold did not alert immediately';end if;
 if cp_submit(i.batch_id,payload)<>rid then raise exception 'Duplicate prevention failed';end if;
 if exists(select 1 from records where batch_id=i.batch_id and kind='log') then raise exception 'Checkpoint doubled into daily logs';end if;
 perform cp_tick_batch(i.batch_id);
 if (select status from cp_instances where id=i.id)<>'completed' then raise exception 'Checkpoint not completed';end if;
 select id into aid from cp_alerts where batch_id=i.batch_id and rule_key='temperature' and status='open';
 perform cp_alert_action(aid,'acknowledge','Worker saw the alert');
 if (select status from cp_alerts where id=aid)<>'acknowledged' then raise exception 'Acknowledgment incorrectly resolved alert';end if;
 perform cp_alert_action(aid,'corrective_action','Checked fans and water; arrange a new measurement',null,now()+interval '15 minutes');
 if not exists(select 1 from cp_actions where alert_id=aid and followup_id is not null) then raise exception 'Follow-up not tracked';end if;
 original=rid;
 for j in 1..2 loop
 payload=jsonb_set(payload,'{requestId}',to_jsonb(gen_random_uuid()::text));payload=jsonb_set(payload,'{measuredAt}',to_jsonb((now()+make_interval(mins=>j))::text));
 payload=jsonb_set(payload,'{values,temperature,value}','30');payload=jsonb_set(payload,'{values,humidity,value}','60');payload=jsonb_set(payload,'{values,ammonia,value}','5');
 next_read=cp_submit(i.batch_id,payload);
 if j=1 and (select status from cp_alerts where id=aid)='resolved' then raise exception 'One recheck should not satisfy two-reading recovery';end if;
 end loop;
 if (select status from cp_alerts where id=aid)<>'resolved' then raise exception 'Recovery did not resolve after two distinct measurements';end if;
 -- Changed content cannot reuse a successfully committed request identity.
 accepted_=false;begin perform cp_submit(i.batch_id,jsonb_set(payload,'{notes}','"changed content"'));accepted_=true;exception when others then if SQLERRM not like '%Request identifier%' then raise;end if;end;if accepted_ then raise exception 'Changed duplicate accepted';end if;
 -- A correction is itself idempotent, independent of the original reading request.
 payload=payload||jsonb_build_object('requestId',gen_random_uuid(),'readingId',next_read,'revision',1);
 rid=cp_submit(i.batch_id,payload);if cp_submit(i.batch_id,payload)<>rid then raise exception 'Correction retry did not deduplicate';end if;
 -- An ammonia estimate is never acceptable, even with a plausible numeric value.
 payload=payload-'readingId'-'revision';payload=jsonb_set(payload,'{requestId}',to_jsonb(gen_random_uuid()::text));payload=jsonb_set(payload,'{values,ammonia,state}','"estimated"');
 accepted_=false;begin perform cp_submit(i.batch_id,payload);accepted_=true;exception when others then if SQLERRM not like '%Ammonia%' then raise;end if;end;if accepted_ then raise exception 'Estimated ammonia accepted';end if;
 -- Overnight local slots materialize on the correct local dates, not a two-hour UTC assumption.
 n=cp_save_schedule(i.org_id,(select config from cp_schedules where id=s)||jsonb_build_object('times',jsonb_build_array('22:00','02:00'),'extra',true,'name','Overnight test'));
 perform cp_generate(i.batch_id);
 if (select count(*) from cp_instances where schedule_id=n)<4 or exists(select 1 from cp_instances where schedule_id=n and extract(hour from scheduled_at at time zone 'Asia/Kolkata') not in (2,22)) then raise exception 'Overnight scheduling incorrect';end if;
 -- Background missed-check escalation creates a manager reminder and is deduplicated.
 update cp_instances set scheduled_at=now()-interval '3 hours',deadline_at=now()-interval '2 hours',escalate_at=now()-interval '1 hour' where id=(select id from cp_instances where schedule_id=n limit 1) returning * into i;
 perform cp_tick_batch(i.batch_id);perform cp_tick_batch(i.batch_id);
 if (select status from cp_instances where id=i.id)<>'missed' or not exists(select 1 from cp_notifications where entity_id=i.id and kind='checkpoint_escalated') then raise exception 'Missed escalation failed';end if;
 if (select count(*) from cp_notifications where entity_id=i.id and kind='checkpoint_escalated')<>1 then raise exception 'Escalation duplicate';end if;
 -- Meter reset is a baseline, not consumption; a decrease is withheld.
 select * into r from cp_readings where id=original;
 r.payload=r.payload||jsonb_build_object('waterMode','meter_reset','meterId','test-meter','intervalStart',now()-interval '1 hour','openingBirds',10000,'values',r.payload->'values'||jsonb_build_object('waterAmount',jsonb_build_object('value',500,'state','measured','method','manual')));
 if cp_derive(r)->>'waterConsumed' is not null then raise exception 'Meter reset counted as consumption';end if;
 -- Rates require actual duration and verified exposure, not fabricated full-day projections.
 r.payload=r.payload||jsonb_build_object('waterMode','interval','intervalStart',now()-interval '2 hours','openingBirds',10000);
 r.derived=cp_derive(r);if (r.derived->>'hours')::numeric<>2 or (r.derived->>'waterRate')::numeric<>500.0/10000/2 then raise exception 'Per-bird/hour calculation failed';end if;
 r.payload=jsonb_set(r.payload,'{openingBirds}','null');if (cp_derive(r)->>'comparable')::boolean then raise exception 'Unknown birds considered comparable';end if;


 -- Three matched prior intervals support a current two-hour rate comparison.
 update records set data=jsonb_set(data,'{placement}',to_jsonb(((now() at time zone 'Asia/Kolkata')::date-4)::text)) where id='30000000-0000-4000-8000-000000000003';
 select * into i from cp_instances where schedule_id=s order by scheduled_at limit 1;
 i.snapshot=jsonb_set(i.snapshot,'{profile,rules,persistenceCount}','1');update cp_instances set snapshot=i.snapshot where id=i.id;
 payload=(select x.payload from cp_readings x where x.id=original)-'readingId'-'revision';
 payload=jsonb_set(payload,'{values,temperature,value}','30');payload=jsonb_set(payload,'{values,humidity,value}','60');payload=jsonb_set(payload,'{values,ammonia,value}','5');
 payload=payload||jsonb_build_object('waterMode','interval','openingBirds',10000,'values',payload->'values'||jsonb_build_object('feedAmount',jsonb_build_object('value',100,'state','measured','method','manual'),'waterAmount',jsonb_build_object('value',200,'state','measured','method','manual')));
 for j in 1..3 loop
 baseline_time=now()+interval '3 minutes'-make_interval(days=>j);
 insert into cp_instances(org_id,batch_id,scheduled_at,deadline_at,escalate_at,timezone,snapshot,worker_id,manager_id) values(i.org_id,i.batch_id,baseline_time,baseline_time+interval '30 minutes',baseline_time+interval '1 hour',i.timezone,i.snapshot,i.worker_id,i.manager_id) returning id into baseline_instance;
 payload=payload||jsonb_build_object('instanceId',baseline_instance,'requestId',gen_random_uuid(),'measuredAt',baseline_time,'intervalStart',baseline_time-interval '2 hours');
 perform cp_submit(i.batch_id,payload);
 end loop;
 payload=payload||jsonb_build_object('instanceId',i.id,'requestId',gen_random_uuid(),'measuredAt',now()+interval '3 minutes','intervalStart',now()+interval '3 minutes'-interval '2 hours');
 payload=jsonb_set(payload,'{values,feedAmount,value}','20');payload=jsonb_set(payload,'{values,waterAmount,value}','40');
 rid=cp_submit(i.batch_id,payload);select * into cmp from cp_readings where id=rid;
 if (cmp.derived->>'baselineCount')::int<>3 or not exists(select 1 from cp_alerts where batch_id=i.batch_id and rule_key='combined_intake' and status<>'resolved') then raise exception 'Matched per-bird/hour baseline comparison failed: %',cmp.derived;end if;
 -- A six-hour interval cannot reuse the three two-hour baselines.
 payload=payload||jsonb_build_object('requestId',gen_random_uuid(),'measuredAt',now()+interval '4 minutes','intervalStart',now()+interval '4 minutes'-interval '6 hours');
 rid=cp_submit(i.batch_id,payload);if (select (derived->>'baselineCount')::int from cp_readings where id=rid)<>0 then raise exception 'Unequal intervals were directly compared';end if;
 end $$;

-- Exercise actual RLS and function grants as a worker and outsider.
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000002","role":"authenticated"}',true);
set local role authenticated;
do $$ declare denied boolean=false;begin
 if (select count(*) from cp_instances)=0 then raise exception 'Assigned worker cannot read own checkpoints';end if;
 begin insert into cp_readings(org_id,batch_id,instance_id,request_id,measured_at,payload,profile_snapshot) values('20000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000003',gen_random_uuid(),gen_random_uuid(),now(),'{}','{}');exception when insufficient_privilege then denied=true;end;if not denied then raise exception 'Direct clinical insert was allowed';end if;
 denied=false;begin perform cp_save_profile('20000000-0000-4000-8000-000000000001','{}');exception when others then denied=true;end;if not denied then raise exception 'Worker approved a profile';end if;
 denied=false;begin perform cp_tick_all();exception when insufficient_privilege then denied=true;end;if not denied then raise exception 'Worker invoked global job';end if;
 denied=false;begin perform * from cp_private_settings;exception when insufficient_privilege then denied=true;end;if not denied then raise exception 'Private push credentials exposed';end if;
 end $$;
reset role;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000003","role":"authenticated"}',true);
set local role authenticated;
do $$ declare denied boolean=false;begin
 if exists(select 1 from cp_readings) or exists(select 1 from cp_instances) or exists(select 1 from cp_alerts) then raise exception 'Cross-organization data leaked';end if;
 begin perform cp_refresh('30000000-0000-4000-8000-000000000003');exception when others then denied=true;end;if not denied then raise exception 'Cross-org refresh permitted';end if;
 end $$;
reset role;
select 'checkpoint integration assertions passed; all fixtures rolled back' as result;

rollback;
