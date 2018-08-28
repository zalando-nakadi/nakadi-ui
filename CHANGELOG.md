# Change Log
All notable changes to `Nakadi UI` will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.0.0] 2018-08-28
### Added
- Users now can publish batches of events directly from Event Type details page.
- Added full support of the [subscription authorization](https://nakadi.io/manual.html#definition_Subscription*authorization).
- Added support for the event type [audience](https://nakadi.io/manual.html#definition_EventType*audience) field.
- Added support for the event type [cleanup_policy](https://nakadi.io/manual.html#definition_EventType*cleanup_policy) field.
- Added support for the event type [ordering_key_fields](https://nakadi.io/manual.html#definition_EventType*ordering_key_fields) field.
- Added a configuration for Scalyr request filter.
- Added Dockerfile and docker-compose

### Changed
- Nakadi UI is open-sourced and moved to github.com. All internal links updated.

### Fixed
- Updated minor versions of all dependencies to fix security audit npm warnings.

## [0.0.23] 2018-06-19
### Added
- Added the link to the user profile.
- Added the `Copy to clipboard` button for events and schemas.
- Show the Subscription partitions lag and assignment type.

### Changed
- It is now possible to change `owning_application`.
- The maximum partitions number was changed to 32.
- UI now shows the `loading` label for total events count calculation.

### Fixed
- Fix unintended "jump back" to the previous page.
- Fixed a typo in a Event Type validation error message.
- Fixed a typo in the Event Type Details page.
- Fixed constant reloading when user is logout.

## [0.0.22] 2017-11-27
### Added
- Added the Effective schema switch to the Event Type details page.
- Added unique page titles for each page to make browser history and bookmarks more useful.

### Changed
- The Event Type category can be changed from "undefined" to "business".
- The JSON viewer adds invisible double quote symbols around keys so that JSON can be easily copy/pasted.
- The description of the Avoid Versioning check changed.

## [0.0.21] 2017-11-18
### Added
- Added the Clone Subscription button to the Subscription Details page.
- Added robots.txt to prevent Nakadi UI from appearing in search results.
- Added server endpoint to get the validation report for all Event Types.

### Changed
- The design of pagination on the Inspect Events page.
- Icons now use Font Awesome 5.
- Maximum number or partitions changed to 20 on the Create Event type form.
- The validation check changed to allow an Event Type to have READ permission for all.
- Partition IDs sorted as numbers if possible.

### Fixed
- Fixed the validation check that checks the existing properties in the schema.
- Fixed resetting the Event Types Clone form on a browser refresh.
- Fixed the broken layout for a long even type names in the Last Updated Event Types list.

## [0.0.20] 2017-11-04
### Added
- Added Event Type configuration validation API.
- Added Event Type configuration quality notification panel on the Event Type Details page.

### Fixed
- Fixed Update or Clone in UI for the retention time less then 2 or more than 4 days.

## [0.0.19] 2017-10-05
### Added
- Added the tool button with the link to the event type monitoring board on the Event Type details page.
- Added the tool button with the link to the subscription monitoring board on the Subscription details page.
- Added the link to the SLO monitoring board on the homepage.
- Added an optional analytics plugin support.

### Changed
- The link to the main monitoring board now configurable.

### Fixed
- Fixed typo in the name of the configuration parameter.

## [0.0.18] 2017-09-13
### Added
- Added an info dialog with instructions on how to request the deletion of an event type on Nakadi Live.
- Added an event length to the loaded events list.
- Added the Clone Event Type button to the Event Type Details page.

### Changed
- Changed the placeholders for the service id and the username in the authorization form, to clarify the expected format.

### Fixed
- Fixed layout of the Authorization panel. Added spaces between READ, WRITE, ADMIN labels.
- Fixed the list of low-level consumers in the Delete confirmation dialog showing data from a previously opened event type but not
from the dialog.

## [0.0.17] - 2017-09-04
### Added
- A user can "unstar" an Event Type or a Subscription on the home page.
- The project documentation added to the docs directory.

## [0.0.16] - 2017-07-14
### Added
- The authorization section added to "Create Event Type" form.
- The authorization section added to "Update Event Type" form.
- The authorization tab added to "Event Type details" page.

### Fixed
- The offset reset input looks wrong in Firefox.
- The documentation page references wrong link for Nakadi Manual.
- Removed unnecessary calls to Scalyr.

## [0.0.15] - 2017-06-28
### Changed
- Loading speed optimisation for Consumers and Producers tabs of event type
- Better error message in case of Consumers and Producers tabs load failure.

## [0.0.14] - 2017-06-23
### Added
- A user can reset the current offsets of a subscription.
- Project documentation added (README, CONTRIBUTING, MAINTAINERS).

### Changed
- The offsets are treated as strings not as numbers. The UI is ready to handle the "Nakadi Timeline" offsets format.

### Fixed
- Fixed. The "Create" dropdown doesn't work in Firefox.
- Fixed. Load maximum events returns partial results.

## [0.0.13] - 2017-06-07
### Added
- A user can create a new Subscription.
- A user can delete a Subscription
- Display offsets of last committed cursors on the Subscription Details page.

### Fixed
- The Event Type list of subscription is a column now instead of one line.

## [0.0.12] - 2017-05-09
### Added
- A user can create a new Event Type.
- A user can update some fields of Event Type.
- A user can delete an Event Type (on staging only).

### Fixed
- Fixed limit of only 1,000 loaded subscriptions.

## [0.0.11] - 2017-04-03
### Changed
- Authentication module and configuration updated to use new IAM Platform.

## [0.0.10] - 2017-03-16
### Changed
- Event Types list and Subscriptions list can be sorted by any visible column.
- New schema related columns added to Event Types list: "COMPATIBILITY", "VERSION", "UPDATED", "SCHEMA".
- A user can search a substring inside the current schema of all Event Types.
- Quick Search redesigned. A user can search Event Types and Subscriptions by
 name, id, owning application and consumer group of subscriptions.
- Quick Search sorts the result by relevance, considering the starred items.
- The Logout button changed to the user drop-down menu with the Logout option.
- The Offset input label changed and the quick help icon added to avoid confusions.
- Reload buttons added to Event Type detail view and Subscription detail view.
- The menu item "Dashboard" removed and now the logo is the home button.
- The hit area of "star" on Event Types and Subscriptions list views now takes the whole cell.

## [0.0.9] - 2017-02-28
### Changed
- Implemented the list of publishers to a selected Event Type based on access logs.
- Implemented the list of low-level consumers for a selected Event Type based on access logs.
- Added the list of subscriptions for a selected Event Type.
- All logs are now in JSON format and contain more meta information.
- Logs messages and response headers contain RequestId.
- The offset input type changed from numeric to string because the event offset is a string now.

### Fixed
- Fixed wrong event offsets in search mode.

## [0.0.8] - 2017-02-14
### Changed
- Home page redesigned and renamed to Dashboard.
- About page redesigned and renamed to Documentation.
- Implemented Subscription list view.
- Implemented Subscription details view with subscription stats.
- Users can bookmark ("Star") Event Types and Subscriptions. The list of "Starred"
 items will be stored locally in the localStorage of the browser.
- "Starred" Event Types and Subscriptions lists added to Dashboard page.
- Top 10 latest created/updated EventTypes and Subscriptions added to Dashboard page.
- A user can open an app page in "YOURTURN" directly from Event Types list view.

## [0.0.7] - 2017-02-06
### Changed
- Quick Help hints added to the event type details view.
- Retention time and Create/Update date are displayed in more human readable formats.
- Errors messages show more information about the request that caused the error.

### Fixed
- Fixed an events offset calculation on the event list view.
- Fixed error on getting no events, but only cursor information.
- Fixed browser 'Back' button on the event list view.
- Fixed browser history spammed with every minor change.


## [0.0.6] - 2017-01-17
### Changed
- Logout the user if his access token expired.
- Errors showing with the message from the server and a request details popup.
- Some errors are showing differently as a warning or info.

### Fixed
- Fast typing in filters creates an infinite page reload loop. #18

## [0.0.5] - 2017-01-12
### Added
- List of Events in partition.
- Event content view.
- Collapsible JSON viewer for Event.

### Changed
- Collapsible JSON viewer for ET Schema.

### Fixed
- Layout resize problems fixed.


## [0.0.2] - 2016-12-08
### Added
- List of Event Types.
- Event Types details page.
- Quick Search for Event Types.

## [0.0.1] - 2016-12-05
### Added
- Login/Logout user using external Identity Manager.
- Build, test, deploy infrastructure.

