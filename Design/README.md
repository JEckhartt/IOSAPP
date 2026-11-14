# App-icoon

Het icoon wordt gegenereerd. Er is geen handwerk in een tekenprogramma.

```sh
python3 make_icon.py                                  # schrijft icon.html
node render_icon.js "$PWD/icon.html" "$PWD/raw.png"   # rendert met Playwright/Chromium
python3 -c "from PIL import Image; Image.open('raw.png').convert('RGB').save('../Gutterlight/Assets.xcassets/AppIcon.appiconset/AppIcon.png')"
```

De laatste stap haalt het alfakanaal weg. Dat is nodig, want App Store-iconen mogen geen transparantie hebben.
