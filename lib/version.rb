module Semantic
  class Version
    def rc!
      if @pre.nil?
        increment!(:minor)
        @pre = 'rc.1'
        return
      end

      if @pre =~ /^rc\.\d+$/
        @pre = "rc.#{Integer(@pre.delete('rc.')) + 1}"
        return
      end

      raise RuntimeError.new(
          "Error: pre segment '#{@pre}' is does not look like 'rc.n'")
    end
  end
end
