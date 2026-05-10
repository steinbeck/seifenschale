# Seifenschale

Wandmontierte 3D-druckbare Seifenschale aus drei Teilen, geklebt mit einem Tesa-Powerstrip Large an Badezimmerfliesen. Schale und Abtropfgitter sind herausnehmbar zum Reinigen.

![Zusammengebaut](build/assembled.png)

## Teile

![Explosionsdarstellung](build/explosion.png)

1. **Wandhalterung** — Wandplatte mit Klebefläche für den Powerstrip, Steg, offener Rahmen.
2. **Schale** — flache Wanne mit Krempenrand. Liegt von oben auf dem Rahmen auf.
3. **Abtropfgitter** — Längsstabgitter mit vier Füßchen, hält die Seife mit 2 mm Luftspalt über dem Schalenboden.

## Druckhinweise

- **Filament:** PLA
- **Layer-Höhe:** 0,2 mm
- **Düse:** 0,4 mm
- **Brim:** für die Wandhalterung empfohlen (schmale Wandplatten-Auflage)
- **Support:** nicht nötig — alle Teile sind so designed, dass sie support-frei drucken
- **Gitter:** wird **kopfüber** gedruckt — die exportierte `gitter.stl` enthält bereits die richtige Pose

![Druck-Layout](build/print.png)

Die kombinierte `print.stl` legt alle drei Teile nebeneinander (~330 mm gesamt). Für Druckbetten kleiner als 350 mm pro Teil eine eigene Datei verwenden (`wandhalterung.stl`, `schale.stl`, `gitter.stl`).

## Bauen

```bash
make            # alle Renderings + alle STLs
make renders    # nur die 3 PNGs
make stls       # nur die 4 STLs
make check      # Bounding-Box-Prüfung
make clean      # build/ löschen
```

## Anpassen

Alle Maße sind als benannte Konstanten am Anfang von `seifenschale.scad` definiert. Tesa-Powerstrip-Größe, Schalenmaß, Wandstärken und Toleranzen können dort einzeln angepasst werden — abgeleitete Maße (z.B. Krempenrand, Schalen-Innenmaß, Gitter-Außenmaß) ziehen sich automatisch nach.

OpenSCAD-Customizer unterstützt zwei Top-Level-Variablen:

- `mode` — `assembled`, `explosion`, oder `print`
- `part` — `all`, `wandhalterung`, `schale`, oder `gitter` (nur im Print-Mode relevant)

## Lizenz

MIT — siehe [LICENSE](LICENSE).
