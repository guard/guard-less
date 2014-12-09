require "guard/less"

RSpec.describe Guard::Less do
  include FakeFS::SpecHelpers

  let(:guard) { Guard::Less.new }
  let(:watcher) { Guard::Watcher.new(%r{^yes/.+\.less$}) }

  describe '#initialize' do
    context 'when no options are provided' do
      it 'enables :all_after_change option' do
        expect(guard.options[:all_after_change]).to be_truthy
      end

      it 'enables :all_on_start option' do
        expect(guard.options[:all_on_start]).to be_truthy
      end

      it 'sets no :ouput option' do
        expect(guard.options[:output]).to be_nil
      end

      it 'sets an empty :import_paths option' do
        expect(guard.options[:import_paths]).to be_empty
      end

      it 'sets false for :compress' do
        expect(guard.options[:compress]).to be_falsey
      end
    end

    context 'when providing options' do
      let(:guard) do
        Guard::Less.new(
          all_after_change: false,
          all_on_start: false,
          output: 'public/stylesheets',
          import_paths: ['lib/styles'],
          compress: true
        )
      end

      it 'sets :compress' do
        expect(guard.options[:compress]).to be_truthy
      end

      it 'sets :all_after_change' do
        expect(guard.options[:all_after_change]).to be_falsey
      end

      it 'sets :all_on_start' do
        expect(guard.options[:all_on_start]).to be_falsey
      end

      it 'sets :output' do
        expect(guard.options[:output]).to eql 'public/stylesheets'
      end

      it 'sets :import_paths' do
        expect(guard.options[:import_paths]).to eql ['lib/styles']
      end
    end
  end

  describe '.start' do
    it 'executes run_all if :all_on_start is true' do
      expect(guard).to receive(:run_all)
      guard.start
    end
  end

  describe '.run_all' do
    let(:watcher) { Guard::Watcher.new(%r{^yes/(.+)\.less$}) }
    let(:guard) { Guard::Less.new(watchers: [watcher]) }

    let(:guard_with_one_to_one_action) do
      watcher.action = ->(m) { "yep/#{m[1]}.less" }
      Guard::Less.new(watchers: [watcher])
    end

    let(:guard_with_many_to_one_action) do
      watcher.action = ->(m) { "base.less" }
      Guard::Less.new(watchers: [watcher])
    end

    before do
      allow(Dir).to receive(:glob).and_return ['yes/a.less', 'yes/b.less', 'no/c.less']
    end

    it 'executes .run passing all watched LESS files' do
      expect(guard).to receive(:run).with(['yes/a.less', 'yes/b.less'])
      guard.run_all
    end

    it 'executes .run passing all watched LESS files while observing actions provided' do
      expect(guard_with_one_to_one_action).to receive(:run).with(['yep/a.less', 'yep/b.less'])
      guard_with_one_to_one_action.run_all
    end

    it 'executes .run only once per path' do
      expect(guard_with_many_to_one_action).to receive(:run).with(['base.less'])
      guard_with_many_to_one_action.run_all
    end
  end

  describe '.run_on_change' do
    it 'executes .run_all if :all_after_change is true' do
      guard = Guard::Less.new(all_after_change: true)
      expect(guard).to receive(:run_all)
      guard.run_on_changes([])
    end

    it 'executes .run passing the watched files if :all_after_change is false' do
      guard = Guard::Less.new(all_after_change: false)
      files = ['a.less', 'b.less']
      expect(guard).to receive(:run).with(files)
      guard.run_on_changes(files)
    end
  end

  describe 'run' do
    let(:guard) { Guard::Less.new(watchers: [watcher]) }

    it 'does not compile otherwise matching _partials' do
      expect(guard).not_to receive(:compile)
      guard.run(['yes/_partial.less'])
    end

    context 'if watcher misconfigured to match CSS' do
      let(:guard) { Guard::Less.new(watchers: [Guard::Watcher.new(%r{^yes/.+\.css$})], output: nil) }

      it 'does not overwrite CSS' do
        expect(guard).not_to receive(:compile)
        expect(::Guard::UI).to receive(:info).with(/output would overwrite the original/)
        guard.run(['yes/a.css'])
      end
    end

    context 'when CSS is more recently modified than LESS' do
      before do
        write_stub_less_file('yes/a.less')
        FileUtils.touch('yes/a.css')
      end

      it 'does not compile' do
        expect(guard).not_to receive(:compile)
        guard.run(['yes/a.less'])
      end

      it 'informs user of up-to-date skipped files' do
        expect(::Guard::UI).to receive(:info).with(/yes\/a.css is already up-to-date/)
        guard.run(['yes/a.less'])
      end

      context 'but LESS file has an import more recently modified than CSS' do
        before do
          write_stub_less_file('yes/a.less', true)
          # touch with :mtime option doesn't seem to work?
          FileUtils.touch(['yes/a.css', 'yes/b.less'])
          File.utime(Time.now - 5, Time.now - 5, 'yes/a.less')
          File.utime(Time.now - 3, Time.now - 3, 'yes/a.css')
        end

        it 'compiles the importing LESS file' do
          expect(guard).to receive(:compile)
          guard.run(['yes/a.less'])
        end
      end
    end

    context 'when CSS is out of date' do
      before do
        stub_compilation_needed
        allow(guard).to receive(:compile)
      end

      it 'compiles matching watched files' do
        expect(guard).to receive(:compile).twice
        guard.run(['yes/a.less', 'no/a.less', 'yes/b.less'])
      end

      it 'informs user of compiled files' do
        expect(::Guard::UI).to receive(:info).with(/yes\/a.less -> yes\/a.css/)
        guard.run(['yes/a.less'])
      end
    end

    context 'when compiling' do
      before { stub_compilation_needed }

      it 'produces CSS from LESS' do
        write_stub_less_file('yes/a.less')
        guard.run(['yes/a.less'])
        expect(File.read('yes/a.css')).to match(/color: #4D926F;/i)
      end

      it 'produces CSS in same nested directory hierarchy as LESS' do
        path = 'yes/we/can/have/nested/directories/a.less'
        write_stub_less_file(path)
        guard.run([path])
        expect(File).to exist('yes/we/can/have/nested/directories/a.css')
      end

      it 'includes directory of currently processing file in Less parser import paths' do
        expect(::Less::Parser).to receive(:new).with(paths: ['yes'], filename: 'yes/a.less')
        guard.run(['yes/a.less'])
      end

      context 'using :import_paths option' do
        let(:guard) do
          Guard::Less.new(watchers: [watcher], import_paths: ['lib/styles'])
        end

        it 'also includes specified import paths for Less parser' do
          expect(::Less::Parser).to receive(:new).with(paths: ['yes', 'lib/styles'], filename: 'yes/a.less')
          guard.run(['yes/a.less'])
        end
      end

      context 'using :output option with custom directory' do
        let(:watcher) { Guard::Watcher.new(%r{^yes/(.+\.less)$}) }
        let(:guard) do
          Guard::Less.new(watchers: [watcher], output: 'public/stylesheets')
        end

        it 'creates directories as needed to match source hierarchy' do
          path = 'yes/we/can/have/nested/directories/a.less'
          write_stub_less_file(path)
          guard.run([path])
          expect(File).to exist('public/stylesheets/we/can/have/nested/directories/a.css')
        end
      end
    end

  end

  private

  def stub_compilation_needed
    allow(guard).to receive(:mtime).and_return(Time.now - 1)
    allow(guard).to receive(:mtime_including_imports).and_return(Time.now)
  end

  def write_stub_less_file(path, import=false)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') do |out|
      out.puts <<LESS
@color: #4D926F;

#header {
  color: @color;
}
LESS

      out << '@import "b";' if import
    end
  end
end
