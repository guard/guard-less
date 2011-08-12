require 'guard'
require 'guard/guard'
require 'less'

require File.dirname(__FILE__) + "/less/version"

module Guard
  class Less < Guard

    # ================
    # = Guard method =
    # ================
    def initialize(watchers=[], options={})
      super
      @all_after_change = options.delete(:all_after_change)
      @all_on_start = options.delete(:all_on_start)
    end

    def start
      UI.info "Guard::Less #{LessVersion::VERSION} is on the job!"
      run_all unless @all_on_start == false
    end

    # Call with Ctrl-/ signal
    # This method should be principally used for long action like running all specs/tests/...
    def run_all
      UI.info "Guard::Less: compiling all files"
      patterns = @watchers.map { |w| w.pattern }
      files = Dir.glob('**/*.*')
      paths = []
      files.each do |file|
        patterns.each do |pattern|
          paths << file if file.match(Regexp.new(pattern))
        end
      end
      run(paths)
    end

    # Call on file(s) modifications
    def run_on_change(paths)
      @all_after_change ? run_all : run(paths)
    end

    def run(paths)
      paths.each do |file|
        unless File.basename(file)[0] == "_"
          css_file = file.gsub(/\.less$/,'.css')

          # Just in case
          if css_file == file
            UI.info "Guard::Less: Skipping #{file} since the output would overwrite the original file"
          else
            UI.info "Guard::Less: #{file} -> #{css_file}\n"

            begin
              parser = ::Less::Parser.new :paths => ['./public/stylesheets'], :filename => file
              File.open(file,'r') do |infile|
                File.open(css_file,'w') do |outfile|
                  tree = parser.parse(infile.read)
                  outfile << tree.to_css
                end
              end
              true
            rescue Exception => e
              UI.info "Guard::Less: Compiling #{file} failed with message: #{e.message}"
              false
            end
          end
        end
      end
    end
  end
end
