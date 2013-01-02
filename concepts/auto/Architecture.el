(TeX-add-style-hook "Architecture"
 (lambda ()
    (LaTeX-add-labels
     "sec:intro"
     "sec:predictor"
     "sec:forwardmodel"
     "eq:forwardmodel"
     "fig:mousemoving"
     "fig:archofnextarm"
     "sec:grangercausality"
     "sec:inversemodel"
     "eq:reversemodel"
     "sec:actor"
     "sec:activelearning"
     "eq:actormath")
    (TeX-run-style-hooks
     "graphicx"
     "latex2e"
     "art10"
     "article")))

