const { chromium } = require("../web/app/node_modules/playwright");
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  await page.goto("http://localhost:5173");
  await sleep(3000);
  const lib = page.locator("button", { hasText: /library/i }).first();
  try { await lib.click({ timeout: 3000 }); await sleep(800); } catch {}
  await page.waitForSelector(".ws-work-item", { timeout: 8000 });
  await page.locator(".ws-work-item", { hasText: "Spectrum" }).first().click();
  await sleep(2500);
  await page.locator("button", { hasText: "Links" }).last().click();
  await sleep(1200);
  const info = await page.evaluate(() => {
    // Look for ANY div with "connection" or "connections" text near the top of each group
    const all = [...document.querySelectorAll("div")];
    const headerCandidates = all.filter((d) => {
      const t = d.textContent || "";
      return (t.includes("connection") || t.includes("connections"))
        && !t.includes("panel") && !t.includes("tab")
        && d.children.length < 5;
    });
    // Also check React.Fragment keys
    const connItems = [...document.querySelectorAll(".ws-conn-item")];
    return {
      headerCount: headerCandidates.length,
      headerTexts: headerCandidates.map((d) => ({
        text: d.textContent?.trim().slice(0, 60),
        style: d.getAttribute("style")?.slice(0, 60),
      })),
      firstThreeRows: connItems.slice(0, 3).map((r) => r.previousElementSibling?.textContent?.slice(0, 60) || "(no prev sibling)"),
    };
  });
  console.log(JSON.stringify(info, null, 2));
  await browser.close();
})();
