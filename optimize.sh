#!/usr/bin/env bash
# From https://guide.elm-lang.org/optimization/asset_size.html
set -e

js="app.js"
min="public/app.min.js"

elm make --optimize --output=$js "$@"

mkdir -p public
uglifyjs $js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output $min

echo "Compiled size: $(wc $js -c) bytes  ($js)"
echo "Minified size: $(wc $min -c) bytes  ($min)"
echo "Gzipped size:  $(gzip $min -c | wc -c) bytes"

npm run css-build:prod

mkdir -p public/img public/pdf
cp -r img/128px_v2 public/img/
cp -r pdf public/
cp img/favicon.ico img/Esperas_Comunes_Mahjong.png public/img/

sed "s#../css/app.css#app.min.css#; s/app.js/app.min.js/; s/YOUR_PROJECT_ID/$SWETRIX_PROJECT_ID/; s/disabled: *true/disabled: false/" index.html > public/index.html

echo "google-site-verification: google$GOOGLE_SITE_VERIFICATION.html" > "public/google$GOOGLE_SITE_VERIFICATION.html"

cat << EOF > "public/BingSiteAuth.xml"
<?xml version="1.0"?>
<users>
	<user>$BING_SITE_VERIFICATION</user>
</users>
EOF