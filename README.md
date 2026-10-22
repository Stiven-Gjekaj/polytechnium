<div align="center">

<img src="assets/brand/icon-full.svg" alt="Polytechnium" width="160">

### Your timetable, grades, exams, and deadlines at the Polytechnic University of Tirana

_For the students of FTI, with the timetable from the PDF of the faculty_

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17%2B-000000?style=for-the-badge&logo=apple&logoColor=white" alt="iOS 17 or newer"/>
  <img src="https://img.shields.io/badge/Swift-SwiftUI-000000?style=for-the-badge&logo=swift&logoColor=white" alt="Swift and SwiftUI"/>
</p>

<p align="center">
  <a href="https://github.com/Stiven-Gjekaj/polytechnium/releases/latest"><img src="https://img.shields.io/github/v/release/Stiven-Gjekaj/polytechnium?style=for-the-badge&color=ffffff&labelColor=000000&label=Download" alt="Download the newest release"/></a>
  <a href="https://ko-fi.com/stivengjekaj"><img src="https://img.shields.io/badge/Ko--fi-Support_this_project-000000?style=for-the-badge&logo=ko-fi&logoColor=white" alt="Support this project on Ko-fi"/></a>
</p>

<p align="center">
  <a href="https://github.com/Stiven-Gjekaj/polytechnium/actions/workflows/ci.yml"><img src="https://github.com/Stiven-Gjekaj/polytechnium/actions/workflows/ci.yml/badge.svg" alt="CI"/></a>
  <img src="https://img.shields.io/badge/license-MIT-black?style=flat-square" alt="MIT License"/>
</p>

</div>

---

## Overview

**Polytechnium** is an iPhone and iPad app for the students of the
Polytechnic University of Tirana (UPT). It reads the timetable PDF of the
Faculty of Information Technology and keeps the classes of your group, such
as II-A-ELN. It is not an app of the university.

The app has the text in English and in Albanian. Your data stays on your
device.

## Features

- Import the timetable PDF of the faculty. The app finds each group, and you
  choose yours. A lecture for many groups goes to each of them
- The kind of each class (lecture, seminar, or lab), the room, the lecturer,
  and the weeks: every week, the odd weeks (tek), or the even weeks (cift)
- Change, add, and delete a class, when a class moves to a new time or room
- Choose if this week is odd or even. The app counts the next weeks
- Today: the class that is on now and the time that is left, the next
  class, and the rest of the day
- Widgets: "Next class" with the room and the time, on the home screen and
  the lock screen
- Grades: the credit-weighted average on the scale from 4 to 10, and a
  what-if mode that gives the points that the final needs for a grade
- English or Albanian, or the language of the device

The next releases add the exam countdown and the deadlines. See
[TODO.md](TODO.md).

## Install

Polytechnium is not in the App Store.

**With SideStore or AltStore:** add this source one time. The app then gets
each update from it.

```
https://stiven-gjekaj.github.io/sidestore-source/apps.json
```

**By hand:** each release has an unsigned `Polytechnium.ipa`. Sign and install
it with one of these tools:

- [AltStore](https://altstore.io) or [SideStore](https://sidestore.io)
- [Sideloadly](https://sideloadly.io)
- [TrollStore](https://github.com/opa334/TrollStore), on a version of iOS
  that it supports

The widgets need the app group of the app. AltStore and SideStore register
it. With a free Apple account, the widget extension uses one more of the
three app IDs of the week.

The newest IPA is always at this URL:

```
https://github.com/Stiven-Gjekaj/polytechnium/releases/latest/download/Polytechnium.ipa
```

## Import your timetable

1. Download the timetable PDF of the faculty, such as `Orari-Bachelor.pdf`,
   to the Files app.
2. In Polytechnium, open Timetable, tap the plus button, and tap Import a PDF.
3. Choose the PDF, then your group.
4. Look at the classes and tap Save.

A new PDF of the faculty replaces the classes of your group. Import it again
when the faculty changes the timetable.

## Project structure

```
App/Sources/
  Model/        the app model, which reads and writes the data
  Navigation/   the tabs
  Screens/      the screens
  Components/   the buttons, the chips, and the other parts of a screen
  Theme/        the colours and the font, from ZettaStream
Widgets/        the widget extension
Shared/         the code and the text that the app and the widgets share
PolyCore/       the parts that do not need a screen, with their tests
  Sources/PolyCore/
    Import/     the reader of the timetable PDF
    Timetable/  the classes, the weeks, and the current and next class
    Grades/     the grades, the points that a grade needs, and the average
    Store/      the data file
assets/brand/   the icon
docs/           the reason behind each choice
scripts/        the build of the IPA and the check of the text
project.yml     the XcodeGen project
```

## Building

You need Xcode 16 or newer and XcodeGen.

```
brew install xcodegen
git clone https://github.com/Stiven-Gjekaj/polytechnium
cd polytechnium
./scripts/build-ipa.sh
```

The IPA is in `build/`. To work in Xcode, run `xcodegen` and open
`Polytechnium.xcodeproj`.

A tag such as `v0.1.0` makes the workflow build the IPA and attach it to a
release.

## Testing

```
swift test --package-path PolyCore
python3 scripts/strings.py --check
```

The unit tests of the core package cover the reader of the timetable PDF, the
weeks, and the data file. The tests of the reader draw a small timetable into
a PDF in the test. When a copy of the real timetable is at
`private/Orari-Bachelor-4.pdf`, one more test reads it. The `private/` folder
is not in the repository. The text check makes sure that each English text
has an Albanian text.

## Documentation

- [docs/decisions.md](docs/decisions.md): each choice and its reason
- [CHANGELOG.md](CHANGELOG.md): what changed, and when
- [TODO.md](TODO.md): the next releases
- [AGENTS.md](AGENTS.md): the rules for an agent that works here

## License

MIT. See [LICENSE](LICENSE). Karla is under the SIL Open Font License, in
[licenses/](licenses/Karla-OFL.txt).
