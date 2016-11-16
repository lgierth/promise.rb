# promise.rb [![Build Status](https://travis-ci.org/lgierth/promise.rb.png?branch=master)](https://travis-ci.org/lgierth/promise.rb) [![Code Climate](https://codeclimate.com/github/lgierth/promise.rb.png)](https://codeclimate.com/github/lgierth/promise.rb) [![Coverage Status](https://coveralls.io/repos/lgierth/promise.rb/badge.png?branch=master)](https://coveralls.io/r/lgierth/promise.rb?branch=master)

Ruby implementation of the [Promises/A+ spec](http://promisesaplus.com/).
100% [mutation coverage](https://github.com/mbj/mutant),
tested on MRI 1.9, 2.0, 2.1, 2.2, Rubinius, and JRuby.

Similar projects:

- [concurrent-ruby](https://github.com/jdantonio/concurrent-ruby), Promises/A(+) inspired implementation, thread based
- [ruby-thread](https://github.com/meh/ruby-thread), thread/mutex/condition variable based, thread safe
- [promise](https://github.com/bhuga/promising-future), a.k.a. promising-future, classic promises and futures, thread based
- [celluloid-promise](https://github.com/cotag/celluloid-promise), inspired by Q, backed by a Celluloid actor
- [em-promise](https://github.com/cotag/em-promise), inspired by Q, backed by an EventMachine reactor
- [futuristic](https://github.com/seanlilmateus/futuristic), MacRuby bindings for Grand Central Dispatch
- [methodmissing/promise](https://github.com/methodmissing/promise), thread based, abandoned

*Note that promise.rb is probably not thread safe.*

## Installation

Add this line to your application's Gemfile:

    gem 'promise.rb'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install promise.rb

## Usage

This guide assumes that you are familiar with the [Promises/A+ spec](http://promisesaplus.com/). It's a quick read, though.

promise.rb comes with a very primitive way of scheduling callback dispatch. It
immediately executes the callback, instead of scheduling it for execution
*after* `Promise#fulfill` or `Promise#reject`, as demanded by the spec:

> onFulfilled or onRejected must not be called until the execution context
> stack contains only platform code.

Compliance can be achieved, for example, by running an event reactor like
EventMachine:

```ruby
require 'promise'
require 'eventmachine'

class MyPromise < Promise
  def defer
    EM.next_tick { yield }
  end
end
```

Now you can create MyPromise objects, and fullfil (or reject) them, as well as
add callbacks to them:

```ruby
def nonblocking_stuff
  promise = MyPromise.new
  EM.next_tick { promise.fulfill('value') }
  promise
end

EM.run do
  nonblocking_stuff.then { |value| p value }
  nonblocking_stuff.then(proc { |value| p value })
end
```

Rejection works similarly:

```ruby
def failing_stuff
  promise = MyPromise.new
  EM.next_tick { promise.reject('reason') }
  promise
end

EM.run do
  failing_stuff.then(proc { |value| }, proc { |reason| p reason })
end
```

### Waiting for fulfillment/rejection

promise.rb also comes with the utility method `Promise#sync`, which waits for
the promise to be fulfilled and returns the value, or for it to be rejected and
re-raises the reason. Using `#sync` requires you to implement `#wait`. You could
for example cooperatively schedule fibers waiting for different promises:

```ruby
require 'fiber'
require 'promise'
require 'eventmachine'

class MyPromise < Promise
  def defer
    EM.next_tick { yield }
  end

  def wait
    fiber = Fiber.current
    resume = proc do |arg|
      defer { fiber.resume(arg) }
    end

    self.then(resume, resume)
    Fiber.yield
  end
end

EM.run do
  promise = MyPromise.new
  Fiber.new { p promise.sync }.resume
  promise.fulfill
end
```

Or have the rejection reason re-raised from `#sync`:

```ruby
EM.run do
  promise = MyPromise.new

  Fiber.new do
    begin
      promise.sync
    rescue
      p $!
    end
  end.resume

  promise.reject('reason')
end
```

### Chaining promises

As per the A+ spec, every call to `#then` returns a new promise, which assumes
the first promise's state. That means it passes its `#fulfill` and `#reject`
methods to first promise's `#then`, shortcircuiting the two promises. In case
a callback returns a promise, it'll instead assume that promise's state.

Imagine the `#fulfill` and `#reject` calls in the following example happening
somewhere in a background Fiber or so.

```ruby
require 'promise'

Promise.new
  .tap(&:fulfill)
  .then { Promise.new.tap(&:fulfill) }
  .then { Promise.new.tap(&:reject) }
  .then(nil, proc { |reason| p reason })
```

In order to use the result of multiple promises, they can be grouped using
`Promise.all` for chaining.

```ruby
sum_promise = Promise.all([promise1, promise2]).then do |value1, value2|
  value1 + value2
end
```

### Progress callbacks

Very simple progress callbacks, as per Promises/A, are supported as well. They have been dropped in A+, but I found them to be a useful mechanism - if kept simple. Callback dispatch happens immediately in the call to `#progress`, in the order of definition via `#on_progress`. Also note that `#on_progress` does not return a new promise for chaining - the progress mechanism is meant to be very lightweight, and ignores many of the constraints and guarantees of `then`.

```ruby
promise = MyPromise.new
promise.on_progress { |status| p status }
promise.progress(:anything)
```

## Unlicense

promise.rb is free and unencumbered public domain software. For more
information, see [unlicense.org](http://unlicense.org/) or the accompanying
UNLICENSE file.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
