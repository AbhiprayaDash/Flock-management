import {RecordRow,flockDay} from './domain';
import {assessPerformance,dayFacts} from './performance';
export type HealthRisk={title:string;explanation:string;action:string;source?:{label:string;url:string}};
const earlySource={label:'Veterinary guidance: early chick mortality',url:'https://pmc.ncbi.nlm.nih.gov/articles/PMC8251962/'};
export function healthRisks(batch:RecordRow,allRows:RecordRow[],date:string):HealthRisk[]{
 const rows=allRows.filter(r=>r.batch_id===batch.id),facts=dayFacts(rows,date),assessment=assessPerformance(batch,rows,date);
 const day=flockDay(batch.data.placement,date),risks:HealthRisk[]=[];
 if(assessment.severity==='Urgent veterinary review'){
  if(facts.deaths!=null&&facts.deaths>0){
   const young=day>=1&&day<=7;
   risks.push({title:young?'Early chick mortality — investigate promptly':'Mortality concern — cause undetermined',explanation:young?'Deaths in the first week can involve brooding or transport stress, dehydration, failure to start feeding, or infections such as navel/yolk-sac infection (omphalitis). The log cannot distinguish these causes.':'An unusual death count may reflect infection, heat or ventilation problems, water/feed interruption, or other causes. Mortality alone does not identify a disease.',action:'Contact the company veterinarian now for flock examination and appropriate post-mortem/laboratory investigation. Check brooding temperature, chick distribution, water and feed access. Do not wait for more daily records.',source:earlySource});
  }else risks.push({title:'Reported severe signs — urgent examination',explanation:'Severe breathing difficulty or rapid deterioration may reflect respiratory illness or environmental distress; daily totals cannot identify the cause.',action:'Contact the veterinarian promptly and check ventilation and water access.'});
 }
 if(assessment.intakeFlags.some(f=>f.direction==='low'))risks.push({title:'Low intake — dehydration or poor growth risk',explanation:'Insufficient water or feed can compromise hydration and growth. Low intake may also accompany illness, heat stress or access problems; it does not establish a particular disease.',action:'Confirm the units and reporting period. Check feeder/drinker access, water flow, crop fill and bird activity; ask the company officer or veterinarian to examine persistent changes.',source:earlySource});
 if(assessment.intakeFlags.some(f=>f.reading==='water'&&f.direction==='high'))risks.push({title:'High water reading — check heat, leaks and litter',explanation:'A high reading may reflect hot conditions, leaks, wastage or illness. It is not proof of infection. If litter is wet or contaminated, ask the veterinarian about enteric-disease risks, including coccidiosis.',action:'Check the meter, drinker leaks and litter condition. Report diarrhea, blood in droppings, lethargy or continued deaths promptly. Do not restrict drinking water to match the estimate.',source:{label:'ICAR: coccidiosis guidance',url:'https://www.icar.gov.in/en/poultry-coccidiosis-recognising-disease-and-preventing-production-losses'}});
 if(assessment.intakeFlags.some(f=>f.reading==='feed'&&f.direction==='high'))risks.push({title:'High feed reading — verify consumption',explanation:'Feed disappearance can include spillage, pests or recording errors. A high feed total alone does not predict a disease.',action:'Check feed wastage, quantity units, feeder settings and recent weight measurements before interpreting the reading.'});
 return risks;
}
