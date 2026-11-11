"use client";
import Link from "next/link";
import {useEffect,useState} from "react";
import {Menu,X} from "lucide-react";
import BrandMark from "./BrandMark";
import {getSupabaseBrowserClient} from "@/lib/supabase";
const links=[{label:"Home",href:"/"},{label:"About",href:"/about"},{label:"Divisions",href:"/divisions"},{label:"Opportunities",href:"/opportunities"},{label:"Our Approach",href:"/approach"},{label:"Insights",href:"/insights"},{label:"Contact",href:"/contact"}];
export default function SiteHeader(){
 const [open,setOpen]=useState(false),[signedIn,setSignedIn]=useState(false);
 useEffect(()=>{const supabase=getSupabaseBrowserClient();if(!supabase)return;supabase.auth.getSession().then(({data})=>setSignedIn(Boolean(data.session)));const {data:{subscription}}=supabase.auth.onAuthStateChange((_event,session)=>setSignedIn(Boolean(session)));return()=>subscription.unsubscribe()},[]);
 async function signOut(){const supabase=getSupabaseBrowserClient();if(supabase)await supabase.auth.signOut();setSignedIn(false);setOpen(false);window.dispatchEvent(new Event("crystal-session-change"));window.location.href="/";}
 return <header className="site-header"><div className="container nav-wrap"><Link href="/" className="brand" onClick={()=>setOpen(false)}><BrandMark/><span><strong>CRYSTAL</strong><small>INVESTMENTS</small></span></Link><button className="menu-toggle" aria-label="Toggle menu" onClick={()=>setOpen(!open)}>{open?<X/>:<Menu/>}</button><nav className={open?"main-nav is-open":"main-nav"}>{links.map(l=><Link key={l.href} href={l.href} onClick={()=>setOpen(false)}>{l.label}</Link>)}{signedIn?<><Link className="nav-login" href="/investor" onClick={()=>setOpen(false)}>Investor's Dash</Link><button className="nav-session-button" onClick={signOut}>Log out</button></>:<><Link className="nav-login" href="/login" onClick={()=>setOpen(false)}>Investor Login</Link><Link className="button button-gold nav-cta" href="/register" onClick={()=>setOpen(false)}>Become an Investor <span>↗</span></Link></>}</nav></div></header>
}
