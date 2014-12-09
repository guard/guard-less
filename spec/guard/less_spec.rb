require 'guard/less'

RSpec.describe Guard::Less do
  include FakeFS::SpecHelpers

  let(:options) { {} }
  subject { described_class.new(options) }

  let(:watcher) { Guard::Watcher.new(/^yes\/.+\.less$/) }

  before do
    allow(Guard::UI).to receive(:info)
  end

  describe '#initialize' do
    describe 'options' do
      subject { described_class.new(options).options }

      context 'when none provided' do
        it { is_expected.to include(all_after_change: true) }
        it { is_expected.to include(all_on_start: true) }
        it { is_expected.to include(output: nil) }
        it { is_expected.to include(import_paths: []) }
        it { is_expected.to include(compress: false) }
      end

      context 'when provided' do
        let(:options) do
          {
            all_after_change: false,
            all_on_start: false,
            output: 'public/stylesheets',
            import_paths: ['lib/styles'],
            compress: true
          }
        end

        it { is_expected.to include(compress: true) }
        it { is_expected.to include(all_after_change: false) }
        it { is_expected.to include(all_on_start: false) }
        it { is_expected.to include(output: 'public/stylesheets') }
        it { is_expected.to include(import_paths: ['lib/styles']) }
      end
    end
  end

  describe '.start' do
    it 'executes run_all if :all_on_start is true' do
      expect(subject).to receive(:run_all)
      subject.start
    end
  end

  describe '.run_all' do
    let(:watcher) { Guard::Watcher.new(/^yes\/(.+)\.less$/) }
    let(:options) { { watchers: [watcher] } }

    before do
      allow(Dir).to receive(:glob).and_return ['yes/a.less', 'yes/b.less', 'no/c.less']
    end

    it 'executes .run passing all watched LESS files' do
      expect(subject).to receive(:run).with(['yes/a.less', 'yes/b.less'])
      subject.run_all
    end

    it 'executes .run passing all watched LESS files while observing actions provided' do
      watcher.action = ->(m) { "yep/#{m[1]}.less" }
      guard = Guard::Less.new(watchers: [watcher])
      expect(guard).to receive(:run).with(['yep/a.less', 'yep/b.less'])
      guard.run_all
    end

    it 'executes .run only once per path' do
      watcher.action = ->(_m) { 'base.less' }
      guard = Guard::Less.new(watchers: [watcher])
      expect(guard).to receive(:run).with(['base.less'])
      guard.run_all
    end
  end

  describe '.run_on_change' do
    context 'with :all_after_change true' do
      let(:options) { { all_after_change: true } }
      it 'executes .run_all if :all_after_change is true' do
        expect(subject).to receive(:run_all)
        subject.run_on_changes([])
      end
    end

    context 'with :all_after_change false' do
      let(:options) { { all_after_change: false } }
      it 'executes .run passing the watched files' do
        files = ['a.less', 'b.less']
        expect(subject).to receive(:run).with(files)
        subject.run_on_changes(files)
      end
    end
  end

  describe 'run' do
    let(:options) { { watchers: [watcher] } }

    it 'does not compile otherwise matching _partials' do
      expect(subject).not_to receive(:compile)
      subject.run(['yes/_partial.less'])
    end

    context 'if watcher misconfigured to match CSS' do
      let(:options) { { watchers: [Guard::Watcher.new(/^yes\/.+\.css$/)], output: nil } }

      it 'does not overwrite CSS' do
        expect(subject).not_to receive(:compile)
        expect(Guard::UI).to receive(:info).with(/output would overwrite the original/)
        subject.run(['yes/a.css'])
      end
    end

    context 'when CSS is more recently modified than LESS' do
      before do
        write_stub_less_file('yes/a.less')
        FileUtils.touch('yes/a.css')
      end

      it 'does not compile' do
        expect(subject).not_to receive(:compile)
        subject.run(['yes/a.less'])
      end

      it 'informs user of up-to-date skipped files' do
        expect(Guard::UI).to receive(:info).with(/yes\/a.css is already up-to-date/)
        subject.run(['yes/a.less'])
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
          expect(subject).to receive(:compile)
          subject.run(['yes/a.less'])
        end
      end
    end

    context 'when CSS is out of date' do
      before do
        allow(subject).to receive(:mtime).and_return(Time.now - 1)
        allow(subject).to receive(:mtime_including_imports).and_return(Time.now)
        allow(subject).to receive(:compile)
      end

      it 'compiles matching watched files' do
        expect(subject).to receive(:compile).twice
        subject.run(['yes/a.less', 'no/a.less', 'yes/b.less'])
      end

      it 'informs user of compiled files' do
        expect(Guard::UI).to receive(:info).with(%r{yes/a.less -> yes/a.css})
        subject.run(['yes/a.less'])
      end
    end

    context 'when compiling' do
      before do
        allow(subject).to receive(:mtime).and_return(Time.now - 1)
        allow(subject).to receive(:mtime_including_imports).and_return(Time.now)
      end

      it 'produces CSS from LESS' do
        write_stub_less_file('yes/a.less')
        subject.run(['yes/a.less'])
        expect(File.read('yes/a.css')).to match(/color: #4D926F;/i)
      end

      it 'produces CSS in same nested directory hierarchy as LESS' do
        path = 'yes/we/can/have/nested/directories/a.less'
        write_stub_less_file(path)
        subject.run([path])
        expect(File).to exist('yes/we/can/have/nested/directories/a.css')
      end

      it 'includes directory of currently processing file in Less parser import paths' do
        expect(::Less::Parser).to receive(:new).with(paths: ['yes'], filename: 'yes/a.less')
        subject.run(['yes/a.less'])
      end

      context 'using :import_paths option' do
        let(:options) { { watchers: [watcher], import_paths: ['lib/styles'] } }

        it 'also includes specified import paths for Less parser' do
          expect(::Less::Parser).to receive(:new).with(paths: ['yes', 'lib/styles'], filename: 'yes/a.less')
          subject.run(['yes/a.less'])
        end
      end

      context 'using :output option with custom directory' do
        let(:watcher) { Guard::Watcher.new(/^yes\/(.+\.less)$/) }
        let(:options) { { watchers: [watcher], output: 'public/stylesheets' } }

        it 'creates directories as needed to match source hierarchy' do
          path = 'yes/we/can/have/nested/directories/a.less'
          write_stub_less_file(path)
          subject.run([path])
          expect(File).to exist('public/stylesheets/we/can/have/nested/directories/a.css')
        end
      end
    end
  end

  private

  def write_stub_less_file(path, import = false)
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
