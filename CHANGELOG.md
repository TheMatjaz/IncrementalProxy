Change Log
==========

All notable changes to the _IncrementalProxy_ project will be documented in this
file. This project adheres to [Semantic Versioning](http://semver.org/).

[0.3.1] - 2020-11-24
--------------------

### Fixed

- Added BSD 3-Clause license: there was no license file before
- Added screenshots to readme
- Added disclaimer of project abandonment



[0.3.0] - 2016-07-02
--------------------

### Added

- SSL Bump: HTTPS connections are now decripted in a man-in-the-middle style
  and the traffic is analyzed in clear text. **You'll have to install the
  [proxy's self-signed certificate](proxy.matjaz.it/squid.pem)** in order to
  navigate on websites over HTTPS.
- Proxy administration web panel: it features the moderation of all domains
  with status `limbo` and the listing of all domains visited by all users.
  Only proxy administrators have access to it.


### Changed

- CSS look and feel of the web pages and panel. A very simple change with some
  design fixes.
- Add information in the Readme: about the generation of the proxy's 
  self-signed certificate, about the SSL bump and the proxy admin web panel.


[0.2.0] - 2016-07-01
--------------------

### Added

- Squid allows automatically any download of page resources. Those are any 
  files located on a URL for which the HTTP request has a non-empty `Referer`
  and the HTTP reply has a `Content-Type` different than `text/html`.
- Add PHP driven web pages the user is 307-redirected to where he/she could 
  request an insertion of a website in the limbo status or a temporary unlock
  of a website upon writing the motivation for both.


### Changed

- **Compatibility break**: Squid 3.5 is the minimum required version otherwise 
  the automatic allowance of page resources (see above) does not work, since 
  the `Content-Type` is not passed to the helper script.
- The users have to write a motivation to any visited domain on the first 
  visit of that domain.
- More setup info in the Readme.


[0.1.0] - 2016-06-14
--------------------

### Added

- Python3 external ACL script that verifies if a proxy user may visit a certain
  domain against a PostgreSQL db.
- PostgreSQL database setup scripts that work also for the Basic proxy
  authentication script `basic_db_auth` integrated with Squid. The setup
  includes editable views that may be interfaced with a Web administration panel
  for the proxy admin and a Web domain-unlock-request panel for the proxy user.

