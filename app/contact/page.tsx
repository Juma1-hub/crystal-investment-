"use client";
import {FormEvent,useState} from "react";
import {getSupabaseBrowserClient} from "@/lib/supabase";
export default function Contact(){
 const [message,setMessage]=useState(""),[error,setError]=useState(""),[busy,setBusy]=useState(false);
 async function submit(e:FormEvent<HTMLFormElement>){
  e.preventDefault();setMessage("");setError("");setBusy(true);
  const form=e.currentTarget;const data=new FormData(form);
  const name=String(data.get("name")||"").trim(),email=String(data.get("email")||"").trim(),category=String(data.get("type")||"General enquiry"),body=String(data.get("message")||"").trim();
  if(!name||!email||body.length<5){setError("Please complete all required fields.");setBusy(false);return;}
  const db=getSupabaseBrowserClient();if(!db){setError("Please try again later.");setBusy(false);return;}
  const {error:submitError}=await db.rpc("public_submit_contact_enquiry",{p_name:name,p_email:email,p_category:category,p_subject:category,p_message:body,p_website:String(data.get("website")||"")});
  setBusy(false);
  if(submitError){setError("We could not submit your enquiry. Please try again.");return;}
  setMessage("Thank you. Your enquiry has been received.");form.reset();
 }
 return <><section className="page-hero"><div className="container"><div className="eyebrow">Contact us</div><h1>Let's start a conversation.</h1><p>Reach out for general enquiries, potential partnerships and investor relations.</p></div></section><section className="section section-soft"><div className="container"><div className="form-shell"><h2>Send an enquiry</h2><p>Complete the form to contact our team.</p><form className="form-grid" onSubmit={submit}><label>Full name<input name="name" maxLength={160} autoComplete="name" required/></label><label>Email address<input name="email" type="email" maxLength={254} autoComplete="email" required/></label><label>Enquiry type<select name="type" defaultValue="General enquiry"><option>General enquiry</option><option>Investor relations</option><option>Partnership</option><option>Other</option></select></label><label>Message<textarea name="message" maxLength={10000} required/></label><label aria-hidden="true" style={{position:"absolute",left:"-10000px",width:1,height:1,overflow:"hidden"}}>Website<input name="website" tabIndex={-1} autoComplete="off"/></label><button className="button button-gold" type="submit" disabled={busy}>{busy?"Sending…":"Send enquiry"}</button></form>{error&&<p className="form-note" role="alert">{error}</p>}{message&&<p className="form-note" role="status">{message}</p>}</div></div></section></>;
}
