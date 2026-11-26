// Checks the live demo of the site in a headless browser, before a release deploys it.
// It serves the built site, compiles each example of the showcase as an edited one, then each case of dev/check-demo.tex, with TikZJax, as a visitor's browser does.
// TikZJax has its own expl3 and format, and loads the package by pasting it into a preamble, so the checks of the flake don't cover it.
// Run it with `nix run .#check-demo [<output directory>]`: it needs network, since TikZJax comes from jsDelivr.
// It writes a screenshot of each picture, and the messages of TeX, to the output directory (default: check-demo), and fails if a picture doesn't compile as expected.
import { createServer } from 'node:http';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

const { SITE, CASES, BROWSER, PLAYWRIGHT_CORE } = process.env;
const { chromium } = await import(path.join(PLAYWRIGHT_CORE, 'index.mjs'));
const out = path.resolve(process.argv[2] ?? 'check-demo');
// NOTE: the first compile loads TeX, about 7 MB, and the playground gives up on a picture after 30 s.
const TIMEOUT = 180000;

// The cases: each starts with a line "%% CASE: <name>", and a line "%% ERROR: <text>" says that TeX must stop with an error whose message has <text>.
const parseCases = (text) => {
  const cases = [];
  for (const line of text.split('\n')) {
    const name = line.match(/^%% CASE: (.*)/);
    const error = line.match(/^%% ERROR: (.*)/);
    if (name) cases.push({ name: name[1].trim(), error: null, code: [] });
    else if (error && cases.length) cases.at(-1).error = error[1].trim();
    else if (cases.length && !line.startsWith('%%')) cases.at(-1).code.push(line);
  }
  return cases.map((c) => ({ ...c, code: c.code.join('\n').trim() }));
};

// A static server for the built site, on a free port.
const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.svg': 'image/svg+xml', '.pdf': 'application/pdf', '.png': 'image/png', '.json': 'application/json' };
const server = createServer(async (request, response) => {
  const name = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
  const file = path.join(SITE, name.endsWith('/') ? `${name}index.html` : name);
  try {
    if (!file.startsWith(SITE)) throw new Error('outside the site');
    const body = await readFile(file);
    response.writeHead(200, { 'content-type': types[path.extname(file)] ?? 'text/plain; charset=utf-8' });
    response.end(body);
  } catch {
    response.writeHead(404);
    response.end();
  }
});
await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const url = `http://127.0.0.1:${server.address().port}/`;

await mkdir(out, { recursive: true });
const browser = await chromium.launch({ executablePath: BROWSER, headless: true });
const page = await browser.newPage({ viewport: { width: 1200, height: 900 }, deviceScaleFactor: 2 });
let console_ = [];
page.on('console', (message) => console_.push(message.text()));
const pageErrors = [];
page.on('pageerror', (error) => pageErrors.push(error.message));
await page.goto(url);

// Compiles code in a figure of the playground, as edited code, and waits for its picture or its error.
const compile = async (figure, code) => {
  await figure.evaluate((element, text) => {
    element.querySelector('.picture .parts')?.setAttribute('data-old', '');
    element.querySelector('details.error')?.remove();
    const editor = element.querySelector('pre.code');
    editor.textContent = text;
    editor.dispatchEvent(new Event('input'));
  }, code);
  console_ = [];
  await figure.locator('[data-action="compile"]').click();
  await figure.evaluate(
    (element, timeout) =>
      new Promise((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error('no picture and no error')), timeout);
        const check = () => {
          const done =
            element.querySelector('.picture .parts:not([data-old])') || element.querySelector('details.error') || element.querySelector('.status.error');
          if (done && !element.querySelector('.picture').classList.contains('busy')) {
            clearTimeout(timer);
            resolve();
          } else requestAnimationFrame(check);
        };
        check();
      }),
    TIMEOUT,
  );
  const result = await figure.evaluate((element) => ({
    error: element.querySelector('details.error summary')?.textContent ?? null,
    details: element.querySelector('details.error pre')?.textContent ?? null,
    status: element.querySelector('.status.error')?.textContent ?? null,
  }));
  // TeX's warnings, from its output in the console: each with the lines that TeX wrapped it into, up to the one that ends the sentence.
  const lines = console_.flatMap((text) => text.split('\n'));
  const warnings = [];
  lines.forEach((line, i) => {
    if (!/Warning:/.test(line)) return;
    let warning = line.trim();
    for (const next of lines.slice(i + 1, i + 5)) {
      if (/\.$/.test(warning) || !next.trim() || /^[(!]|Failed to load/.test(next.trim())) break;
      warning += ` ${next.trim()}`;
    }
    warnings.push(warning);
  });
  return { ...result, warnings, output: lines.join('\n') };
};

