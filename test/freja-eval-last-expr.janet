(import freja/main)
(import freja/frp)
(import freja/events :as e)
(import freja/default-hotkeys :as dh)
(import freja/state)
(import freja/new_gap_buffer :as gb)
(import ../freja-eval-last-expr/eval-last-expression :as lexpr)

(defn chars
  [s]
  (map |@[:char (keyword (string/from-bytes $))]
       s))

# this means we will get ~1 input per frame
(def sleep-dur 0.000001)

(defn type-src
  [src]
  (loop [c :in (chars src)]
    (ev/sleep sleep-dur)
    (e/push! frp/chars @[;c]))
  (ev/sleep sleep-dur))

(defn type-ctrl-end
  []
  (var key-list
    @[@[:key-down :left-control]
      @[:key-down :end]
      @[:key-release :end]
      @[:key-release :left-control]])
  #
  (loop [k :in key-list]
    (ev/sleep sleep-dur)
    (e/push! frp/keyboard k))
  (ev/sleep sleep-dur))

(defn type-enter
  []
  (def key-list
    @[@[:key-down :enter]
      @[:key-release :enter]])
  #
  (loop [k :in key-list]
    (ev/sleep sleep-dur)
    (e/push! frp/keyboard k))
  (ev/sleep sleep-dur))

(defn type-home
  []
  (def key-list
    @[@[:key-down :home]
      @[:key-release :home]])
  #
  (loop [k :in key-list]
    (ev/sleep sleep-dur)
    (e/push! frp/keyboard k))
  (ev/sleep sleep-dur))

(defn type-end
  []
  (def key-list
    @[@[:key-down :end]
      @[:key-release :end]])
  #
  (loop [k :in key-list]
    (ev/sleep sleep-dur)
    (e/push! frp/keyboard k))
  (ev/sleep sleep-dur))

(def tests
  [{:src
    ``
    # multiline expression
    (+ 2
       (* 2
          (* 3 1)))
    ``
    :after type-enter
    :done type-enter
    #
    :expected 8
    :expected-expr
    ``
    (+ 2
       (* 2
          (* 3 1)))
    ``}
   #
   {:src
    ``
    # form as part of comment
    # (+ 9 3)
    ``
    :eval lexpr/eval-last-expr-2
    :get lexpr/get-last-expr-2
    :done |(do (type-enter) (type-enter))
    #
    :expected 12
    :expected-expr "(+ 9 3)"}
   #
   {:src
    ``
    # test evaluation on opening delimiter
    (/ 2 1)

    (* 3 3 3)
    ``
    :after type-home # so evaluation happens at beginning of (* 3 3 3)
    :done |(do (type-end) (type-enter) (type-enter))
    #
    :expected 2
    :expected-expr "(/ 2 1)"}
   #
   {:src
    ``
    # two top-level forms on one line
    (- 3 1) (/ 16 2)
    ``
    :done |(do (type-end) (type-enter))
    #
    :expected 8
    :expected-expr "(/ 16 2)"}])

(def end-chan
  (ev/chan))

(defn red
  [str]
  (string/format "\e[31m%s\e[0m" str))

(defn green
  [str]
  (string/format "\e[32m%s\e[0m" str))

(defn run-commands
  [& _]
  (var results @[])
  (ev/spawn
    (ev/sleep 0.2)
    # get to the end of the buffer
    (type-ctrl-end)
    (type-enter)
    # perform each test
    (print "Running tests")
    (print)
    (var i 0)
    (loop [{:src src
            :after after
            :eval evaluator
            :get getter
            :done done
            :expected expected}
           :in tests]
      (default evaluator lexpr/eval-last-expr)
      (default getter lexpr/get-last-expr)
      #
      (ev/sleep sleep-dur)
      #
      (print (string/repeat "-" 8))
      (printf "Test %d" i)
      (print (string/repeat "-" 8))
      #
      (type-src src)
      #
      (when after
        (after))
      #
      (evaluator (lexpr/current-gb))
      (def result
        (get (e/pop state/eval-results) :value))
      #
      (array/push results
                  {:expr
                   (getter (lexpr/current-gb))
                   :result result})
      #
      (when done
        (done))
      #
      (print (string/repeat "-" 32))
      (print)
      #
      (++ i))
    (print)
    # check the test results
    (with-dyns [:out stdout]
      (def report
        (map (fn [t r]
               (let [expected-expr
                     (or (t :expected-expr) (t :src))]
                 (and (= (t :expected)
                         (r :result))
                      (= expected-expr
                         (r :expr)))))
             tests results))
      (def n-tests
        (length tests))
      (def failed
        (filter false? report))
      (def n-failed
        (length failed))
      (def n-succeeded
        (->> report
             (filter true?)
             length))
      #
      (if (= n-succeeded n-tests)
        (do
          (printf "%s/%d tests succeeded"
                  (green (string/format "%d" n-succeeded))
                  n-tests)
          (print "------------------------------")
          (ev/give end-chan 0))
        (do
          (printf ">> %s/%d tests failed <<"
                  (red (string/format "%d" n-failed))
                  n-tests)
          (print)
          (print "failed tests were:")
          (eachk i failed
            (printf "  %d" i))
          (print "------------------------------")
          (print)
          (ev/give end-chan 1))))))

(main/main nil nil "--no-init")

(run-commands)

(ev/spawn
  # comment out the following to make the gui stay around
  (os/exit (ev/take end-chan)))
