import {NextRequest,NextResponse} from 'next/server';
import {aiConfiguration} from '@/lib/ai-provider';
export async function GET(req:NextRequest){const c=aiConfiguration(req.headers.get('x-vercel-oidc-token'));return NextResponse.json({configured:!!(c.token&&c.model),model:c.model??null,provider:c.gateway?'Vercel AI Gateway':'Configured provider',consentRequired:true,dailyRequestLimit:10,maxRequestUsd:.01,liveVerificationRequired:true})}