const results = [];
const check = async (name, figure, code, expectedError) => {
  const started = Date.now();
  let result;
  try {
    // NOTE: the playground compiles code only when it differs from the code of the picture shown, so each compile starts with a comment of its own, which goes into the preamble.
    result = await compile(figure, `% check-demo: ${name}\n${code}`);
  } catch (error) {
    result = { error: null, status: error.message, warnings: [] };
  }
  const stem = `${String(results.length + 1).padStart(2, '0')}-${name.replace(/[^a-z0-9]+/gi, '-').toLowerCase()}`;
  const file = `${stem}.png`;
  await figure.screenshot({ path: path.join(out, file) });
  await writeFile(path.join(out, `${stem}.txt`), result.output ?? '');
  let ok;
  if (result.status) ok = false;
  else if (expectedError) ok = Boolean(result.error?.includes(expectedError));
  else ok = !result.error;
  results.push({ name, ok, ...result, expectedError, file, seconds: Math.round((Date.now() - started) / 1000) });
  const verdict = ok ? 'ok' : 'FAILED';
  console.log(`${verdict.padEnd(6)} ${name} (${results.at(-1).seconds} s)`);
  if (!ok || result.error) console.log(`       ${result.status ?? result.error ?? `no error, expected one with "${expectedError}"`}`);
};

// The showcase: each tab compiled as an edited example, so that the playground compiles it with TikZJax rather than keep the picture made at build time.
const tabs = page.locator('.showcase [role="tab"]');
const tabCount = await tabs.count();
for (let i = 0; i < tabCount; i++) {
  const tab = tabs.nth(i);
  await tab.click();
  const panel = page.locator(`#${await tab.getAttribute('aria-controls')}`);
  const figure = panel.locator('.example');
  const original = await figure.locator('pre.code').innerText();
  await check(`showcase: ${(await tab.innerText()).trim()}`, figure, original, null);
}

// The cases, compiled in the first tab of the showcase.
await tabs.nth(0).click();
const first = page.locator(`#${await tabs.nth(0).getAttribute('aria-controls')} .example`);
for (const c of parseCases(await readFile(CASES, 'utf8'))) await check(c.name, first, c.code, c.error);

await browser.close();
server.close();

const allWarnings = [...new Set(results.flatMap((r) => r.warnings))];
const report = [
  `# Check of the live demo`,
  '',
  `Site: ${SITE}`,
  `Browser: ${BROWSER}`,
  '',
  ...results.map((r) => [
    `## ${r.ok ? 'ok' : 'FAILED'}: ${r.name}`,
    '',
    `Screenshot: ${r.file}, output of TeX: ${r.file.replace(/png$/, 'txt')}; ${r.seconds} s.`,
    r.expectedError ? `Expected an error with: ${r.expectedError}` : '',
    r.status ? `Status: ${r.status}` : '',
    r.error ? `Error: ${r.error}\n\n\`\`\`\n${r.details}\n\`\`\`` : '',
    '',
  ].filter((line, i, all) => line || all[i - 1]).join('\n')),
  '## Warnings of TeX, over all pictures',
  '',
  ...(allWarnings.length ? allWarnings.map((w) => `- ${w}`) : ['None.']),
  '',
  '## Errors of the page',
  '',
  ...(pageErrors.length ? pageErrors.map((e) => `- ${e}`) : ['None.']),
  '',
].join('\n');
await writeFile(path.join(out, 'report.md'), report);

const failed = results.filter((r) => !r.ok).length + pageErrors.length;
console.log(`\n${results.length - results.filter((r) => !r.ok).length} of ${results.length} pictures as expected; ${pageErrors.length} errors of the page.`);
console.log(`Screenshots and report.md in ${out}`);
process.exit(failed ? 1 : 0);
