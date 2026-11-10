// Makes the examples editable in place: TikZJax, TeX compiled to WebAssembly, compiles them in the browser.
// It is loaded from jsDelivr, and only once someone heads for the code of an example or for Compile.
'use strict';

const TIKZJAX = 'https://cdn.jsdelivr.net/npm/@drgrice1/tikzjax@1.0.0-beta24/dist/';
// NOTE: TeX can hang instead of failing, so a compile that takes longer than this is given up.
const TIMEOUT = 30000;

const data = JSON.parse(document.getElementById('site-data').textContent);

// NOTE: TikZJax looks for packages next to its own script, so it can't find our string-diagrams.sty; the package goes straight into the preamble instead, which works because it has no \endinput (site/generate.lua checks).
let sty;
const styLoaded = fetch(data.sty)
  .then((response) => {
    if (!response.ok) throw new Error(`Could not load ${data.sty}.`);
    return response.text();
  })
  .then((text) => (sty = text));

let tikzjax;
let tikzjaxReady = false;
const loadTikzJax = () =>
  (tikzjax ??= new Promise((resolve, reject) => {
    const link = Object.assign(document.createElement('link'), { rel: 'stylesheet', href: TIKZJAX + 'fonts.css' });
    const script = Object.assign(document.createElement('script'), { src: TIKZJAX + 'tikzjax.js' });
    script.onload = () => {
      tikzjaxReady = true;
      resolve();
    };
    script.onerror = () => {
      tikzjax = undefined;
      reject(new Error('Could not load TikZJax.'));
    };
    document.head.append(link, script);
  }));

// One live region for the whole page tells screen readers what happened.
const announcer = Object.assign(document.createElement('p'), { className: 'visually-hidden' });
announcer.setAttribute('role', 'status');
document.body.append(announcer);
const announce = (message) => (announcer.textContent = message);

// TikZJax compiles one picture at a time, and its TeX output goes to the console, so compiles are queued and the console is captured for each.
let queue = Promise.resolve();
const enqueue = (task) => (queue = queue.then(task, task));

const captureConsole = async (lines, task) => {
  const log = console.log;
  console.log = (...args) => {
    lines.push(args.join(' '));
    log(...args);
  };
  try {
    return await task();
  } finally {
    console.log = log;
  }
};

// Resolves with the picture TikZJax draws, an <img> if TeX failed, or null on timeout.
// NOTE: TikZJax works in a hidden spot, so its own loader never shows and the page doesn't move until the picture is ready.
const render = (script) =>
  new Promise((resolve) => {
    const stage = Object.assign(document.createElement('div'), { hidden: true });
    const done = (result) => {
      observer.disconnect();
      clearTimeout(timer);
      stage.remove();
      resolve(result);
    };
    const observer = new MutationObserver(() => {
      const result = stage.querySelector('svg[role="img"], img');
      if (result) done(result);
    });
    const timer = setTimeout(() => done(null), TIMEOUT);
    observer.observe(stage, { childList: true, subtree: true });
    stage.append(script);
    document.body.append(stage);
  });

// Picks TeX's error out of its output: a one-line summary, and the full message down to the code TeX stopped at.
// Line numbers are counted in the example, as given by toExampleLine, rather than in TeX's whole input.
const texError = (lines, toExampleLine) => {
  const output = lines.join('\n').split('\n');
  const start = output.findIndex((line) => line.startsWith('!'));
  if (start === -1) return { summary: 'TeX stopped without an error message.', details: output.slice(-12).join('\n') };
  const message = [output[start].replace(/^!\s*/, '')];
  for (const line of output.slice(start + 1)) {
    if (!line.trim() || /^(See the |Type |l\.\d+)/.test(line)) break;
    // NOTE: LaTeX starts the continuation lines of a package's message with the package's name.
    message.push(line.trim().replace(/^\([\w-]+\)\s*/, ''));
  }
  const end = output.findIndex((line, i) => i > start && /^l\.\d+/.test(line));
  if (end === -1) return { summary: message.join(' '), details: output.slice(start).join('\n') };
  const line = toExampleLine(Number(output[end].match(/^l\.(\d+)/)[1]));
  const details = output.slice(start, end + 2).join('\n').replace(/^l\.\d+/m, line ? `line ${line}:` : '');
  return { summary: (line ? `Line ${line}: ` : '') + message.join(' '), details };
};

