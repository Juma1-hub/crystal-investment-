import type { Metadata } from "next";
import "./globals.css";
import SiteHeader from "@/components/SiteHeader";
import SiteFooter from "@/components/SiteFooter";
export const metadata: Metadata = { title: "Crystal Investments | Investing Today. Building Tomorrow.", description: "Explore the investment philosophy, divisions and opportunities of Crystal Investments." };
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body><SiteHeader/><main>{children}</main><SiteFooter/></body></html>}
