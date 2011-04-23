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

    guard 'less', :all_on_start => true, :all_after_pass => true do
      watch(/.*\.less$/)
    end

Please read [Guard doc](https://github.com/guard/guard#readme) for more info about Guardfile DSL.

## Options

    :all_after_pass => false   # don't run on all files after changed files pass, default: true
    :all_on_start => false     # don't run on all the specs at startup, default: true

# License

**Copyright (c) 2011 Brendan Erwin**

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
