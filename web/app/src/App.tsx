import { useEffect, useState } from "react";
import { AppShell } from "./components/shell/AppShell";
import { WorkspaceShell } from "./components/workspace/WorkspaceShell";

function usePathname(): string {
  const [pathname, setPathname] = useState(() => window.location.pathname);
  useEffect(() => {
    const onPop = () => setPathname(window.location.pathname);
    window.addEventListener("popstate", onPop);
    return () => window.removeEventListener("popstate", onPop);
  }, []);
  return pathname;
}

export default function App() {
  const pathname = usePathname();
  if (pathname.startsWith("/explore")) {
    return <WorkspaceShell />;
  }
  return <AppShell />;
}
