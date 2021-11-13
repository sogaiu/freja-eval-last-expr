(import freja/new_gap_buffer :as gb)
(import freja/state)
(import freja/default-hotkeys :as dh)

(import freja/evaling)
(import ./last-expression :as lexpr)

# XXX: for investigation
(defn current-gb
  []
  (get-in state/editor-state [:left-state :editor :gb]))

(varfn point
  [gb]
  (gb :caret))

(varfn char-after
  [gb i]
  (gb/gb-nth gb i))

(varfn goto-char
  [gb i]
  (gb/put-caret gb i))

(varfn beginning-of-buffer?
  [gb]
  (= (gb :caret) 0))

(varfn backward-line
  [gb]
  (let [curr-line (gb/index-start-of-line gb (gb :caret))
        # checking not at beginning of buffer not needed
        prev-line (gb/index-start-of-line gb (dec curr-line))]
    (put gb :caret prev-line)))

(comment

  # XXX: assumes more than one line in buffer
  (let [gb (current-gb)
        original (point gb)
        lines (gb :lines)]
    (var somewhere nil)
    (while true
      (set somewhere
           # XXX: seed somewhere else?
           (math/rng-int (math/rng (os/cryptorand 8))
                         (gb/gb-length gb)))
      (when (> somewhere (first lines))
        (break)))
    (goto-char gb somewhere)
    # XXX
    (tracev somewhere)
    (tracev (def someline-number
      (gb/current-line-number gb)))
    #
    (backward-line gb)
    (tracev (def prevline-number
      (gb/current-line-number gb)))
    #
    (defer (goto-char gb original)
      (= (dec someline-number)
         prevline-number)))
  # => true

 )

(varfn begin-of-top-level
  [gb]
  # XXX: necessary?
  (-> gb gb/commit!)
  (defn begin-of-top-level-char?
    [char]
    (def botl-chars
      {(chr "(") true
       (chr "~") true
       (chr "'") true})
    (get botl-chars char))
  #
  (when (not (beginning-of-buffer? gb))
    (var pos (point gb))
    (gb/beginning-of-line gb)
    (if (begin-of-top-level-char? (char-after gb (point gb)))
      (set pos (point gb))
      (while true
        (backward-line gb)
        (cond
          (begin-of-top-level-char? (char-after gb (point gb)))
          (do
            (set pos (point gb))
            (break))
          #
          (beginning-of-buffer? gb)
          (break))))
    (goto-char gb pos)))

(varfn get-last-expr
  [gb]
  (def current (point gb))
  # restore the caret at the end
  (defer (goto-char gb current)
    (def end (point gb))
    # find the containing top-level construct - start of region
    #(backward-line gb)
    (begin-of-top-level gb)
    (def start (point gb))
    # try to detect the last expression
    (def region
      (string/slice (gb/content gb) start end))
    (print region)
    (lexpr/last-expr region)))

(varfn eval-last-expr
  [gb]
  (def expr (get-last-expr gb))
  (evaling/eval-it state/user-env
                   expr)
  gb)

(put-in dh/gb-binds
        [:control :enter]
        (comp dh/reset-blink eval-last-expr))
