# GUTTERLIGHT

*Een neo-noir punk riot.* Twin-stick shooter voor iOS: jij bent VEX, het regent,
de neon flikkert en de Suits willen hun straten terug.

## Spelen

- **Linkerduim**: bewegen (de stick verschijnt waar je drukt)
- **Rechterduim**: richten + automatisch vuren
- Kills achter elkaar bouwen een combo op tot **x8**. Word je geraakt, dan is je combo weg.
- Om de 5 waves komt er een Brute. Die laat vaak een stim pack (+1 HP) vallen.

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
Alle graphics worden in code gegenereerd. Er zijn geen assets nodig.

## Structuur

```
Gutterlight/
  App/         SwiftUI-entry + SKView-host
  Game/        GameScene: loop, waves, collisions, score
  Entities/    Player, Enemy, Bullet, Pickup
  UI/          HUD, Joystick, CityBackdrop
  Support/     Palette, FX (procedurele textures/particles), Math
```

## Volgende stappen

- Geluid (synthwave-loop + SFX)
- Dash/dodge-roll
- Meer wapens als pickups
- Baas-wave
- Game Center-leaderboard
- App-icoon
