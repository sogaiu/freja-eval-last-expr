(import freja/main)
(import freja/frp)
(import freja/events :as e)
(import freja/default-hotkeys :as dh)
(import freja/state)
(import freja/new_gap_buffer :as gb)
(import ../freja-eval-last-expr/eval-last-expression :as lexpr)

(defn tap
  [k & body]
  [@[:key-down k]
   ;body
   @[:key-release k]])

(defn chars
  [s]
  (map (fn [c]
         @[:char (keyword (string/from-bytes c))]) s))

(def calc-code
  ``
  (+ 2
     (* 2
        (* 3 1)))
  ``  )

(var commands
  @[;(tap
       :left-control
       ;(tap :end))
    ;(chars calc-code)])

(defn run-commands
  [& _]
  (print "running commands")
  (ev/spawn
    (ev/sleep 0.2)
    (loop [c :in commands]
      (ev/sleep 0.000001) # this means we will get ~1 input per frame
      (print "pushing c: ")
      (pp c)
      (if (= :char (first c))
        (e/push! frp/chars @[;c])
        (e/push! frp/keyboard @[;c])))
    (ev/sleep 0.00001)
    (def expr
      (lexpr/get-last-expr-2 (lexpr/current-gb)))
    (lexpr/eval-last-expr-2 (lexpr/current-gb))
    (def result
      (get (e/pop state/eval-results) :value))
    (with-dyns [:out stdout]
      (def more-code "(+ 2 3)")
      (if (and (= (tracev expr)
                  (tracev calc-code))
               (= (tracev result)
                  (tracev (eval-string calc-code))))
        (do
          (print "tests successful\n------------------------------")
          (os/exit 0))
        (do (print "!!! tests failed !!!\n------------------------------")
          (os/exit 1))))))

(main/main nil nil "--no-init")

(run-commands)
