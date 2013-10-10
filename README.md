# Guard::Less

[![Gem Version](https://badge.fury.io/rb/guard-less.png)](http://badge.fury.io/rb/guard-less) [![Build Status](https://travis-ci.org/guard/guard-less.png?branch=master)](https://travis-ci.org/guard/guard-less) [![Dependency Status](https://gemnasium.com/guard/guard-less.png)](https://gemnasium.com/guard/guard-less) [![Code Climate](https://codeclimate.com/github/guard/guard-less.png)](https://codeclimate.com/github/guard/guard-less) [![Coverage Status](https://coveralls.io/repos/guard/guard-less/badge.png?branch=master)](https://coveralls.io/r/guard/guard-less)

A guard extension that compiles `.less` files to `.css` files when changed.

* Compatible with Less ~> 2.3.
* Tested against Ruby 1.9.3, 2.0.0, Rubinius & JRuby (1.9 mode only).

## Install

You will need to have [Guard](https://github.com/guard/guard) first.

Install the gem with:

```bash
gem install guard-less
```

Add an initial setup to your Guardfile with:

```bash
guard init less
```

## Usage

Please read [Guard usage doc](https://github.com/guard/guard#readme).

## Guardfile

```ruby
guard :less, all_on_start: true, all_after_change: true do
  watch %r{^.*\.less$}
end
```

Please read [Guard doc](https://github.com/guard/guard#readme) for more info about Guardfile DSL.

## Options

```ruby
all_after_change: [true|false]   # run on all files after any changed files
                                    # default: true

all_on_start: [true|false]       # run on all the files at startup
                                    # default: true

output: 'relative/path'          # base directory for output CSS files; if unset,
                                    # .css files are generated in the same directories
                                    # as their corresponding .less file
                                    # default: nil

import_paths: ['lib/styles']     # an array of additional load paths to pass to the
                                 # LESS parser, used when resolving `@import`
                                 # statements
                                 # default: [] (see below)

compress: true                   # minify output

yuicompress: true                # minify output using yui
```

### Output option

By default, `.css` files will be generated in the same directories as their
corresponding `.less` files (partials beginning with `_` are always excluded).
To customize the output location, pass the `:output` option as described above,
and be sure to use a match group in the regular expression in your watch to
capture nested structure that will be preserved, i.e.

```ruby
guard :less, output: 'public/stylesheets' do
  watch %r{^app/stylesheets/(.+\.less)$}
end
```

will result in `app/stylesheets/forums/main.less` producing CSS at
`public/stylesheets/forums/main.css`.

### Import paths option

As each `.less` file is parsed, the directory containing the file is
automatically prepended to the import paths, so imports relative to your watched
dirs like `@import 'shared/_type-styles'` should always work. You can supply
additional paths with this option so that, for the `['lib/styles']` example, a
file at `lib/styles/reset.less` could be imported without a qualified path as
`@import 'reset'`.

## Author

[Brendan Erwin](https://github.com/brendanjerwin) ([@brendanjerwin](http://twitter.com/brendanjerwin), [brendanjerwin.com](http://brendanjerwin.com))

## Maintainer

[Rémy Coutable](https://github.com/rymai) ([@rymai](http://twitter.com/rymai), [rym.ai](http://rym.ai))

## Contributors

[https://github.com/guard/guard-less/graphs/contributors](https://github.com/guard/guard-less/graphs/contributors)
