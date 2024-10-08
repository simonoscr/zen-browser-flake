#!/usr/bin/env -S nix shell nixpkgs#jq -c bash

set -euo pipefail

info="info.json"
oldversion=$(jq -rc '.version' "$info")

url="https://api.github.com/repos/zen-browser/desktop/releases/latest"
version="$(curl -s "$url" | jq -rc '.tag_name')"

if [ "$oldversion" != "$version" ]; then
  echo "Found new version $version"
  sharedUrl="https://github.com/zen-browser/desktop/releases/download"

  genericUrl="${sharedUrl}/${version}/zen.linux-generic.tar.bz2"
  specificUrl="${sharedUrl}/${version}/zen.linux-specific.tar.bz2"

  # perform downloads in parallel
  echo "Prefetching files..."
  nix store prefetch-file "$genericUrl" --log-format raw --json | jq -rc '.hash' >/tmp/genericHash &
  nix store prefetch-file "$specificUrl" --log-format raw --json | jq -rc '.hash' >/tmp/specificHash &
  wait
  genericHash=$(</tmp/genericHash)
  specificHash=$(</tmp/specificHash)

  echo '{"version":"'"$version"'","generic":{"hash":"'"$genericHash"'","url":"'"$genericUrl"'"},"specific":{"hash":"'"$specificHash"'","url":"'"$specificUrl"'"}}' >"$info"
else
  echo "zen is up to date"
fi