// TikZJax keeps only the first picture it draws, so code with several pictures, as in an equation, is compiled one picture at a time.
// What comes before the first picture (such as \tikzset) goes into the preamble of each, and text between pictures (such as $=$) becomes a picture of its own.
const PICTURE = /\\begin\{tikzpicture\}[\s\S]*?\\end\{tikzpicture\}/g;
const splitCode = (code) => {
  const lineAt = (index) => code.slice(0, index).split('\n').length;
  const parts = [];
  let prelude = '';
  let last = 0;
  const addText = (from, to) => {
    const text = code.slice(from, to);
    if (!text.trim()) return;
    parts.push({ tex: `\\begin{tikzpicture}\\node[inner sep=0pt]{${text.trim()}};\\end{tikzpicture}`, line: lineAt(from + text.search(/\S/)) });
  };
  for (const match of code.matchAll(PICTURE)) {
    if (parts.length) addText(last, match.index);
    else prelude = code.slice(0, match.index);
    parts.push({ tex: match[0], line: lineAt(match.index) });
    last = match.index + match[0].length;
  }
  if (!parts.length) return { prelude: '', parts: [{ tex: code, line: 1 }] };
  addText(last, code.length);
  return { prelude: prelude && !prelude.endsWith('\n') ? `${prelude}\n` : prelude, parts };
};

const sizePicture = (svg) => {
  const pt = parseFloat(svg.getAttribute('width'));
  if (pt) svg.style.width = `${Math.round((pt * 4) / 3 * data.scale)}px`;
};

const examples = new Map();
const currentCode = (figure) => figure.querySelector('pre.code').innerText.replace(/\n$/, '');

const setStatus = (example, message = '', error = false) => {
  example.status.textContent = message;
  example.status.className = error ? 'status error' : 'status';
};

// Compile and Reset are disabled while they would have no effect: Compile while the code matches the picture, Reset while it is the original.
// NOTE: aria-disabled rather than disabled, so a button keeps the focus when pressing it disables it.
const update = (figure) => {
  const example = examples.get(figure);
  const code = currentCode(figure);
  example.compileButton.setAttribute('aria-disabled', String(code === example.compiled));
  example.resetButton.setAttribute('aria-disabled', String(code === example.original));
};

// TeX's error goes on a row of its own below the buttons, its full message folded away; once opened, it stays open.
const showError = (figure, { summary, details }) => {
  const example = examples.get(figure);
  let row = figure.querySelector('details.error');
  if (!row) {
    row = Object.assign(document.createElement('details'), { className: 'error', open: example.errorOpen });
    row.addEventListener('toggle', () => (example.errorOpen = row.open));
    figure.append(row);
  }
  const summaryElement = Object.assign(document.createElement('summary'), { textContent: summary });
  row.replaceChildren(summaryElement, Object.assign(document.createElement('pre'), { textContent: details }));
  announce(summary);
};

