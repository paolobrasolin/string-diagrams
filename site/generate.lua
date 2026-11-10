-- Generates the project site from a finished `l3build doc` run.
--
--   texlua site/generate.lua <l3build build dir> <output dir> [<version>]
--
-- The page shows the examples of site/showcase, rendered to SVG with dvisvgm, as tabs.
-- llms.txt has them too, along with the examples of the manual, which the build dir holds
-- as string-diagrams-example-<name>.tex.

local build_dir, out_dir, version = arg[1], arg[2], arg[3] or "dev"
if not (build_dir and out_dir) then
  io.stderr:write("usage: texlua site/generate.lua <l3build build dir> <output dir> [<version>]\n")
  os.exit(2)
end

local SITE_URL = "https://paolobrasolin.github.io/string-diagrams/"
-- NOTE: pictures are shown at this multiple of their size in TeX, both as rendered here and as compiled in the browser.
local SCALE = 2

local site_dir = arg[0]:match("^(.*)/[^/]*$") or "."

local function fail(message, ...)
  io.stderr:write("site/generate.lua: ", string.format(message, ...), "\n")
  os.exit(1)
end

local function absolute(path)
  return path:sub(1, 1) == "/" and path or lfs.currentdir() .. "/" .. path
end

local function read(path)
  local file = io.open(path, "rb") or fail("can't read %s", path)
  local content = file:read("a")
  file:close()
  return content
end

local function write(path, content)
  local file = io.open(path, "wb") or fail("can't write %s", path)
  file:write(content)
  file:close()
end

local function quote(text)
  return "'" .. text:gsub("'", "'\\''") .. "'"
end

-- NOTE: LuaTeX's os.execute returns the exit status, where plain Lua 5.3 returns true or nil.
local function run(directory, command)
  local status = os.execute("cd " .. quote(directory) .. " && " .. command)
  if status ~= 0 and status ~= true then fail("this failed in %s: %s", directory, command) end
end

local function escape_html(text)
  return (text:gsub("[&<>\"]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;" }))
end

local function json_string(text)
  local escaped = text:gsub('[%c"\\]', function(c)
    local named = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\t"] = "\\t" }
    return named[c] or string.format("\\u%04x", c:byte())
  end)
  -- NOTE: the data goes inside a <script> element, which a literal "</" could close.
  return '"' .. escaped:gsub("</", "<\\/") .. '"'
end

