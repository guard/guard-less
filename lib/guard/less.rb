require 'guard'
require 'guard/plugin'
require 'less'

module Guard
  class Less < Plugin
    require 'guard/less/version'

    def initialize(options = {})
      defaults = {
        all_after_change: true,
        all_on_start: true,
        output: nil,
        import_paths: [],
        compress: false,
        patterns: [],
        yuicompress: false
      }
      super(defaults.merge(options))
    end

    def start
      UI.info "Guard::Less #{LessVersion::VERSION} is on the job!"
      run_all if options[:all_on_start]
    end

    # Call with Ctrl-/ signal
    # This method should be principally used for long action like running all specs/tests/...
    def run_all
      UI.info 'Guard::Less: compiling all files'
      files = Dir.glob('**/*.*')
      paths = Watcher.match_files(self, files).uniq
      run(paths)
    end

    # Call on file(s) modifications
    def run_on_changes(paths)
      options[:all_after_change] ? run_all : run(paths)
    end

    def run(paths)
      directories = nested_directory_map(paths)

      directories.each do |destination, stylesheets|
        stylesheets.each do |lessfile|
          # Skip partials
          basename = File.basename(lessfile)
          next if basename[0, 1] == '_'

          cssfile = File.join(destination, basename.gsub(/\.less$/, '.css'))

          # Just in case
          if cssfile == lessfile
            UI.info "Guard::Less: Skipping #{lessfile} since the output would overwrite the original file"
          elsif mtime(cssfile) >= mtime_including_imports(lessfile)
            UI.info "Guard::Less: Skipping #{lessfile} because #{cssfile} is already up-to-date"
          else
            UI.info "Guard::Less: #{lessfile} -> #{cssfile}\n"
            FileUtils.mkdir_p(File.expand_path(destination))
            compile(lessfile, cssfile)
          end
        end
      end
    end

    private

    # Parse the source lessfile and write to target cssfile
    def compile(lessfile, cssfile)
      import_paths = options[:import_paths].unshift(File.dirname(lessfile))
      parser = ::Less::Parser.new paths: import_paths, filename: lessfile
      File.open(lessfile, 'r') do |infile|
        File.open(cssfile, 'w') do |outfile|
          tree = parser.parse(infile.read)
          outfile << tree.to_css(compress: options[:compress], yuicompress: options[:yuicompress])
        end
      end
      true
    rescue StandardError => e
      UI.info "Guard::Less: Compiling #{lessfile} failed with message: #{e.message}"
      false
    end

    # Creates a hash of changed files keyed by their target nested directory,
    # which is based on either the original source directory or the :output
    # option, plus the regex match group in a watcher like:
    #
    #    %r{^app/stylesheets/(.+\.less)$}
    def nested_directory_map(paths)
      directories = {}

      options[:patterns].product(paths).each do |pattern, path|
        next unless (matches = path.match(pattern))

        target = options[:output] || File.dirname(path)
        if (subpath = matches[1])
          target = File.join(target, File.dirname(subpath)).gsub(/\/\.$/, '')
        end

        (directories[target] ||= []) << path
      end

      directories
    end

    # mtime checking borrowed from the old official LESS Rails plugin:
    #    https://github.com/cloudhead/more
    def mtime(file)
      return 0 unless File.file?(file)
      File.mtime(file).to_i
    end

    # consider imports for mtime
    # just 1 level deep so we do not get any looping/nesting errors
    def mtime_including_imports(file)
      mtimes = [mtime(file)]
      File.readlines(file).each do |line|
        next unless line =~ /^\s*@import ['"]([^'"]+)/

        imported = File.join(File.dirname(file), Regexp.last_match[1])

        # complete path given ?
        mod_time = if imported =~ /\.le?ss$/
                     mtime(imported)
                   else
                     # we need to add .less or .lss
                     [mtime("#{imported}.less"), mtime("#{imported}.lss")].max
                   end
        mtimes << mod_time
      end
      mtimes.max
    end
  end
end
