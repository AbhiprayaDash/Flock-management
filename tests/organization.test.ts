import test from 'node:test';
import assert from 'node:assert/strict';
import {z} from 'zod';
import {resolveFarmOrganization,recordValidationMessage} from '../lib/organization';
const id='12345678-1234-4123-8123-123456789012';
test('First farm creates an owned workspace and returns its UUID for the save',async()=>{let called:any;const db={rpc:async(...args:any[])=>{called=args;return {data:id,error:null}}};const result=await resolveFarmOrganization(db,'',[],'farm',' Greenfield ');assert.deepEqual(result,{id,created:true});assert.deepEqual(called,['create_organization',{org_name:'Greenfield'}])});
test('Existing workspace is reused without creating another organization',async()=>{const db={rpc:()=>{throw Error('unexpected')}};assert.equal((await resolveFarmOrganization(db,id,[],'farm','Farm')).id,id);assert.equal((await resolveFarmOrganization(db,'',[{org_id:id}],'farm','Farm')).id,id)});
test('Workspace errors are actionable and do not return an invalid org ID',async()=>{await assert.rejects(()=>resolveFarmOrganization({rpc:async()=>({data:null,error:{message:'Permission denied'}})},'',[],'farm','Farm'),/Unable to create/);await assert.rejects(()=>resolveFarmOrganization({rpc:async()=>({data:'bad',error:null})},'',[],'farm','Farm'),/valid ID/);await assert.rejects(()=>resolveFarmOrganization({},'',[],'shed','Shed'),/first farm/);await assert.rejects(()=>resolveFarmOrganization({},'',[],'farm',' '),/farm name/)});
test('Invalid org ID is reported as a workspace message, not raw Zod JSON',()=>{const parsed=z.object({org_id:z.string().uuid()}).safeParse({org_id:''});assert.equal(parsed.success,false);if(!parsed.success)assert.ok(recordValidationMessage(parsed.error).includes('workspace'))});
