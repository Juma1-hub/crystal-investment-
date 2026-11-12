"use client";
import {useEffect,useState,type FormEvent} from "react";

type SiteSettings={contactEmail:string;contactPhone:string;headquarters:string;defaultCurrency:string;footerTagline:string};
type SiteContent={homeEyebrow:string;homeDescription:string;aboutIntro:string;opportunitiesIntro:string};
const defaultSettings:SiteSettings={contactEmail:"",contactPhone:"",headquarters:"Kenya",defaultCurrency:"KES",footerTagline:"Investing Today. Building Tomorrow."};
const defaultContent:SiteContent={homeEyebrow:"A considered approach to investing",homeDescription:"We explore investment opportunities across sectors and markets, guided by disciplined evaluation, thoughtful capital allocation and a long-term perspective.",aboutIntro:"Headquartered in Kenya, Crystal Investments explores relevant opportunities around the world, across a diverse range of industries and markets.",opportunitiesIntro:"We consider opportunities worldwide, from operating businesses and real assets to infrastructure, technology and eligible financial markets."};
export default function AdminSiteManager({mode}:{mode:"settings"|"content"}){
 const [settings,setSettings]=useState<SiteSettings>(defaultSettings),[content,setContent]=useState<SiteContent>(defaultContent),[saved,setSaved]=useState("");
 useEffect(()=>{try{setSettings({...defaultSettings,...JSON.parse(localStorage.getItem("crystal_site_settings")||"{}")});setContent({...defaultContent,...JSON.parse(localStorage.getItem("crystal_site_content")||"{}")});}catch{}},[]);
 function saveSettings(){
  try{
   const payload=JSON.stringify(settings);
   localStorage.setItem("crystal_site_settings",payload);
   const verified=localStorage.getItem("crystal_site_settings");
   if(verified!==payload)throw new Error("The browser did not confirm the saved settings.");
   window.dispatchEvent(new Event("crystal-site-settings-change"));
   setSaved("Platform settings saved successfully.");
  }catch(error){setSaved(error instanceof Error?`Could not save settings: ${error.message}`:"Could not save platform settings. Please try again.");}
 }
 function submitSettings(e:FormEvent<HTMLFormElement>){e.preventDefault();saveSettings();}
 function saveContent(e:FormEvent<HTMLFormElement>){e.preventDefault();try{const payload=JSON.stringify(content);localStorage.setItem("crystal_site_content",payload);if(localStorage.getItem("crystal_site_content")!==payload)throw new Error("The browser did not confirm the saved content.");window.dispatchEvent(new Event("crystal-site-content-change"));setSaved("Website content saved successfully.");}catch(error){setSaved(error instanceof Error?`Could not save website content: ${error.message}`:"Could not save website content. Please try again.");}}
 if(mode==="settings")return <section className="admin-panel admin-site-manager"><h3>Platform settings</h3><form className="admin-site-form" onSubmit={submitSettings}><label>Investor relations email<input type="email" value={settings.contactEmail} onChange={e=>setSettings({...settings,contactEmail:e.target.value})} placeholder="investors@yourdomain.com"/></label><label>Contact telephone<input value={settings.contactPhone} onChange={e=>setSettings({...settings,contactPhone:e.target.value})} placeholder="+254 ..."/></label><label>Headquarters<input value={settings.headquarters} onChange={e=>setSettings({...settings,headquarters:e.target.value})}/></label><label>Default account currency<select value={settings.defaultCurrency} onChange={e=>setSettings({...settings,defaultCurrency:e.target.value})}><option>KES</option><option>USD</option><option>GBP</option></select></label><label className="wide-field">Footer tagline<input value={settings.footerTagline} onChange={e=>setSettings({...settings,footerTagline:e.target.value})}/></label><button className="admin-primary" type="submit">Save platform settings</button></form>{saved&&<p className={`admin-help ${saved.startsWith("Could not")?"save-error":"save-success"}`} role="status">{saved}</p>}</section>;
 return <section className="admin-panel admin-site-manager"><h3>Website content</h3><form className="admin-site-form" onSubmit={saveContent}><label>Homepage eyebrow<input value={content.homeEyebrow} onChange={e=>setContent({...content,homeEyebrow:e.target.value})}/></label><label className="wide-field">Homepage introduction<textarea rows={3} value={content.homeDescription} onChange={e=>setContent({...content,homeDescription:e.target.value})}/></label><label className="wide-field">About page introduction<textarea rows={3} value={content.aboutIntro} onChange={e=>setContent({...content,aboutIntro:e.target.value})}/></label><label className="wide-field">Opportunities introduction<textarea rows={3} value={content.opportunitiesIntro} onChange={e=>setContent({...content,opportunitiesIntro:e.target.value})}/></label><button className="admin-primary" type="submit">Save website content</button></form>{saved&&<p className="admin-help" role="status">{saved}</p>}</section>;
}
