// KAU / TNAU approximate broiler consumption under average conditions.
// These point estimates are not breed-specific targets or diagnostic limits.
export const INDIAN_REFERENCE_VERSION='kau-tnau-broiler-v1';
export const INDIAN_REFERENCE_URL='https://www.celkau.in/Animalhusbandry/chicken/feed.php';
export function indianBroilerReference(day:number){
 if(!Number.isInteger(day)||day<1||day>42)return null;
 return {feedG:day*10/4.4,waterMl:day*5};
}
// Application-selected screening margin, not the source's seasonal allowance.
export const REFERENCE_SCREENING_MARGIN=.2;
