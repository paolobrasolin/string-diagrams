module = "string-diagrams"

checkengines = { "pdftex" } --, "xetex", "luatex" }

-- NOTE: CTAN maintainers prefer a flat upload (no TDS zip) for simple packages.
packtdszip = false

tagfiles = { "*.dtx", "*.ins" }

-- NOTE: listed explicitly so no other Markdown file ends up on CTAN by accident.
textfiles = { "README.md", "CHANGELOG.md" }

-- NOTE: this makes the PDF reproducible, along with SOURCE_DATE_EPOCH and FORCE_SOURCE_DATE (see https://texdoc.org/serve/pdftex-a.pdf/0)
typesetcmds = "\\pdftrailerid{}"

function update_tag(filename, content, tagname, tagdate)
	content = string.gsub(content, "<VERSION>", tagname)
	content = string.gsub(content, "<DATE>", (string.gsub(tagdate, "-", "/")))
	return content
end

-- NOTE: `l3build upload <version>` validates the upload with CTAN, then asks before submitting it.
uploadconfig = {
	author = "Paolo Brasolin",
	uploader = "Paolo Brasolin",
	email = "paolo.brasolin@gmail.com",
	license = "lppl1.3c",
	summary = "Create string diagrams with LaTeX and TikZ",
	ctanPath = "/graphics/pgf/contrib/string-diagrams",
	home = "https://github.com/paolobrasolin/string-diagrams",
	repository = "https://github.com/paolobrasolin/string-diagrams",
	bugtracker = "https://github.com/paolobrasolin/string-diagrams/issues",
}
