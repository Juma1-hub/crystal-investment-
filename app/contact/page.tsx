"use client";
import {FormEvent,useState} from "react";
export default function Contact(){
 const [message,setMessage]=useState("");
 const [error,setError]=useState("");
 function submit(e:FormEvent<HTMLFormElement>){
  e.preventDefault();setMessage("");setError("");
  const form=e.currentTarget;const data=new FormData(form);
  const enquiry={id:crypto.randomUUID(),name:String(data.get("name")||"").trim(),email:String(data.get("email")||"").trim(),type:String(data.get("type")||"General enquiry"),message:String(data.get("message")||"").trim(),createdAt:new Date().toISOString()};
  if(!enquiry.name||!enquiry.email||!enquiry.message){setError("Please complete all required fields.");return;}
  try{
   const previous=JSON.parse(localStorage.getItem("crystal_contact_enquiries")||"[]");
   localStorage.setItem("crystal_contact_enquiries",JSON.stringify([enquiry,...previous]));
   const settings=JSON.parse(localStorage.getItem("crystal_site_settings")||"{}");
   const recipient=String(settings.contactEmail||"").trim();
   if(recipient){
    const subject=encodeURIComponent(`Crystal Investments — ${enquiry.type}`);
    const body=encodeURIComponent(`Name: ${enquiry.name}\nEmail: ${enquiry.email}\nEnquiry type: ${enquiry.type}\n\n${enquiry.message}`);
    window.location.href=`mailto:${recipient}?subject=${subject}&body=${body}`;
    setMessage("Your email application has been opened with the enquiry prepared. Please send the email to complete delivery.");
   }else{
    setMessage("Your enquiry has been saved in this browser, but email delivery is not configured. Please contact the site administrator to configure the investor relations email.");
   }
   form.reset();
  }catch{setError("We could not prepare your enquiry. Please try again.");}
 }
 return <><section className="page-hero"><div className="container"><div className="eyebrow">Contact us</div><h1>Let's start a conversation.</h1><p>Reach out for general enquiries, potential partnerships and investor relations.</p></div></section><section className="section section-soft"><div className="container"><div className="form-shell"><h2>Send an enquiry</h2><p>Complete the form to contact our team.</p><form className="form-grid" onSubmit={submit}><label>Full name<input name="name" placeholder="Your name" autoComplete="name" required/></label><label>Email address<input name="email" type="email" placeholder="you@example.com" autoComplete="email" required/></label><label>Enquiry type<select name="type" defaultValue="General enquiry"><option>General enquiry</option><option>Investor relations</option><option>Partnership</option><option>Other</option></select></label><label>Message<textarea name="message" placeholder="How can we help?" required/></label><button className="button button-gold" type="submit">Send enquiry</button></form>{error&&<p className="form-note" role="alert">{error}</p>}{message&&<p className="form-note" role="status">{message}</p>}</div></div></section></>;
}
