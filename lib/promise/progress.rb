# frozen_string_literal: true

class Promise
  module Progress
    def on_progress(&block)
      (@on_progress ||= []).tap do |callbacks|
        callbacks << block if block_given?
      end
    end

    def progress(status)
      on_progress.each { |block| block.call(status) } if pending?
    end
  end
end
