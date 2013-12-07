# promise.rb [![Build Status](https://travis-ci.org/lgierth/promise.rb.png?branch=master)](https://travis-ci.org/lgierth/promise.rb) [![Code Climate](https://codeclimate.com/github/lgierth/promise.rb.png)](https://codeclimate.com/github/lgierth/promise.rb) [![Coverage Status](https://coveralls.io/repos/lgierth/promise.rb/badge.png?branch=master)](https://coveralls.io/r/lgierth/promise.rb?branch=master)

Ruby implementation of the [Promises/A+ spec](http://promisesaplus.com/).
100% mutation coverage, tested on 1.9, 2.0, Rubinius, and JRuby.

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

nonblocking_stuff.then { |value| p value }
nonblocking_stuff.then(proc { |value| p value })
```

Rejection works similarly:

```ruby
def failing_stuff
  promise = MyPromise.new
  EM.next_tick { promise.reject('reason') }
  promise
end

failing_stuff.then(proc { |value| }, proc { |reason| p reason })
```

promise.rb also comes with the utility method `Promise#sync`, which waits for
the promise to be fulfilled and returns the value, or for it to be rejected and
re-raises the reason. Using `#sync` requires you to implement `#wait`. You could
for example cooperatively schedule fibers waiting for different promises:

```ruby
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

promise = MyPromise.new
Fiber.new { p promise.sync }.resume
EM.next_tick { promise.fulfill }
```

Or have the rejection reason re-raised from `#sync`:

```ruby
promise = MyPromise.new
begin
  Fiber.new { promise.sync }.resume
  EM.next_tick { promise.fulfill }
rescue
  p $!
end
```

## License

Hatetepe is licensed under the [MIT License](http://opensource.org/licenses/MIT).
See LICENSE.txt for details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
