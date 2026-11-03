"use client";
import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Menu, X, Gem } from "lucide-react";
const links = [{label:"Home",href:"/"},{label:"About",href:"/about"},{label:"Divisions",href:"/divisions"},{label:"Opportunities",href:"/opportunities"},{label:"Our Approach",href:"/approach"},{label:"Insights",href:"/insights"},{label:"Contact",href:"/contact"}];
export default function SiteHeader(){
 const [open,setOpen]=useState(false); const [signedIn,setSignedIn]=useState(false); const router=useRouter();
 useEffect(()=>{const sync=()=>setSignedIn(localStorage.getItem("crystal_demo_session")==="active");sync();window.addEventListener("storage",sync);window.addEventListener("crystal-session-change",sync);return()=>{window.removeEventListener("storage",sync);window.removeEventListener("crystal-session-change",sync)}},[]);
 function logout(){localStorage.removeItem("crystal_demo_session");setSignedIn(false);setOpen(false);router.push("/");}
 return <header className="site-header"><div className="container nav-wrap"><Link href="/" className="brand" onClick={()=>setOpen(false)}><span className="brand-mark"><Gem size={23}/></span><span><strong>CRYSTAL</strong><small>INVESTMENTS</small></span></Link><button className="menu-toggle" aria-label="Toggle menu" onClick={()=>setOpen(!open)}>{open?<X/>:<Menu/>}</button><nav className={open?"main-nav is-open":"main-nav"}>{links.map(l=><Link key={l.href} href={l.href} onClick={()=>setOpen(false)}>{l.label}</Link>)}{signedIn?<><Link className="nav-login" href="/investor" onClick={()=>setOpen(false)}>INVESTOR'S DASH</Link><button className="button button-gold nav-cta" type="button" onClick={logout}>Log out</button></>:<><Link className="nav-login" href="/login" onClick={()=>setOpen(false)}>Investor Login</Link><Link className="button button-gold nav-cta" href="/register" onClick={()=>setOpen(false)}>Become an Investor <span>↗</span></Link></>}</nav></div></header>
}