const compile = async (figure) => {
  const example = examples.get(figure);
  const code = currentCode(figure);
  if (code === example.compiled) return;
  example.compiled = code;
  update(figure);
  const picture = figure.querySelector('.picture');
  picture.classList.add('busy');
  if (!tikzjaxReady) {
    setStatus(example, 'Loading TeX, about 7 MB the first time…');
    announce('Loading TeX.');
  }
  try {
    await Promise.all([loadTikzJax(), styLoaded]);
  } catch (error) {
    example.compiled = undefined;
    update(figure);
    picture.classList.remove('busy');
    setStatus(example, error.message, true);
    announce(error.message);
    return;
  }

  // TikZJax's input is the preamble, then \begin{document} on a line of its own, then a part of the example.
  const base = `\\makeatletter\n${sty}\n\\ExplSyntaxOff\\makeatother\n${data.preamble}`;
  const { prelude, parts } = splitCode(code);
  const preamble = base + prelude;
  const baseLines = base.split('\n').length - 1;
  const offset = preamble.split('\n').length;

  const pictures = [];
  for (const part of parts) {
    const script = Object.assign(document.createElement('script'), { type: 'text/tikz', textContent: part.tex });
    Object.assign(script.dataset, { addToPreamble: preamble, showConsole: 'true', disableCache: 'true' });
    const lines = [];
    const result = await captureConsole(lines, () => render(script));
    // NOTE: a reset meanwhile has put the original picture back, and this one is no longer wanted.
    if (example.compiled !== code) return;
    if (result?.localName === 'svg') {
      pictures.push(result);
      continue;
    }
    picture.classList.remove('busy');
    picture.classList.add('stale');
    setStatus(example);
    if (result) {
      const toExampleLine = (line) => (line > offset ? line - offset + part.line - 1 : line > baseLines ? line - baseLines : null);
      showError(figure, texError(lines, toExampleLine));
      return;
    }
    // NOTE: the code can be compiled again, though TeX is likely stuck until the page is reloaded.
    example.compiled = undefined;
    update(figure);
    setStatus(example, 'TeX did not finish: reload the page to try again.', true);
    announce('TeX did not finish.');
    return;
  }

  // The parts go side by side, as one image for screen readers.
  const row = Object.assign(document.createElement('div'), { className: 'parts' });
  row.setAttribute('role', 'img');
  row.setAttribute('aria-label', code === example.original ? example.alt : "Rendering of this example's LaTeX code, as edited.");
  for (const svg of pictures) {
    sizePicture(svg);
    svg.removeAttribute('role');
    svg.setAttribute('aria-hidden', 'true');
    row.append(svg);
  }
  picture.replaceChildren(row);
  picture.classList.remove('busy', 'stale');
  setStatus(example);
  figure.querySelector('details.error')?.remove();
  announce('Picture updated.');
};

const reset = (figure) => {
  const example = examples.get(figure);
  figure.querySelector('pre.code').textContent = example.original;
  figure.querySelector('.picture').replaceChildren(example.picture.cloneNode(true));
  figure.querySelector('.picture').classList.remove('stale', 'busy');
  figure.querySelector('details.error')?.remove();
  example.compiled = example.original;
  update(figure);
  setStatus(example);
};

const copy = async (figure, button) => {
  try {
    await navigator.clipboard.writeText(currentCode(figure));
  } catch {
    setStatus(examples.get(figure), 'Could not copy: select the code and copy it by hand.', true);
    announce('Could not copy.');
    return;
  }
  button.classList.add('copied');
  announce('Copied.');
  setTimeout(() => button.classList.remove('copied'), 1500);
};

const base64 = (text) => {
  let binary = '';
  for (const byte of new TextEncoder().encode(text)) binary += String.fromCharCode(byte);
  return btoa(binary);
};

// The project takes our string-diagrams.sty along, in case Overleaf's TeX Live has an older one; a .sty in the project comes before TeX Live's.
const openInOverleaf = (figure) => {
  const main =
    `% This project includes string-diagrams.sty ${data.version}, in case Overleaf's TeX Live has an older one:\n` +
    `% delete it to use Overleaf's own.\n` +
    data.documentHead +
    currentCode(figure) +
    '\n' +
    data.documentTail;
  const form = Object.assign(document.createElement('form'), {
    method: 'POST',
    action: 'https://www.overleaf.com/docs',
    target: '_blank',
  });
  const fields = [
    ['snip_uri[]', `data:application/x-tex;base64,${base64(main)}`],
    ['snip_name[]', 'main.tex'],
    ['snip_uri[]', `data:application/x-tex;base64,${base64(sty)}`],
    ['snip_name[]', 'string-diagrams.sty'],
    ['engine', 'pdflatex'],
    ['main_document', 'main.tex'],
  ];
  for (const [name, value] of fields) form.append(Object.assign(document.createElement('input'), { type: 'hidden', name, value }));
  document.body.append(form);
  form.submit();
  form.remove();
};

