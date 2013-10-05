# encoding: utf-8

class Promise
  module Progress
    def initialize
      super
      @on_progress = []
    end

    def on_progress(&block)
      @on_progress << block
    end

    def progress(status)
      if pending?
        @on_progress.each { |block| block.call(status) }
      end
    end
  end
end
