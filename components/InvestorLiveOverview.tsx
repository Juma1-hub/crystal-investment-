"use client";
import {ShieldCheck,Database,Wallet} from "lucide-react";

export default function InvestorLiveOverview(){
 return <section className="portal-card income-panel">
  <div className="card-heading"><div><span className="eyebrow">ACCOUNT CONNECTION</span><h3>Investor account status</h3></div><ShieldCheck size={20}/></div>
  <div className="admin-health-grid">
   <article><Database size={19}/><b>Investor authentication</b><span>Connected to Supabase</span></article>
   <article><Wallet size={19}/><b>Financial records</b><span>Backend integration in progress</span></article>
  </div>
  <p className="portal-disclaimer">Your sign-in and basic investor profile are being managed through the CRYSTAL INVESTMENTS Supabase project. Account balances, deposits, withdrawals, investment allocations, distributions and income reporting will appear after their secure database workflows are connected and verified. No financial activity can be initiated from this dashboard at this stage.</p>
 </section>;
}