// The code of each example becomes editable in place, as plain text, and Compile redraws its picture.
const shortcut = /Mac|iPhone|iPad/.test(navigator.userAgent) ? '⌘+Enter' : 'Ctrl+Enter';
for (const figure of document.querySelectorAll('.example')) {
  const code = figure.querySelector('pre.code');
  try {
    code.contentEditable = 'plaintext-only';
  } catch {
    code.contentEditable = 'true';
  }
  Object.assign(code, { spellcheck: false, tabIndex: 0 });
  code.setAttribute('role', 'textbox');
  code.setAttribute('aria-multiline', 'true');
  code.setAttribute('aria-label', 'LaTeX code of the example, editable');
  code.setAttribute('autocapitalize', 'off');
  code.setAttribute('autocorrect', 'off');

  const compileButton = figure.querySelector('[data-action="compile"]');
  compileButton.title = `Compile the code (${shortcut})`;
  const resetButton = figure.querySelector('[data-action="reset"]');
  const status = figure.querySelector('.status');

  const original = currentCode(figure);
  const picture = figure.querySelector('.picture > *');
  examples.set(figure, { original, compiled: original, alt: picture.getAttribute('alt'), picture, compileButton, resetButton, status, errorOpen: false });

  // TeX starts loading as soon as someone heads for the code or for Compile, so the first compile waits less.
  const preload = () => loadTikzJax().catch(() => {});
  code.addEventListener('focus', preload);
  code.addEventListener('pointerenter', preload, { once: true });
  compileButton.addEventListener('pointerenter', preload, { once: true });
  code.addEventListener('input', () => update(figure));
  code.addEventListener('keydown', (event) => {
    if (event.key === 'Enter' && (event.ctrlKey || event.metaKey)) {
      event.preventDefault();
      enqueue(() => compile(figure));
    }
  });
}

for (const element of document.querySelectorAll('.js-only, .example .tools')) element.hidden = false;

// The showcase becomes tabs: one example shows at a time, and each keeps its edits.
// The address names the tab, as in #mousse, so a link can open a given example.
const showcase = document.querySelector('.showcase');
if (showcase) {
  const tabs = [...showcase.querySelectorAll('[role="tab"]')];
  const nameOf = (tab) => tab.id.replace(/^tab-/, '');
  const select = (tab, focus = false) => {
    for (const other of tabs) {
      const selected = other === tab;
      other.setAttribute('aria-selected', String(selected));
      other.tabIndex = selected ? 0 : -1;
      document.getElementById(other.getAttribute('aria-controls')).classList.toggle('active', selected);
    }
    if (focus) tab.focus();
  };
  const fromAddress = () => tabs.find((tab) => `#${nameOf(tab)}` === location.hash);
  window.addEventListener('hashchange', () => {
    const tab = fromAddress();
    if (tab) select(tab);
  });
  tabs.forEach((tab, i) => {
    tab.addEventListener('click', () => {
      select(tab);
      history.replaceState(null, '', `#${nameOf(tab)}`);
    });
    tab.addEventListener('keydown', (event) => {
      const next = { ArrowRight: i + 1, ArrowLeft: i - 1, Home: 0, End: tabs.length - 1 }[event.key];
      if (next === undefined) return;
      event.preventDefault();
      const target = tabs[(next + tabs.length) % tabs.length];
      select(target, true);
      history.replaceState(null, '', `#${nameOf(target)}`);
    });
  });
  showcase.classList.add('tabbed');
  showcase.querySelector('[role="tablist"]').hidden = false;
  const linked = fromAddress();
  select(linked ?? tabs[0]);
  if (linked) showcase.scrollIntoView();
}

document.addEventListener('click', (event) => {
  const button = event.target.closest('.example [data-action]');
  if (!button || button.getAttribute('aria-disabled') === 'true') return;
  const figure = button.closest('.example');
  const action = button.dataset.action;
  if (action === 'compile') enqueue(() => compile(figure));
  else if (action === 'copy') copy(figure, button);
  else if (action === 'reset') reset(figure);
  else if (action === 'overleaf') {
    if (sty) openInOverleaf(figure);
    else styLoaded.then(() => openInOverleaf(figure));
  }
});
