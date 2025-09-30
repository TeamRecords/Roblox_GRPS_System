export const metadata = { title: "RLE Leaderboard", description: "Robloxian Lightning Empire — GRPS Web" };
import "./globals.css";
export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body className="min-h-screen font-sans antialiased">{children}</body>
    </html>
  );
}
