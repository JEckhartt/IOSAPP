# GUTTERLIGHT

*Een neo-noir punk riot.* Twin-stick shooter voor iOS: jij bent VEX, het regent,
de neon flikkert en de Suits willen hun straten terug.

## Spelen

- **Linkerduim**: bewegen (de stick verschijnt waar je drukt)
- **Rechterduim**: richten + automatisch vuren
- Kills achter elkaar bouwen een combo op tot **x8**. Word je geraakt, dan is je combo weg.
- Om de 5 waves komt er een Brute. Die laat altijd een wapen vallen en vaak ook een stim pack (+1 HP).
- Om de 3 waves ligt er na een clear een wapenkrat klaar.

### Wapens

Wapens liggen als draaiende kratten op straat. Is de munitie op, dan val je terug op de SPITTER.

| Krat | Wapen   | Wat het doet                                  | Munitie |
|------|---------|-----------------------------------------------|---------|
| —    | SPITTER | standaardpistool                              | ∞       |
| S    | SCATTER | shotgun, 7 hagels, korte afstand, flinke duw  | 30      |
| Z    | BUZZSAW | SMG, belachelijk snel, wilde spray            | 260     |
| R    | RAILGUN | traag, 4 schade, gaat door alles heen         | 22      |
| X    | BOOMBOX | raketwerper, splash-schade                    | 16      |

| Vijand   | Vorm      | Gedrag                                   |
|----------|-----------|------------------------------------------|
| Suit     | cyaan ◆   | loopt recht op je af                     |
| Hound    | groen ▲   | snel, zigzagt                            |
| Enforcer | amber ⬢   | houdt afstand en schiet terug            |
| Brute    | rood ⯃    | traag, kan veel hebben, laat de grond trillen |

## Bouwen

Vereisten: macOS met Xcode 15+ en [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate
open Gutterlight.xcodeproj
```

Kies je team onder *Signing & Capabilities* en run op een iPhone of iPad, in landscape.
Alle graphics én audio worden in code gegenereerd: een synthwave-loop van 8 maten
in A-mineur (100 BPM) en 13 geluidseffecten, gerenderd bij het opstarten. Er zijn geen assets nodig.
De audiosessie staat op `.ambient`, dus de stilteknop wordt gerespecteerd.

## Structuur

```
Gutterlight/
  App/         SwiftUI-entry + SKView-host
  Audio/       Synth (oscillators, SFX, muziek) + AVAudioEngine-player
  Game/        GameScene: loop, waves, collisions, score · Weapon
  Entities/    Player, Enemy, Bullet, Pickup
  UI/          HUD, Joystick, CityBackdrop
  Support/     Palette, FX (procedurele textures/particles), Math
```

## Volgende stappen

- Dash/dodge-roll
- Instellingen (muziek/SFX aan/uit)
- Baas-wave
- Game Center-leaderboard
- App-icoon
