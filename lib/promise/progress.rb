# encoding: utf-8

class Promise
  module Progress
    def on_progress(&block)
      (@on_progress ||= []).tap do |callbacks|
        callbacks << block if block_given?
      end
    end

    def progress(status)
      if pending?
        on_progress.each { |block| block.call(status) }
      end
    end
  end
end
