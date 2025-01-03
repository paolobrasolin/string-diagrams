#!/usr/bin/env bash

WORKDIR=$(mktemp --directory --tmpdir)

cp string-diagrams.sty "$WORKDIR/"
cat <<'EOF' >"$WORKDIR/string-diagrams.sty.tex"
\RequirePackage{snapshot}
\RequirePackage{string-diagrams}
\let\normalsize\relax
\begin{document}\end{document}
EOF

pushd "$WORKDIR" && latex -interaction=batchmode string-diagrams.sty.tex && popd || exit

cp "$WORKDIR/string-diagrams.sty.dep" .
