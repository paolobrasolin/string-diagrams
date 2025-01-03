#!/usr/bin/env bash

WORKDIR=$(mktemp --directory --tmpdir)

cp string-diagrams.sty "$WORKDIR/"
cat <<'EOF' | cat - string-diagrams.dtx >"$WORKDIR/string-diagrams.dtx"
% \iffalse meta-comment
%<*driver>
\RequirePackage{snapshot}
%</driver>
% \fi
EOF

pushd "$WORKDIR" && pdflatex string-diagrams.dtx && popd || exit

cp "$WORKDIR/string-diagrams.dep" string-diagrams.pdf.dep
