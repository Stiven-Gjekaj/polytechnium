<div align="center">
  <a href="../README.md"><img src="../assets/brand/icon-full.svg" alt="Polytechnium" height="44"></a>
</div>

# Decisions

Each choice of the owner is written here, with its reason. A new choice that
replaces an old one names the old one.

## 2026-10-22: An app for the students of UPT

- Polytechnium is for the students of the Polytechnic University of Tirana.
  The first user is a student of II-A-ELN at the Faculty of Information
  Technology.
- It operates on iPhone and iPad. The lowest version is iOS 17.
- Reason: iOS 17 has the Observation framework and the newer widgets.

## 2026-10-22: Native Swift, with a core package

- The app is native Swift with SwiftUI.
- XcodeGen makes the Xcode project from `project.yml`. The generated project
  is not in the repository.
- The parts that do not need a screen are in the Swift package `PolyCore`.
  They build and test on a Mac with `swift test`, with no simulator.
- Reason: the same form as ZettaStream for iOS. The tests run in seconds.

## 2026-10-22: An unsigned IPA for sideloading

- The app is not in the App Store.
- A tag such as `v0.1.0` builds an unsigned `Polytechnium.ipa` and attaches it
  to a release on GitHub. The SideStore source of the owner shows each release.
- The build signs the app with no identity and with its entitlements. The
  entitlements hold the app group that the widgets need.
- Reason: a sideload tool reads the app group from the entitlements of the
  app, and signs the app again with the account of the user. With no
  signature, the app group is lost.

## 2026-10-22: Version numbers

- The versions start at 0.1.0. Each release before 1.0.0 adds one large
  function: 0.1.0 the import and the timetable, 0.2.0 Today, 0.3.0 the
  widgets, 0.4.0 the grades, 0.5.0 the exams, and 0.6.0 the deadlines.
- 1.0.0 has all of these functions.
- From 1.0.0, a fix raises the patch number, a new function raises the minor
  number, and a change that an older version cannot read raises the major
  number.
- The attendance tracker, the quick links, and the study planner come after
  1.0.0.
- Reason: the owner asked for a release for each large function. The import
  of the PDF is a large function, so it has its own release.

## 2026-10-22: The timetable comes from the PDF of the faculty

- The app reads the timetable PDF of the faculty. The user chooses a group.
- The user enters the credits, the weights of the grades, and the dates of the
  exams in the app. The PDF does not have them.
- A class can change after the import. The user can add, change, and delete a
  class.
- Reason: the faculty gives the timetable as a PDF, and the times of a class
  can change during the semester.

## 2026-10-22: How the reader finds the cells

- The PDF is a spreadsheet that is printed to a PDF. The reader takes the
  thin black rectangles of the page as the borders of the cells.
- A merged cell has no border inside it. A lecture for four groups is one cell
  over four columns, so the lecture goes to each of the four groups.
- The row of column names is the row with "ORA". "ORA" names a column of
  hours, and the groups to its right use these hours. The hours start again at
  the top of each day, from Monday.
- The place of each word comes from a selection of PDFKit, not from
  `characterBounds(at:)`.
- Reason: the fill of the cells does not give the cells. The printer joins the
  fill of two cells of the same colour that are side by side. The bounds of one
  character move away from the text after the first lines of the page.

## 2026-10-22: How the reader reads a cell

- "(L)" is a lecture, and "(S)" is a seminar. The word "lab" makes a lab.
- "tek" is the odd weeks, and "cift" or "çift" is the even weeks.
- A number of three or four digits is a room. "LAB 108" in capitals is a room.
- The first name with an initial, such as "R. Datja" or "L.Likaj", starts the
  lecturer. The words before it are the course.
- A cell can hold two classes, each with its mark.
- A cell with no mark after the same course gets the kind of that course.
- Reason: these are the forms of the timetable of the first semester of
  2026-2027.

## 2026-10-22: Odd and even weeks

- The user chooses if this week is odd or even. The app keeps the Monday of an
  odd week and counts the weeks from it.
- With no choice, the current week is odd.
- Reason: the timetable does not give the first week of the semester.

## 2026-10-22: Two languages

- The text of the app is in English and in Albanian. The key of each text is
  the English text.
- The app uses the language of the device, or the language that the user
  chooses in Settings. A change of the language draws the screens again.
- `scripts/strings.py` writes the English file from the keys in the code. It
  fails when the Albanian file does not have a key. The workflows run it.
- The hours show with 24 hours, as in the timetable.
- Reason: the owner asked for both languages, with a switch in the app.

## 2026-10-22: The data on the device

- All data is in one JSON file in the folder of the app group. The widgets
  read the same file.
- The app has no account, no server, and no analytics.
- Reason: one user keeps one timetable. A file is easy to examine and to back
  up.

## 2026-10-22: The real timetable is not in the repository

- The tests of the reader draw a small timetable into a PDF in the test.
- One more test reads the real timetable from `private/Orari-Bachelor-4.pdf`
  when the file is there. The folder is not in the repository.
- Reason: the real PDF is a draft of the faculty with the names of the
  lecturers. A test must build its own state.
