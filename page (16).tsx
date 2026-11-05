import {InvestorFrame,InvestorSectionContent} from "@/components/InvestorPortal";
export default async function InvestorSection({params}:{params:Promise<{section:string}>}){const {section}=await params;return <InvestorFrame><InvestorSectionContent section={section}/></InvestorFrame>}
