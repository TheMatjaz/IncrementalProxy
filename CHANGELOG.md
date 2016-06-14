Change Log
==========

All notable changes to the _IncrementalProxy_ project will be documented in this
file. This project adheres to [Semantic Versioning](http://semver.org/).


[0.1.0] - 2016-06-14
--------------------

### Added

- Python3 external ACL script that verifies if a proxy user may visit a certain
  domain against a PostgreSQL db.
- PostgreSQL database setup scripts that work also for the Basic proxy
  authentication script `basic_db_auth` integrated with Squid. The setup
  includes editable views that may be interfaced with a Web administration panel
  for the proxy admin and a Web domain-unlock-request panel for the proxy user.

