"use client";
import {useEffect, useRef} from "react";
export default function ScrollReveal({children,className="",direction="up"}:{children:React.ReactNode;className?:string;direction?:"up"|"down"}){
 const ref=useRef<HTMLDivElement>(null);
 useEffect(()=>{const el=ref.current;if(!el)return;const observer=new IntersectionObserver(entries=>entries.forEach(entry=>{if(entry.isIntersecting){entry.target.classList.add("is-visible");observer.unobserve(entry.target)}}),{threshold:.12,rootMargin:"0px 0px -35px 0px"});observer.observe(el);return()=>observer.disconnect()},[]);
 return <div ref={ref} className={`scroll-reveal reveal-${direction} ${className}`}>{children}</div>
}
