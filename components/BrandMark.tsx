import React from "react";
export default function BrandMark({size=42}:{size?:number}){
 return <span className="crystal-logo-mark" style={{width:size,height:size}} aria-hidden="true"><svg viewBox="0 0 48 48" width="100%" height="100%" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M24 3 42 16 24 45 6 16 24 3Z" stroke="currentColor" strokeWidth="1.5"/><path d="M6 16h36M24 3v42M6 16l18 29 18-29M15 9l9 7 9-7" stroke="currentColor" strokeWidth="1.1"/><path d="m24 16 9 0-9 15-9-15h9Z" fill="currentColor" fillOpacity=".16"/></svg></span>
}
