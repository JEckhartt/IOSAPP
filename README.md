# GUTTERLIGHT

*Een neo-noir punk riot.* Twin-stick shooter voor iOS: jij bent VEX, het regent,
de neon flikkert en de Suits willen hun straten terug.

## Spelen

### Startmenu

- **PLAY**: start bij wave 1
- **HIGH SCORES**: top 10, met wave, moeilijkheid en datum
- **UNLOCKS**:
  - *Upgrade points*: elke overleefde wave levert 1 punt op. Elk punt geeft de SPITTER +1 damage (je kunt het terugdraaien met −). Ontgrendelt na je eerste overleefde wave.
  - *Extra lives*: elke baas die je voor het eerst verslaat geeft permanent +1 max HP. Zet je dit aan, dan begin je met meer levens; uit kan ook.
- **DIFFICULTY**: slider van −100% tot +100% in stappen van 10%. Dit schaalt het aantal vijanden en hun HP (25%–200%) en hun snelheid, kogelsnelheid en vuurtempo (50%–150%).
- **DEVELOPER**: god mode en direct naar elke baas springen. Dev-runs tellen niet mee voor highscores en unlocks.
- **?**: uitleg over het spel

- **Linkerduim**: bewegen (de stick verschijnt waar je drukt)
- **Rechterduim**: richten + automatisch vuren (met lichte aim assist)
- Trek je duim verder dan de stick, dan schuift de stick mee
- Kills achter elkaar bouwen een combo op tot **x8**. Word je geraakt, dan is je combo weg.
- Om de 5 waves komt er een Brute. Die laat altijd een wapen vallen en vaak ook een stim pack (+1 HP).
- Om de 3 waves ligt er na een clear een wapenkrat klaar.

### Bazen

Elke 10e wave komt er een baas, met een levensbalk en drie fases (bij 66% en 33% HP wordt hij sneller en agressiever).
Na wave 100 begint de rij opnieuw, elke ronde taaier.

| Wave | Baas               | Stijl                                          |
|------|--------------------|------------------------------------------------|
| 10   | THE MIDDLE MANAGER | achtervolgt, ringen + waaiers, roept Suits     |
| 20   | KENNEL MASTER      | dashes, roept Hounds                           |
| 30   | RIOT CAPTAIN       | salvo's van 3, roept Enforcers                 |
| 40   | THE BULLDOZER      | groot, chargeert, dichte schokgolven           |
| 50   | SPIN DOCTOR        | spiralen                                       |
| 60   | THE AUDITOR        | teleporteert en barst uit                      |
| 70   | BIG BROTHER        | volgt je met een kogelstroom                   |
| 80   | THE LOBBYIST       | grote waaiers, koopt versterking in            |
| 90   | THE BOARD          | 6–8-armige spiralen, streams                   |
| 100  | THE CHAIRMAN       | alles tegelijk                                 |

### Wapens

Wapens liggen als draaiende kratten op straat. Is de munitie op, dan val je terug op de SPITTER.

| Krat | Wapen   | Wat het doet                                     | Munitie |
|------|---------|--------------------------------------------------|---------|
| —    | SPITTER | standaardpistool                                 | ∞       |
| S    | SCATTER | shotgun, 10 hagels à 2 schade, gooit ze omver    | 45      |
| Z    | BUZZSAW | SMG, 25 schoten/s à 2 schade                     | 400     |
| R    | RAILGUN | 10 schade, gaat door alles heen                  | 35      |
| X    | BOOMBOX | raketten, 10 splash-schade in een grote straal   | 25      |

Pak je hetzelfde wapen nog een keer op, dan stapelt de munitie (tot 2× de normale hoeveelheid).

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
