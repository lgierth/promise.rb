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

promise.rb doesn't come with a way of scheduling callback dispatch.

```ruby
require 'promise'

class MyPromise < Promise
  def defer(callback, arg)
    callback.dispatch(arg)
  end
end
```

The above scheduling mechanism violates the following section of the spec:

> onFulfilled or onRejected must not be called until the execution context
> stack contains only platform code.

Compliance can be achieved, for example, by running an event reactor like
EventMachine:

```ruby
require 'promise'
require 'eventmachine'

class MyPromise < Promise
  def defer(callback, arg)
    EM.next_tick { callback.dispatch(arg) }
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

## License

Hatetepe is licensed under the [MIT License](http://opensource.org/licenses/MIT).
See LICENSE.txt for details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
