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

## 2026-10-22: The widget

- One widget, "Next class", has five sizes: small and medium on the home
  screen, and rectangular, inline, and circular on the lock screen.
- It shows the class that is on, or else the next class. The medium size also
  shows the class after it.
- The timeline has an entry at each start and end of a class in the next day,
  so that the widget changes with no request to the app.
- The widget reads the data file in the folder of the app group.
- A simulator build signs with no identity, so that the app group works in
  the simulator too.
- Reason: the owner asked for "Next class: Elektroteknika II, room X, 10:00"
  on the home screen and the lock screen.

## 2026-10-22: The data file moves into the app group

- When the folder of the app group has no data file and the documents of the
  app have one, the app moves the file into the folder of the group.
- Reason: a build with no app group keeps the file in the documents. The
  widget cannot read the documents of the app.

## 2026-10-22: The grades

- Each part of a course has a weight in percent and points from 0 to 100.
  The points of the course are the sum of each part in its share.
- The points give the grade with the scale of the universities of Albania:
  91 points give 10, 81 give 9, 71 give 8, 61 give 7, 51 give 6, and 41 give 5.
  Less than 41 points gives 4.
- When the weights do not give 100%, each part counts in its share of the sum.
- A grade that the faculty gives takes the place of the grade from the points.
- The average counts each passed course, with a grade of 5 or more, by its
  credits. A failed course and a course with no grade are not in it.
- The what-if mode gives the average that the parts with no points need for a
  grade. It says when the points give the grade already, and when the grade is
  not possible.
- Reason: the owner asked for a credit-weighted average on the scale from 4
  to 10 and the points that the final needs for a grade. If the faculty uses
  another scale, the scale is one value in the data file.

## 2026-10-22: The reminders of an exam

- An exam has reminders at 18:00 one week, three days, and one day before.
- The app asks for the permission to send notifications when you save the
  first exam with reminders.
- At each start and each change, the app removes its reminders and asks for
  the reminders of the plan again. The plan keeps the first 60.
- Reason: the owner asked for reminders a week, three days, and the day
  before. An evening reminder gives time to revise. iOS keeps only 64 local
  notifications of an app.

## 2026-10-22: The deadlines

- A deadline has reminders one day and two hours before its time.
- A deadline that is handed in has no reminders.
- The exams and the deadlines share one plan of at most 60 reminders, in the
  order of their time.
- Reason: the owner asked for lab reports and assignments with local
  notifications. Two hours give time to hand in.

## 2026-10-22: Five tabs

- The tabs are Today, Timetable, Grades, Exams, and Deadlines.
- Settings opens from the gear button at the top of Today.
- Reason: on an iPhone, a sixth tab goes behind a "More" tab. Settings is the
  screen that a user opens least.

## 2026-10-22: The backup

- The backup is the data file, in one JSON file that the user saves with the
  Files app.
- A restore puts the data of the backup in the place of all data, after a
  question.
- A backup with a form newer than the app does not restore.
- Reason: the data stays on the device, so the user needs a way to move it to
  a new phone. A restore of a newer form would lose the parts that the older
  app does not know.

## 2026-10-22: The check for a newer version

- Settings asks the GitHub API for the newest release of the app. When it is
  newer, Settings shows its version with a link to the release.
- The app does not install the update. SideStore or AltStore gets it from the
  source.
- Reason: the same function as ZettaStream for iOS. A sideloaded app has no
  App Store to tell of an update.

## 2026-10-22: What 1.0.0 has

- 1.0.0 has the import, the timetable, Today, the widget, the grades, the
  exams, and the deadlines, with a backup and a check for a newer version.
- The checks of the simulator cover each screen in English and in Albanian,
  the import of the real timetable, the widget on the home screen, the
  backup and the restore, and the question for notifications.
- These checks need a real iPhone and are in the roadmap: the widget on the
  lock screen, a notification at its time, and the import of a PDF from the
  Files app.
- Reason: the owner asked for 1.0.0 with all the functions of the first list.
  The second list comes after 1.0.0.

## 2026-10-22: Releases after 1.0.0

- Each function of the second list has its own release: 1.1.0 the
  attendance, 1.2.0 the quick links, and 1.3.0 the study planner.
- 2.0.0 has all of them, with Today as the place that joins them.
- Reason: the owner asked for a release for each function, up to 2.0.0.

## 2026-10-22: The attendance

- The student marks each class as attended or missed, on the page of the
  course.
- The classes of the semester come from the timetable: each class of a week
  counts one time each week, and a class of the odd or the even weeks counts
  in half of the weeks. The semester has 15 weeks by default.
- The required part is 75% for each course by default. The student can
  change it for each course.
- Reason: the rule of attendance is not the same for each course, and the
  PDF does not give it. The page tells the student how many classes are left
  to miss.

## 2026-10-22: The quick links

- A quick link is a web page or a file. The app copies a file into a folder
  next to the data file, with a new name, so that two files with the same
  name do not replace each other.
- An address with no scheme gets "https://". The app takes only http and
  https.
- The backup has the web links, but not the files.
- Reason: a link to Moodle or to a drive works on each device. A PDF can be
  large, and the backup stays one small file.

## 2026-10-22: The study plan

- An exam has its hours of revision, 10 by default. The revision starts 7
  days before the exam and ends on the day before it. A day has at most 3
  hours. The user can change the three numbers.
- The exams come in the order of their dates. Each exam spreads its hours
  over its days, in half hours, with no more than the free time of each day.
  A second pass gives the hours that are left to the days with free time.
- The hours that the user marked as done before today count. The plan of
  today and the next days spreads the rest again each day.
- Reason: an exam that comes first needs its revision first. A plan that
  changes with the hours that are done stays true when a day goes wrong.

## 2026-10-22: Form 2 of the data

- 2.0.0 writes the data in form 2. Form 2 has the attendance, the quick
  links, and the study plan.
- The app reads the data of form 1 into form 2. A backup of form 2 does not
  restore in an app of form 1.
- Reason: an app of form 1 does not know the new parts. A restore there would
  lose them with no word. This change raises the major number.

## 2026-10-22: Today joins the functions

- Today asks about the attendance of each class of the day that is over and
  has no mark of the same course, kind, and day.
- Today shows the revision of the day from the study plan.
- The revision of each day of the plan has a reminder at 17:00.
- Reason: Today is the screen that the student opens each day. A question at
  the end of the day is faster than a visit to the page of each course.
