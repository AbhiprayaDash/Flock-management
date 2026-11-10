import test from 'node:test';
import assert from 'node:assert/strict';
import React from 'react';
import {renderToStaticMarkup} from 'react-dom/server';
import {BirdBehavior} from '../components/bird-behavior';
import {behaviorSchema,defaultBehavior} from '../lib/bird-behavior';
import {defaultGuide,resolveGuide} from '../lib/management-guide';
test('Behavior library covers comfort, movement, access, respiratory and neurological concerns across all seasons',()=>{assert.equal(behaviorSchema.safeParse(defaultBehavior).success,true);assert.equal(defaultBehavior.length,8);for(const b of defaultBehavior)for(const s of ['summer','rainy','winter'] as const)assert.ok(b[s].length>10);assert.equal(behaviorSchema.safeParse([{...defaultBehavior[0],source:'javascript:alert(1)'}]).success,false);assert.equal(behaviorSchema.safeParse([defaultBehavior[0],defaultBehavior[0]]).success,false);assert.equal(resolveGuide({...defaultGuide,behavior:undefined}).behavior.length,8)});
test('Behavior page explains limits, urgent action, recording and all-season responses without creating a diagnosis',()=>{const html=renderToStaticMarkup(React.createElement(BirdBehavior,{guide:defaultBehavior,onHealth:()=>{}}));for(const phrase of ['cannot confirm a disease','sudden losses','What to do','Compare all seasons','Summer / hot','Rainy / humid','Winter / cold','observation time','Urgent veterinary review'])assert.ok(html.includes(phrase),phrase);assert.ok(!html.includes('disease probability'));assert.ok(!html.includes('mg/kg'))});
