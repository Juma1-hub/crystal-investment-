"use client";
import Link from "next/link";
import {useEffect,useState} from "react";
import {BriefcaseBusiness,Wallet,ArrowDownToLine,ArrowUpFromLine,FileText,TrendingUp,ShieldCheck,ChartNoAxesCombined} from "lucide-react";
import {getSupabaseBrowserClient} from "@/lib/supabase";

type InvestorSummary={name:string;currency:string;email:string};
const shortcuts=[
 {label:"My investments",description:"Review allocations and project performance",href:"/investor/investments",icon:BriefcaseBusiness},
 {label:"Deposits",description:"View contribution records",href:"/investor/deposits",icon:ArrowDownToLine},
 {label:"Withdrawals",description:"Review withdrawal requests",href:"/investor/withdrawals",icon:ArrowUpFromLine},
 {label:"Statements & documents",description:"Access account documents",href:"/investor/documents",icon:FileText},
];
export default function InvestorLiveOverview(){
 const [investor,setInvestor]=useState<InvestorSummary>({name:"Investor",currency:"KES",email:""});
 useEffect(()=>{let live=true;async function load(){const supabase=getSupabaseBrowserClient();if(!supabase)return;const {data:{user}}=await supabase.auth.getUser();if(!user||!live)return;const {data}=await supabase.from("investor_profiles").select("full_name,preferred_currency").eq("id",user.id).maybeSingle();if(live)setInvestor({name:data?.full_name||String(user.user_metadata?.full_name||"Investor"),currency:data?.preferred_currency||"KES",email:user.email||""});}void load();return()=>{live=false}},[]);
 return <div className="investor-overview-stack">
  <section className="investor-metric-grid" aria-label="Investment account summary">
   <article className="investor-metric-card"><span><Wallet size={18}/> Portfolio value</span><strong>—</strong><small>Based on recorded investment valuations</small></article>
   <article className="investor-metric-card"><span><BriefcaseBusiness size={18}/> Active investments</span><strong>—</strong><small>Current approved allocations</small></article>
   <article className="investor-metric-card"><span><ArrowDownToLine size={18}/> Total contributions</span><strong>—</strong><small>Approved investor contributions</small></article>
   <article className="investor-metric-card"><span><TrendingUp size={18}/> Distributions received</span><strong>—</strong><small>Recorded payments to your account</small></article>
  </section>
  <section className="portal-card investor-account-summary">
   <div className="card-heading"><div><span className="eyebrow">ACCOUNT PROFILE</span><h3>Investor account</h3></div><ShieldCheck size={21}/></div>
   <div className="investor-profile-summary"><div><small>ACCOUNT HOLDER</small><b>{investor.name}</b></div><div><small>EMAIL ADDRESS</small><b>{investor.email||"—"}</b></div><div><small>ACCOUNT CURRENCY</small><b>{investor.currency}</b></div><Link href="/investor/profile">Manage profile <span>→</span></Link></div>
  </section>
  <section className="portal-card investor-shortcuts-panel">
   <div className="card-heading"><div><span className="eyebrow">ACCOUNT SERVICES</span><h3>Manage your investments</h3></div><ChartNoAxesCombined size={21}/></div>
   <div className="investor-shortcuts-grid">{shortcuts.map(({label,description,href,icon:Icon})=><Link href={href} key={href}><span className="investor-shortcut-icon"><Icon size={19}/></span><span><b>{label}</b><small>{description}</small></span><span className="investor-shortcut-arrow">↗</span></Link>)}</div>
  </section>
  <section className="investor-overview-bottom-grid">
   <article className="portal-card"><div className="card-heading"><div><span className="eyebrow">PORTFOLIO</span><h3>Investment activity</h3></div></div><div className="investor-empty-state"><BriefcaseBusiness size={22}/><b>No investment allocations recorded</b><p>Your approved investment allocations and project updates will appear here.</p><Link href="/investor/investments">View investments</Link></div></article>
   <article className="portal-card"><div className="card-heading"><div><span className="eyebrow">ACCOUNT HISTORY</span><h3>Recent transactions</h3></div></div><div className="investor-empty-state"><FileText size={22}/><b>No transactions recorded</b><p>Approved contributions, withdrawals and distributions will appear here.</p><Link href="/investor/transactions">View transactions</Link></div></article>
  </section>
 </div>;
}
