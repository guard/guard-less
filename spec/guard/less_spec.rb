require "guard/less"

RSpec.describe Guard::Less do
  include FakeFS::SpecHelpers

  let(:guard) { Guard::Less.new }
  let(:watcher) { Guard::Watcher.new(%r{^yes/.+\.less$}) }

  describe '#initialize' do
    context 'when no options are provided' do
      it 'enables :all_after_change option' do
        guard.options[:all_after_change].should be_true
      end

      it 'enables :all_on_start option' do
        guard.options[:all_on_start].should be_true
      end

      it 'sets no :ouput option' do
        guard.options[:output].should be_nil
      end

      it 'sets an empty :import_paths option' do
        guard.options[:import_paths].should be_empty
      end

      it 'sets false for :compress' do
        guard.options[:compress].should be_false
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
        guard.options[:compress].should be_true
      end

      it 'sets :all_after_change' do
        guard.options[:all_after_change].should be_false
      end

      it 'sets :all_on_start' do
        guard.options[:all_on_start].should be_false
      end

      it 'sets :output' do
        guard.options[:output].should eql 'public/stylesheets'
      end

      it 'sets :import_paths' do
        guard.options[:import_paths].should eql ['lib/styles']
      end
    end
  end

  describe '.start' do
    it 'executes run_all if :all_on_start is true' do
      guard.should_receive(:run_all)
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
      Dir.stub(:glob).and_return ['yes/a.less', 'yes/b.less', 'no/c.less']
    end

    it 'executes .run passing all watched LESS files' do
      guard.should_receive(:run).with(['yes/a.less', 'yes/b.less'])
      guard.run_all
    end

    it 'executes .run passing all watched LESS files while observing actions provided' do
      guard_with_one_to_one_action.should_receive(:run).with(['yep/a.less', 'yep/b.less'])
      guard_with_one_to_one_action.run_all
    end

    it 'executes .run only once per path' do
      guard_with_many_to_one_action.should_receive(:run).with(['base.less'])
      guard_with_many_to_one_action.run_all
    end
  end

  describe '.run_on_change' do
    it 'executes .run_all if :all_after_change is true' do
      guard = Guard::Less.new(all_after_change: true)
      guard.should_receive(:run_all)
      guard.run_on_changes([])
    end

    it 'executes .run passing the watched files if :all_after_change is false' do
      guard = Guard::Less.new(all_after_change: false)
      files = ['a.less', 'b.less']
      guard.should_receive(:run).with(files)
      guard.run_on_changes(files)
    end
  end

  describe 'run' do
    let(:guard) { Guard::Less.new(watchers: [watcher]) }

    it 'does not compile otherwise matching _partials' do
      guard.should_not_receive(:compile)
      guard.run(['yes/_partial.less'])
    end

    context 'if watcher misconfigured to match CSS' do
      let(:guard) { Guard::Less.new(watchers: [Guard::Watcher.new(%r{^yes/.+\.css$})], output: nil) }

      it 'does not overwrite CSS' do
        guard.should_not_receive(:compile)
        ::Guard::UI.should_receive(:info).with(/output would overwrite the original/)
        guard.run(['yes/a.css'])
      end
    end

    context 'when CSS is more recently modified than LESS' do
      before do
        write_stub_less_file('yes/a.less')
        FileUtils.touch('yes/a.css')
      end

      it 'does not compile' do
        guard.should_not_receive(:compile)
        guard.run(['yes/a.less'])
      end

      it 'informs user of up-to-date skipped files' do
        ::Guard::UI.should_receive(:info).with(/yes\/a.css is already up-to-date/)
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
          guard.should_receive(:compile)
          guard.run(['yes/a.less'])
        end
      end
    end

    context 'when CSS is out of date' do
      before do
        stub_compilation_needed
        guard.stub(:compile)
      end

      it 'compiles matching watched files' do
        guard.should_receive(:compile).twice
        guard.run(['yes/a.less', 'no/a.less', 'yes/b.less'])
      end

      it 'informs user of compiled files' do
        ::Guard::UI.should_receive(:info).with(/yes\/a.less -> yes\/a.css/)
        guard.run(['yes/a.less'])
      end
    end

    context 'when compiling' do
      before { stub_compilation_needed }

      it 'produces CSS from LESS' do
        write_stub_less_file('yes/a.less')
        guard.run(['yes/a.less'])
        File.read('yes/a.css').should match(/color: #4D926F;/i)
      end

      it 'produces CSS in same nested directory hierarchy as LESS' do
        path = 'yes/we/can/have/nested/directories/a.less'
        write_stub_less_file(path)
        guard.run([path])
        File.should exist('yes/we/can/have/nested/directories/a.css')
      end

      it 'includes directory of currently processing file in Less parser import paths' do
        ::Less::Parser.should_receive(:new).with(paths: ['yes'], filename: 'yes/a.less')
        guard.run(['yes/a.less'])
      end

      context 'using :import_paths option' do
        let(:guard) do
          Guard::Less.new(watchers: [watcher], import_paths: ['lib/styles'])
        end

        it 'also includes specified import paths for Less parser' do
          ::Less::Parser.should_receive(:new).with(paths: ['yes', 'lib/styles'], filename: 'yes/a.less')
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
          File.should exist('public/stylesheets/we/can/have/nested/directories/a.css')
        end
      end
    end

  end

  private

  def stub_compilation_needed
    guard.stub(:mtime).and_return(Time.now - 1)
    guard.stub(:mtime_including_imports).and_return(Time.now)
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
