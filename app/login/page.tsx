"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";

type InvestorProfile = { fullName?: string; email?: string; password?: string; [key: string]: unknown };
export default function Login(){
  const router=useRouter();
  const [error,setError]=useState("");
  function submit(e:FormEvent<HTMLFormElement>){
    e.preventDefault(); setError("");
    const form=new FormData(e.currentTarget);
    const email=String(form.get("email")||"").trim().toLowerCase();
    const password=String(form.get("password")||"");
    try{
      const current=JSON.parse(localStorage.getItem("crystal_demo_investor")||"null") as InvestorProfile|null;
      const registry=JSON.parse(localStorage.getItem("crystal_investor_profiles")||"[]") as InvestorProfile[];
      const investor=registry.find(p=>String(p.email||"").toLowerCase()===email) || (String(current?.email||"").toLowerCase()===email?current:null);
      if(!investor){setError("We could not find an investor account with that email address. Please register first.");return;}
      // Older local demo profiles did not store a password. On their first sign-in,
      // accept the supplied password and save it for subsequent sign-ins.
      if(investor.password && investor.password!==password){setError("The password is incorrect. Please try again.");return;}
      const updated={...investor,password:investor.password||password};
      localStorage.setItem("crystal_demo_investor",JSON.stringify(updated));
      localStorage.setItem("crystal_investor_profiles",JSON.stringify([...registry.filter(p=>String(p.email||"").toLowerCase()!==email),updated]));
      localStorage.setItem("crystal_account_currency",String(updated.currency||"KES"));
      localStorage.setItem("crystal_demo_session","active");
      window.dispatchEvent(new Event("crystal-session-change"));
      router.push("/investor");
    }catch{setError("Unable to access the investor profile. Please check your browser storage and try again.");}
  }
  return <section className="section section-soft"><div className="container"><div className="form-shell"><div className="eyebrow">Investor access</div><h2>Welcome back.</h2><p>Sign in to access your investor dashboard.</p><form className="form-grid" onSubmit={submit}><label>Email address<input name="email" type="email" placeholder="you@example.com" autoComplete="email" required/></label><label>Password<input name="password" type="password" placeholder="Enter your password" autoComplete="current-password" required/></label><button type="submit" className="button button-gold">Sign in</button></form>{error&&<p role="alert" className="form-note">{error}</p>}<p className="form-note">New to Crystal Investments? <Link href="/register" style={{color:'#987842'}}>Create an investor account</Link></p></div></div></section>
}
