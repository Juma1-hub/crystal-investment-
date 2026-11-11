"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useEffect, useState } from "react";
import { getSupabaseBrowserClient } from "@/lib/supabase";

export default function Register(){
  const router=useRouter();
  const [error,setError]=useState("");
  const [message,setMessage]=useState("");
  const [busy,setBusy]=useState(false);
  const [referralCode,setReferralCode]=useState("");
  useEffect(()=>{const value=new URLSearchParams(window.location.search).get("ref")||"";setReferralCode(value.trim().toUpperCase());},[]);
  async function submit(e:FormEvent<HTMLFormElement>){
    e.preventDefault();const formElement=e.currentTarget;setError("");setMessage("");setBusy(true);
    const supabase=getSupabaseBrowserClient();
    if(!supabase){setError("Investor registration is not configured yet. Please contact the site administrator.");setBusy(false);return;}
    const form=new FormData(e.currentTarget);
    const fullName=String(form.get("fullName")||"").trim();
    const email=String(form.get("email")||"").trim().toLowerCase();
    const password=String(form.get("password")||"");
    const phone=String(form.get("phone")||"").trim();
    const country=String(form.get("country")||"").trim();
    const currency=String(form.get("currency")||"KES");
    if(!fullName||!email||!phone||!country||password.length<8){setError("Please complete all required fields and use a password of at least 8 characters.");setBusy(false);return;}
    if(form.get("terms")!=="on"){setError("Please accept the Terms & Conditions to continue.");setBusy(false);return;}
    const {data,error}=await supabase.auth.signUp({
      email,password,
      options:{
        emailRedirectTo:`${window.location.origin}/login`,
        data:{full_name:fullName,phone,country,preferred_currency:currency,terms_accepted_at:new Date().toISOString(),referral_code:referralCode}
      }
    });
    setBusy(false);
    if(error){setError(error.message.includes("already registered")?"An account with this email address already exists. Please sign in.":error.message);return;}
    if(data.session){window.dispatchEvent(new Event("crystal-session-change"));router.replace("/investor");router.refresh();return;}
    setMessage("Your registration has been received. Please check your email and confirm your address before signing in.");
    formElement.reset();
  }
  return <section className="section section-soft"><div className="container"><div className="form-shell"><div className="eyebrow">Investor registration</div><h2>Begin your investment journey.</h2><p>Register your investor profile and access your account dashboard.</p><form className="form-grid" onSubmit={submit}><label>Full name<input name="fullName" type="text" placeholder="Your full name" autoComplete="name" required/></label><label>Email address<input name="email" type="email" placeholder="you@example.com" autoComplete="email" required/></label><label>Create password<input name="password" type="password" minLength={8} autoComplete="new-password" placeholder="At least 8 characters" required/></label><label>Phone number<input name="phone" type="tel" placeholder="+254 ..." autoComplete="tel" required/></label><label>Country of residence<input name="country" type="text" placeholder="Country" autoComplete="country-name" required/></label><label>Referral code (optional)<input name="referralCode" type="text" value={referralCode} onChange={e=>setReferralCode(e.target.value.toUpperCase())} placeholder="Enter referral code" autoCapitalize="characters"/></label><label>Preferred account currency<select name="currency" defaultValue="KES"><option value="KES">KES</option><option value="USD">USD</option><option value="GBP">GBP</option></select></label><label className="terms-check"><input type="checkbox" name="terms" required/><span>I have read and agree to the <Link href="/terms">Terms &amp; Conditions</Link> and acknowledge the investment risk disclosures.</span></label><button type="submit" className="button button-gold" disabled={busy}>{busy?"Submitting…":"Submit registration details"}</button></form>{error&&<p role="alert" className="form-note">{error}</p>}{message&&<p role="status" className="success-message">{message}</p>}<p className="form-note">Already have an account? <Link href="/login" style={{color:'#987842'}}>Sign in</Link></p></div></div></section>
}
