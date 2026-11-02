# Bogenzeit for Swift

The Swift engine for Bogenzeit, time read as position on the Sun's arc: spans
from solar noon (☉) or solar midnight (○), a hundred per half-arc, with
kiloseconds as the fixed scale beside them. The standard, its reference
implementation and the test vectors every port passes live at
https://github.com/excelano/bogenzeit; this package is how Apple apps compute
and show a reading.

## What is here

`Bogenzeit` is the engine: solar noon, sunrise, sunset and the solar midnights
for a place and a day, and a `Reading` of any instant on its arc. It also
formats a reading for display in either scale at one of three precisions,
floored toward the past as the standard requires. It depends on nothing,
makes no network request and runs on any platform Swift does.

`BogenzeitUI` draws ☉, ○, △ and ▽ from one SwiftUI definition, because no font
draws the two anchors at matching sizes.

`vectors/bz_vectors.json` is a copy of the standard's file, replaced whenever
the standard regenerates it.

## Using it

Add the package to an Xcode project or a `Package.swift` by its repository URL,
then:

    import Bogenzeit

    let instant = Date(rfc3339: "2026-11-01T17:08:00Z")!
    let reading = Reading(at: instant, latitude: 29.76, longitude: -95.37)
    let shown = DisplayedPosition(reading, scale: .spans, precision: .standard)
    print(shown.text)   // 17.3 ☉

## Testing

    swift test

The tests run the engine against the vectors: event times within a second,
displayed values exact.
