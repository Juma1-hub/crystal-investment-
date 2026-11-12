"use client";
import {useEffect,useState} from "react";
import {getSupabaseBrowserClient} from "@/lib/supabase";
import {CurrencyValue} from "./CurrencyValue";
export default function InvestorInvestmentList(){const [rows,setRows]=useState<any[]>([]);
 useEffect(()=>{let live=true;const db=getSupabaseBrowserClient();if(!db)return;db.from("investment_allocations").select("id,project_name,amount,currency,status,terms_reference,activated_at,created_at").order("created_at",{ascending:false}).then(({data})=>{if(live)setRows(data||[])});return()=>{live=false}},[]);
 return rows.length?<div className="record-list">{rows.map(r=><article className="record-row" key={r.id}><span><b>{r.project_name}</b><small>{r.status} · {r.terms_reference}</small></span><strong><CurrencyValue amount={Number(r.amount)} sourceCurrency={r.currency}/></strong></article>)}</div>:<div className="portal-empty">No investment allocations have been recorded.</div>;
}
