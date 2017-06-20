# frozen_string_literal: true

require_relative './setup.rb'

PromiseBenchmark.profile_memory do
  Promise.all([
                Promise.all([
                              Promise.resolve(1),
                              Promise.resolve(2),
                              Promise.resolve(3)
                            ]),
                Promise.all([
                              Promise.resolve(1),
                              Promise.resolve(2),
                              Promise.resolve(3)
                            ]),
                Promise.all([
                              Promise.resolve(1),
                              Promise.resolve(2),
                              Promise.resolve(3)
                            ])
              ]).then { |value| value }.sync
end

puts "\n"

PromiseBenchmark.benchmark do |x|
  x.report 'Promise.all w/promises' do
    Promise.all([
                  Promise.all([
                                Promise.resolve(1),
                                Promise.resolve(2),
                                Promise.resolve(3)
                              ]),
                  Promise.all([
                                Promise.resolve(1),
                                Promise.resolve(2),
                                Promise.resolve(3)
                              ]),
                  Promise.all([
                                Promise.resolve(1),
                                Promise.resolve(2),
                                Promise.resolve(3)
                              ])
                ]).then { |value| value }
  end
  x.report 'Promise.all w/values' do
    Promise.all([
                  Promise.all([
                                1,
                                2,
                                3
                              ]),
                  Promise.all([
                                1,
                                2,
                                3
                              ]),
                  Promise.all([
                                1,
                                2,
                                3
                              ])
                ]).then { |value| value }.sync
  end
  x.report('Promise.resolve') { Promise.resolve(true) }
  x.report('Promise.resolve.sync') { Promise.resolve(true).sync }
  x.report('Promise.resolve#then') do
    Promise.resolve(true).then { |value| value }.sync
  end
  x.report('Promise.new#then') { Promise.new.then { |value| value } }
  x.report('Promise.resolve nested') do
    Promise.resolve(true).then { |_value| Promise.resolve(false) }.sync
  end
end