-- The manual indents its examples, so strip the indentation they share, and blank lines around them.
local function dedent(text)
  local lines, indent = {}, math.huge
  for line in (text:gsub("%s+$", "") .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
    if line:find("%S") then indent = math.min(indent, #line:match("^ *")) end
  end
  for i, line in ipairs(lines) do lines[i] = line:sub(indent + 1) end
  return (table.concat(lines, "\n"):gsub("^\n+", "")) .. "\n"
end

local preamble = read(site_dir .. "/preamble.tex")
local document_head = "\\documentclass{standalone}\n\\usepackage{string-diagrams}\n" .. preamble .. "\\begin{document}\n"
local document_tail = "\\end{document}\n"

local sty_path = build_dir .. "/unpacked/string-diagrams.sty"
local sty = read(sty_path)
-- NOTE: the playground pastes the package into the preamble (see playground.js), where \endinput would end the whole input.
if sty:find("\\endinput") then fail("%s has \\endinput, which breaks the playground", sty_path) end

local work_dir = absolute(build_dir .. "/site")
out_dir = absolute(out_dir)
for _, dir in ipairs({ work_dir, out_dir, out_dir .. "/examples" }) do lfs.mkdir(dir) end
write(work_dir .. "/string-diagrams.sty", sty)
write(work_dir .. "/preamble.tex", preamble)

local function fill_variables(text)
  return (text:gsub("{{([%w_]+)}}", { version = version, site_url = SITE_URL }))
end

local showcase = {}
for file in lfs.dir(site_dir .. "/showcase") do
  local name = file:match("^([%w%-]+)%.tex$")
  if name then
    local body = dedent(read(site_dir .. "/showcase/" .. file))
    write(work_dir .. "/" .. name .. ".tex", document_head .. body .. document_tail)
    write(work_dir .. "/body-" .. name .. ".tex", body)
    run(work_dir, string.format(
      "latex -interaction=nonstopmode -halt-on-error -jobname=%s %s > /dev/null || { grep -A 5 '^!' %s.log; exit 1; }",
      name, quote("\\def\\pgfsysdriver{pgfsys-dvisvgm.def}\\input{" .. name .. ".tex}"), name))
    local svg_path = out_dir .. "/examples/" .. name .. ".svg"
    run(work_dir, string.format("dvisvgm --no-fonts --exact-bbox --verbosity=1 --output=%s %s.dvi", quote(svg_path), name))
    local width, height = read(svg_path):match("<svg[^>]- width=['\"]([%d.]+)pt['\"] height=['\"]([%d.]+)pt['\"]")
    if not width then fail("can't find the size of %s", svg_path) end
    showcase[name] = {
      body = body,
      width = math.floor(width * 4 / 3 * SCALE + 0.5),
      height = math.floor(height * 4 / 3 * SCALE + 0.5),
    }
  end
end

-- The page lists the showcase in a comment, one example per line: <name> | <tab> | <caption> | <alt text>.
-- The caption is HTML, for links; llms.txt gets it as Markdown.
local index = read(site_dir .. "/index.html"):gsub("^(<!doctype html>\n)<!%-%-.-%-%->\n", "%1")
local items = {}
local listed = {}
for line in (index:match("<!%-%- showcase\n(.-)%-%->") or fail("index.html has no showcase")):gmatch("[^\n]+") do
  if line:find("%S") then
    local name, tab, caption, alt = line:match("^%s*([%w%-]+)%s*|%s*(.-)%s*|%s*(.-)%s*|%s*(.-)%s*$")
    if not name then fail("can't read this showcase line of index.html: %s", line) end
    if not showcase[name] then fail("index.html shows %s, which site/showcase doesn't have", name) end
    items[#items + 1] = { name = name, tab = tab, caption = caption, alt = alt }
    listed[name] = true
  end
end
for name in pairs(showcase) do
  if not listed[name] then fail("index.html doesn't show site/showcase/%s.tex", name) end
end

local tabs, panels = {}, {}
for i, item in ipairs(items) do
  local example = showcase[item.name]
  tabs[i] = string.format(
    '<button type="button" role="tab" id="tab-%s" aria-controls="panel-%s" aria-selected="%s" tabindex="%d">%s</button>',
    item.name, item.name, i == 1 and "true" or "false", i == 1 and 0 or -1, escape_html(item.tab))
  panels[i] = string.format([[<section class="panel" id="panel-%s" role="tabpanel" aria-labelledby="tab-%s">
<figure class="example" id="example-%s">
  <figcaption class="caption">%s</figcaption>
  <pre class="code"><code>%s</code></pre>
  <div class="picture"><img src="examples/%s.svg" width="%d" height="%d" alt="%s"></div>
  <div class="tools" hidden>
    <button type="button" data-action="compile" aria-disabled="true">Compile</button>
    <button type="button" data-action="reset" aria-disabled="true">Reset</button>
    <span class="status"></span>
    <span class="end">
      <button type="button" data-action="copy"><span>Copy to clipboard</span><span>Copied</span></button>
      <button type="button" data-action="overleaf">Open in Overleaf</button>
    </span>
  </div>
</figure>
</section>]], item.name, item.name, item.name, item.caption, escape_html(example.body:gsub("\n$", "")),
    item.name, example.width, example.height, escape_html(item.alt))
end

local site_data = string.format(
  '{"version": %s, "sty": "string-diagrams.sty", "preamble": %s, "documentHead": %s, "documentTail": %s, "scale": %s}',
  json_string(version), json_string(preamble), json_string(document_head), json_string(document_tail), SCALE)

index = index
  :gsub("<!%-%- showcase\n.-%-%->", function()
    return '<div class="tablist" role="tablist" aria-label="Examples" hidden>' .. table.concat(tabs)
      .. '</div>\n<div class="panels">\n' .. table.concat(panels, "\n") .. "\n</div>"
  end)
  :gsub("{{site_data}}", function() return site_data end)
write(out_dir .. "/index.html", fill_variables(index))

-- llms.txt has the showcase, then the examples of the manual in the order they appear in it.
local manual = {}
for name in read(site_dir .. "/../string-diagrams.dtx"):gmatch("\\begin{tcblisting}{example=([%w%-]+)") do
  local title = name:gsub("%-", " "):gsub("^%l", string.upper)
  manual[#manual + 1] = "### " .. title .. "\n\n```latex\n"
    .. dedent(read(build_dir .. "/doc/string-diagrams-example-" .. name .. ".tex")) .. "```\n"
end
if #manual == 0 then fail("string-diagrams.dtx has no named examples") end
local showcased = {}
for i, item in ipairs(items) do
  local caption = item.caption:gsub('<a href="(.-)">(.-)</a>', "[%2](%1)"):gsub("<.->", "")
  showcased[i] = "### " .. item.tab .. "\n\n" .. caption .. "\n\n```latex\n" .. showcase[item.name].body .. "```\n"
end
local llms = read(site_dir .. "/llms.txt")
  :gsub("<!%-%- showcase %-%->", function() return table.concat(showcased, "\n") end)
  :gsub("<!%-%- manual examples %-%->", function() return table.concat(manual, "\n") end)
write(out_dir .. "/llms.txt", fill_variables(llms))

-- The preview image for social media shows the bialgebra law (see og.tex).
write(work_dir .. "/og.tex", read(site_dir .. "/og.tex"))
run(work_dir, "pdflatex -interaction=nonstopmode -halt-on-error og.tex > /dev/null || { grep -A 5 '^!' og.log; exit 1; }")
run(work_dir, "pdftocairo -png -singlefile -scale-to-x 1200 -scale-to-y 630 og.pdf " .. quote(out_dir .. "/og"))

write(out_dir .. "/string-diagrams.sty", sty)
write(out_dir .. "/string-diagrams.pdf", read(build_dir .. "/doc/string-diagrams.pdf"))
for _, file in ipairs({ "style.css", "playground.js", "favicon.svg" }) do
  write(out_dir .. "/" .. file, read(site_dir .. "/" .. file))
end
