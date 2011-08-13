# Guard-Less

A guard extension that compiles `.less` files to `.css` files when changed.

## Install

You will need to have [Guard](https://github.com/guard/guard) first.

Install the gem with:

    gem install guard-less

Add an initial setup to your Guardfile with:

    guard init less


## Usage

Please read [Guard usage doc](https://github.com/guard/guard#readme).

## Guardfile

    guard 'less', :all_on_start => true, :all_after_change => true do
      watch(%r{^.*\.less$})
    end

Please read [Guard doc](https://github.com/guard/guard#readme) for more info about Guardfile DSL.

## Options

```ruby
:all_after_change => [true|false]   # run on all files after any changed files
                                    # default: true

:all_on_start => [true|false]       # run on all the files at startup
                                    # default: true

:output => 'relative/path'          # base directory for output CSS files; if unset,
                                    # .css files are generated in the same directories
                                    # as their corresponding .less file
                                    # default: nil
```

### Output option

By default, `.css` files will be generated in the same directories as their
corresponding `.less` files (partials beginning with `_` are always excluded).
To customize the output location, pass the `:output` option as described above,
and be sure to use a match group in the regular expression in your watch to
capture nested structure that will be preserved, i.e.

```ruby
guard 'less', :output => 'public/stylesheets' do
  watch(%r{^app/stylesheets/(.+\.less)$})
end
```

will result in `app/stylesheets/forums/main.less` producing CSS at
`public/stylesheets/forums/main.css`.

# License

**Copyright (c) 2011 Brendan Erwin and contributors**

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
