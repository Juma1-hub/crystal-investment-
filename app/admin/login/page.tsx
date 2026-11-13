"use client";
import {FormEvent,useState} from "react";
import {useRouter} from "next/navigation";
import {ShieldCheck} from "lucide-react";
import BrandMark from "@/components/BrandMark";
import {getSupabaseBrowserClient} from "@/lib/supabase";
export default function AdminLogin(){const [email,setEmail]=useState("");const [password,setPassword]=useState("");const [notice,setNotice]=useState("");const [busy,setBusy]=useState(false);const router=useRouter();
 async function submit(e:FormEvent){e.preventDefault();setNotice("");setBusy(true);const db=getSupabaseBrowserClient();if(!db){setNotice("Unable to sign in. Please try again.");setBusy(false);return;}const {error}=await db.auth.signInWithPassword({email:email.trim(),password});if(error){setNotice("The administrator credentials could not be verified.");setBusy(false);return;}const {data,error:accessError}=await db.rpc("crystal_admin_access");if(accessError||!data?.role){await db.auth.signOut();setNotice("This account does not have administrator access.");setBusy(false);return;}router.replace("/admin");}
 return <main className="auth-page"><section className="auth-card"><div className="auth-brand"><BrandMark size={48}/><span><b>CRYSTAL</b><small>INVESTMENTS · ADMIN</small></span></div><div className="eyebrow"><ShieldCheck size={15}/> SECURE ADMINISTRATOR ACCESS</div><h1>Administrator sign in</h1><form className="portal-form" onSubmit={submit}><label>Administrator email<input type="email" autoComplete="username" value={email} onChange={e=>setEmail(e.target.value)} required/></label><label>Password<input type="password" autoComplete="current-password" value={password} onChange={e=>setPassword(e.target.value)} required/></label><button className="button button-gold" type="submit" disabled={busy}>{busy?"Signing in…":"Sign in securely"}</button></form>{notice&&<p className="form-note" role="alert">{notice}</p>}</section></main>
}
