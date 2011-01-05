require 'guard'
require 'guard/guard'
require 'less'

module Guard
  class Less < Guard

    # ================
    # = Guard method =
    # ================

    def start
      UI.info "Guard::Less #{VERSION} is on the job!\n"
    end

    # Call with Ctrl-/ signal
    # This method should be principally used for long action like running all specs/tests/...
    def run_all
       patterns = @watchers.map { |w| w.pattern }
       files = Dir.glob('**/*.*')
       r = []
       files.each do |file|
         patterns.each do |pattern|
           r << file if file.match(Regexp.new(pattern))
         end
       end
       run_on_change(r)
    end

    # Call on file(s) modifications
    def run_on_change(paths)
      paths.each do |file|
        unless File.basename(file)[0] == "_"
          UI.info "lessc - #{file}\n"
          `lessc #{file} --verbose`
        end
      end
    end

  end
end