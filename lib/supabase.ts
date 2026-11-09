import {createClient} from '@supabase/supabase-js';
import {isRecoveryLink} from './auth-flow';
// Capture only the recovery flag before the SDK consumes the callback hash. Never retain tokens.
export const initialRecoveryRequested=typeof window!=='undefined'&&isRecoveryLink(window.location.search,window.location.hash);
export const configured=!!(process.env.NEXT_PUBLIC_SUPABASE_URL&&process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY);
export const supabase=configured?createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!,process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!):null;
export function serverClient(token:string){if(!configured)throw new Error('Supabase is not configured');return createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!,process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,{global:{headers:{Authorization:`Bearer ${token}`}},auth:{persistSession:false}})}
