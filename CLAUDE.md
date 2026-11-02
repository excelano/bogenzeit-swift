# CLAUDE.md

The Swift engine for Bogenzeit, shared by the Apple apps that show it. The standard is excelano/bogenzeit:
`docs/bogenzeit-spec.md` there is normative and no definition in it changes without David, and its
`reference/bz_reference.py` is the only writer of `vectors/bz_vectors.json`. The copy here is replaced
whenever that file regenerates.

## Commands

    swift test    # the engine and the display forms against the vectors, on this box

`BogenzeitUI` needs SwiftUI, so on Linux it compiles empty; it is built for real on the Mac with
`xcodebuild build -scheme Bogenzeit-Package -destination generic/platform=iOS` (and `watchOS`).

## Rules

The engine reproduces the reference step for step, including the declination being taken at solar
noon's UTC hour and minute with the seconds dropped; an engine that is "more accurate" fails the
vectors. Displayed spans and kiloseconds are the floor of the signed value, so an anchor or event
shows only once it has been reached. Position replaces sign: number left of the glyph is before,
right is after, no `+` or `−`. A plain space separates number and glyph. The persisted raw values of
`Scale` and `Precision` are stored by the apps and never change. The `Bogenzeit` target depends on
nothing and runs offline. Don't commit, push or tag unless David asks.
