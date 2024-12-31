module = "string-diagrams"

checkengines = { "pdftex" } --, "xetex", "luatex" }

function update_tag(filename, content, tagname, tagdate)
	content = string.gsub(content, "<VERSION>", tagname)
	content = string.gsub(content, "<DATE>", tagdate)
	return content
end
