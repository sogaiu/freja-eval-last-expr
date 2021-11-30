# freja-eval-last-expr

Alternative evaluate last expression support for the freja editor.

## Prerequisites

The [freja editor](https://github.com/saikyun/freja).

## Setup

0. Clone this repository somewhere and cd to the resulting directory
1. Start freja with: `freja ./freja-eval-last-expr/eval-last-expression.janet`
2. `Control+L` to load the file

## Example Usage

1. In freja's buffer window, type some code that could be evaluated
   successfully, e.g.:
    ```
    (+ 1 1)
    ```

2. With the cursor after the closing paren, press the key sequence
   `Control+Enter`.

3. Observe in the console or the echoer area at the bottom of freja's
   window, the following sort of output:
    ```
    => (+ 1 1)
    2
    ```

## Explanation

In this version, `Control+Enter` invokes the function `eval-last-expr`
which:

* Determines a region of text containing (but not necessarily limited
  to) the expression immediately preceding the cursor
* Analyzes the region to determine a "last expression"
* Hands the determined expression off for evaluation

Note that the code relies on a [Left Margin Convention](https://www.gnu.org/software/emacs/manual/html_node/emacs/Left-Margin-Paren.html) for Janet code.  Briefly, this means that in one's Janet code the presence of a left paren, single quote, or a tilde in the left-most column always indicates the beginning of a top-level form.

## Tests

There are tests than can be run by `jpm test`.

One set of tests runs tests inside freja while the other uses
[judge-gen](https://github.com/sogaiu/judge-gen) to test supporting
code.

