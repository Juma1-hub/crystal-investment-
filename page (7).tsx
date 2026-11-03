"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";

export default function Login(){
  const router = useRouter();
  const [message, setMessage] = useState("");
  function handleSubmit(event: React.FormEvent<HTMLFormElement>){
    event.preventDefault();
    setMessage("Opening the investor account dashboard…");
    router.push("/investor");
  }
  return <section className="section section-soft"><div className="container"><div className="form-shell"><div className="eyebrow">Investor access</div><h2>Welcome back.</h2><p>Sign in to access your Crystal Investments account.</p><form className="form-grid" onSubmit={handleSubmit}><label>Email address<input type="email" placeholder="you@example.com" autoComplete="email" required/></label><label>Password<input type="password" placeholder="Enter your password" autoComplete="current-password" required/></label><button type="submit" className="button button-gold">Sign in</button></form>{message && <p role="status" className="form-note">{message}</p>}<p className="form-note">Account authentication will be connected when the secure identity service is configured. This access currently opens the dashboard interface and does not authenticate an investor or create a financial account.</p><p className="form-note">New to Crystal Investments? <Link href="/register" style={{color:'#987842'}}>Create an investor account</Link></p><p className="form-note"><Link href="/investor" style={{color:'#987842'}}>Open investor dashboard</Link></p></div></div></section>
}
