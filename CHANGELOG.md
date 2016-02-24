# promise.rb changelog

## 0.7.0 (February 24, 2016)

### Features

* Add a Promise#rescue convenience for specifying on_reject. (pull #16)

## 0.7.0.rc2 (February 17, 2016)

### Bug Fixes

* Avoid re-raising exception that occur in then callbacks (pull #13)
* Wait for an instance of a subclass of Promise in Promise.all (pull #15)

### Features

* Instantiate exception classes and set missing backtrace in reject (pull #12)
* Allow Promise#fulfill to be called with a promise (pull #14)

### Breaking Changes

* Make add_callback, dispatch, dispatch! and Promise::Callback private (pull #11)
* Remove Promise#backtrace, use #reason.backtrace instead (pull #12)

## 0.7.0.rc1 (February 9, 2016)

### Bug Fixes

* Return instances of the custom promise class from its methods (pull #10)

### Features

* Add Promise.resolve utility method (pull #8)
* Add Promise.all utility method (pull #9)

## 0.6.1 (January 14, 2014)

* The rejection reason now defaults to Promise::Error.
* Promise::Callback got refactored.

## 0.6.0 (December 21, 2013)

* Most of Promise and Callback have been rewritten. Less code.
* The rejection reason isn't overloaded with the promise's backtrace anymore as
  introduced in 0.5.0. Instead, Promise#backtrace will be populated with the
  originating call to #fulfill or #reject.
* The backtrace no longer guarantees that the actual caller is its first
  element (thank you JRuby).

## 0.5.0 (December 16, 2013)

* Fulfillment value and rejection reason are no longer being frozen
* Rejection reason always gets a sensible backtrace now
* Have pending specs for deviations from the A+ spec

## 0.4.0 (December 13, 2013)

* Disclaiming my copyright, promise.rb is now in the Public Domain
* on_fulfill argument to #then now takes precedence over block
* The rejection reason now defaults to RuntimeError, so that it can be re-raised by #sync
* `progress` and `on_progress` are now first class citizens
