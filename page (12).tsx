"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";

export default function Register(){
  const router = useRouter();
  const [submitted, setSubmitted] = useState(false);
  function handleSubmit(event: React.FormEvent<HTMLFormElement>){
    event.preventDefault();
    setSubmitted(true);
    router.push("/investor");
  }
  return <section className="section section-soft"><div className="container"><div className="form-shell"><div className="eyebrow">Investor registration</div><h2>Begin your investment journey.</h2><p>Enter your details to begin an individual investor account application.</p><form className="form-grid" onSubmit={handleSubmit}><label>Full name<input type="text" placeholder="Your full name" autoComplete="name" required/></label><label>Email address<input type="email" placeholder="you@example.com" autoComplete="email" required/></label><label>Phone number<input type="tel" placeholder="+254 …" autoComplete="tel" required/></label><label>Country of residence<input type="text" placeholder="Country" autoComplete="country-name" required/></label><label>Preferred account currency<select defaultValue="KES"><option>KES</option><option>USD</option><option>GBP</option></select></label><button type="submit" className="button button-gold">Continue</button></form>{submitted && <p role="status" className="form-note">Opening the investor dashboard. Your details have not been submitted to a live registration service.</p>}<p className="form-note">Secure registration, identity verification and account activation will be enabled when the backend is connected. This form does not yet create an investor account.</p><p className="form-note">Already have an account? <Link href="/login" style={{color:'#987842'}}>Sign in</Link></p></div></div></section>
}
