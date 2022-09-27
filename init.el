(defun ess-new-post ()
  "Insert header to an empty org file.

When done, point is at end of #+title:.  When title is completed,
use C-SPC to jump to the end"
  (interactive)
  (unless (string-suffix-p ".org" buffer-file-name)
    (error "Buffer is not .org file"))
  (save-excursion
    (insert (concat "#+title: \n"
                    (format "#+date: %s\n"
                            (format-time-string
                             "<%Y-%m-%d %a %H:%M>" (current-time)))
                    "#+author: thebesttv\n"))
    (set-mark (point)))
  (move-end-of-line 1))
