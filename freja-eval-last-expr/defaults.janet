(import freja/default-hotkeys :as dh)

(import ./freja-eval-last-expr :as fele)

(dh/set-key dh/gb-binds
            [:control :enter]
            (comp dh/reset-blink fele/eval-last-expr))

(dh/set-key dh/gb-binds
            [:control :shift :enter]
            (comp dh/reset-blink fele/eval-last-expr-2))
