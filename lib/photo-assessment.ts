import {z} from 'zod';
export const treatmentGuidanceSchema=z.object({
 supportiveCare:z.array(z.string().max(600)).max(5),
 medicationDecision:z.string().min(10).max(1000),
 medicineOptions:z.array(z.object({nameOrClass:z.string().min(2).max(150),purpose:z.string().max(500),vetMustCheck:z.array(z.string().max(400)).min(1).max(5)})).max(3),
 followUp:z.string().min(10).max(600),
 requiresVeterinarian:z.literal(true)
});
export const photoAssessmentSchema=z.object({imageQuality:z.enum(['Adequate','Limited','Insufficient']),visibleFindings:z.array(z.string().max(1000)).max(12),possibleCauses:z.array(z.string().max(1000)).max(12),urgency:z.enum(['Routine','Monitor','Urgent veterinary review','Emergency']),evidenceUsed:z.array(z.string().max(1000)).max(12),missingInformation:z.array(z.string().max(1000)).max(12),safeChecks:z.array(z.string().max(1000)).max(12),veterinaryTests:z.array(z.string().max(1000)).max(12),treatmentGuidance:treatmentGuidanceSchema.optional(),limitations:z.string().min(10).max(2000)});
export function validPhotoPath(path:string,org:string,batch:string){return path.startsWith(org+'/'+batch+'/')&&path.split('/').length===3&&!path.includes('..')&&/\.(jpeg|jpg|png|webp)$/i.test(path)}
export function safePhotoAssessment(value:unknown,urgent:boolean){const parsed=photoAssessmentSchema.parse(value);const text=JSON.stringify(parsed);if(/\b(mg\/kg|ml\/l|I prescribe|definitive diagnosis is|confirmed diagnosis is|diagnosed as)\b/i.test(text)||/\b\d+(?:\.\d+)?\s*(?:mg|mcg|µg|iu|tablets?|drops?)\b/i.test(text))throw new Error('Image assessment requires veterinary review; provider response was rejected.');if(parsed.treatmentGuidance){
 const plan=parsed.treatmentGuidance;
 const prescribingText=JSON.stringify(plan.medicineOptions);
 if(/\b(give|administer|inject|start taking|twice daily|once daily|every \d+ hours)\b/i.test(prescribingText))throw new Error('Medicine options must be for veterinary consideration, not administration instructions.');
 if(parsed.imageQuality==='Insufficient'){plan.medicineOptions=[];plan.medicationDecision='No medicine can be selected from an insufficient image. Veterinary examination and a working diagnosis are needed.';}
}else parsed.treatmentGuidance={supportiveCare:['Ensure clean drinking water, accessible feed and age-appropriate brooding conditions while arranging veterinary review.'],medicationDecision:'No medicine has been selected. A veterinarian must establish the cause and decide whether treatment is appropriate.',medicineOptions:[],followUp:'Contact the company veterinarian for examination and follow-up; seek prompt review if deaths continue.',requiresVeterinarian:true};
 if(urgent&&['Routine','Monitor'].includes(parsed.urgency))parsed.urgency='Urgent veterinary review';parsed.limitations+=' Image findings alone cannot establish a definitive diagnosis. A veterinarian must review this assessment.';return parsed;}
