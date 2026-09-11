const { chromium } = require('playwright');

const url = process.argv[2];
const outputPath = process.argv[3];

if (!url || !outputPath) {
  throw new Error('Uso: node capture_aws_estimate.cjs <url> <saida.png>');
}

(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.CHROME_PATH || 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  });
  const page = await browser.newPage({
    viewport: { width: 1680, height: 1300 },
    deviceScaleFactor: 1,
    locale: 'pt-BR',
  });

  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await page.getByText(/Resumo da estimativa/i).first().waitFor({ timeout: 120000 });

  for (const selector of [
    'button[aria-label="Close notification"]',
    'button[aria-label="Fechar notificação"]',
    'button[aria-label="Minimize chat window"]',
  ]) {
    const button = page.locator(selector).first();
    if (await button.isVisible().catch(() => false)) {
      await button.click({ force: true }).catch(() => {});
    }
  }

  for (const name of ['Decline', 'Recusar', 'Accept', 'Aceitar']) {
    const button = page.getByRole('button', { name, exact: true }).first();
    if (await button.isVisible().catch(() => false)) {
      await button.click({ force: true }).catch(() => {});
      break;
    }
  }

  await page.evaluate(() => {
    document.documentElement.style.zoom = '80%';
  });
  await page.waitForTimeout(800);
  await page.screenshot({ path: outputPath, fullPage: true });
  await browser.close();
})();
