# promise.rb changelog

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
