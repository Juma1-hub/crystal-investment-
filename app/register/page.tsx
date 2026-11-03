"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";

export default function Register(){
  const router=useRouter(); const [error,setError]=useState("");
  function submit(e:FormEvent<HTMLFormElement>){e.preventDefault();setError("");const form=new FormData(e.currentTarget);const investor={fullName:String(form.get("fullName")||"").trim(),email:String(form.get("email")||"").trim().toLowerCase(),phone:String(form.get("phone")||"").trim(),country:String(form.get("country")||"").trim(),currency:String(form.get("currency")||"KES"),createdAt:new Date().toISOString()};
    if(!investor.fullName||!investor.email||!investor.phone||!investor.country){setError("Please complete all required fields.");return;}
    try{localStorage.setItem("crystal_demo_investor",JSON.stringify(investor));localStorage.setItem("crystal_demo_session","active");router.push("/investor");}catch{setError("Your browser could not save this demo profile. Please enable local storage and try again.");}
  }
  return <section className="section section-soft"><div className="container"><div className="form-shell"><div className="eyebrow">Investor registration</div><h2>Begin your investment journey.</h2><p>Create a sample investor profile to explore the investor dashboard.</p><form className="form-grid" onSubmit={submit}><label>Full name<input name="fullName" type="text" placeholder="Your full name" autoComplete="name" required/></label><label>Email address<input name="email" type="email" placeholder="you@example.com" autoComplete="email" required/></label><label>Phone number<input name="phone" type="tel" placeholder="+254 ..." autoComplete="tel" required/></label><label>Country of residence<input name="country" type="text" placeholder="Country" autoComplete="country-name" required/></label><label>Preferred account currency<select name="currency" defaultValue="KES"><option value="KES">KES</option><option value="USD">USD</option><option value="GBP">GBP</option></select></label><button type="submit" className="button button-gold">Submit registration details</button></form>{error&&<p role="alert" className="form-note">{error}</p>}<p className="form-note">Already have an account? <Link href="/login" style={{color:'#987842'}}>Sign in</Link></p><p className="form-note">Demo access: details are saved only in this browser. No account is created on a server and no password or payment details are collected.</p></div></div></section>
}
