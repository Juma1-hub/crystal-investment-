"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";
import { getSupabaseBrowserClient } from "@/lib/supabase";

export default function Login(){
  const router=useRouter();
  const [error,setError]=useState("");
  const [busy,setBusy]=useState(false);
  async function submit(e:FormEvent<HTMLFormElement>){
    e.preventDefault(); setError(""); setBusy(true);
    const supabase=getSupabaseBrowserClient();
    if(!supabase){setError("Investor sign-in is not configured yet. Please contact the site administrator.");setBusy(false);return;}
    const form=new FormData(e.currentTarget);
    const email=String(form.get("email")||"").trim().toLowerCase();
    const password=String(form.get("password")||"");
    const {error}=await supabase.auth.signInWithPassword({email,password});
    setBusy(false);
    if(error){setError(error.message.includes("Email not confirmed")?"Please confirm your email address using the link we sent before signing in.":"The email address or password could not be verified. Please try again.");return;}
    window.dispatchEvent(new Event("crystal-session-change"));
    router.replace("/investor");
    router.refresh();
  }
  return <section className="section section-soft"><div className="container"><div className="form-shell"><div className="eyebrow">Investor access</div><h2>Welcome back.</h2><p>Sign in to access your investor dashboard.</p><form className="form-grid" onSubmit={submit}><label>Email address<input name="email" type="email" placeholder="you@example.com" autoComplete="email" required/></label><label>Password<input name="password" type="password" placeholder="Enter your password" autoComplete="current-password" required/></label><button type="submit" className="button button-gold" disabled={busy}>{busy?"Signing in…":"Sign in"}</button></form>{error&&<p role="alert" className="form-note">{error}</p>}<p className="form-note">New to Crystal Investments? <Link href="/register" style={{color:'#987842'}}>Create an investor account</Link></p></div></div></section>
}
