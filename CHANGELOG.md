# promise.rb changelog

## 0.4.0 (December 13, 2013)

* Disclaiming my copyright, promise.rb is now in the Public Domain
* on_fulfill argument to #then now takes precedence over block
* The rejection reason now defaults to RuntimeError, so that it can be re-raised by #sync
* `progress` and `on_progress` are now first class citizens
