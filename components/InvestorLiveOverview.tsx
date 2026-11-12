"use client";
import {useEffect,useState} from "react";
import {TrendingUp,Wallet} from "lucide-react";
import {getSupabaseBrowserClient} from "@/lib/supabase";
import {CurrencyValue} from "./CurrencyValue";
export default function InvestorLiveOverview(){
 const [rows,setRows]=useState<any[]>([]);
 useEffect(()=>{let live=true;const db=getSupabaseBrowserClient();if(!db)return;const client=db;async function load(){const {data}=await client.rpc("investor_get_earnings_summary");if(live)setRows(data||[])}void load();const timer=window.setInterval(()=>void load(),60_000);const onFocus=()=>{if(document.visibilityState==="visible")void load()};document.addEventListener("visibilitychange",onFocus);return()=>{live=false;window.clearInterval(timer);document.removeEventListener("visibilitychange",onFocus)}},[]);
 return <section className="investor-grid" aria-label="Investment earnings overview">{rows.map((r:any)=><article className="portal-card income-panel" key={r.currency}><div className="card-heading"><div><span className="eyebrow">INVESTMENT PERFORMANCE</span><h3>{r.currency} allocation</h3></div><TrendingUp size={20}/></div><div className="admin-metric-row"><span>Active capital</span><b><CurrencyValue amount={Number(r.principal)} sourceCurrency={r.currency}/></b></div><div className="admin-metric-row"><span>Daily earnings</span><b><CurrencyValue amount={Number(r.daily_earnings)} sourceCurrency={r.currency}/></b></div><div className="admin-metric-row"><span>Accumulated earnings</span><b><CurrencyValue amount={Number(r.accumulated_earnings)} sourceCurrency={r.currency}/></b></div></article>)}{rows.length===0&&<article className="portal-card"><div className="card-heading"><div><span className="eyebrow">PORTFOLIO</span><h3>Investment performance</h3></div><Wallet size={20}/></div><p>Your active investment allocations and earnings will appear here.</p></article>}</section>;
}
