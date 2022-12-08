;;; EServer, but Static

(message "ESS: main.el")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Dependencies
;;;   Setup package source and install `use-package'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'package)
(if (string= (getenv "ELPA_SRC") "no_mirror")
    (progn
      (message "No mirror is used")
      (add-to-list 'package-archives
                   '("melpa" . "https://melpa.org/packages/") t))
  (message "Use tsinghua tuna mirror")
  (setq package-archives
        '(("gnu" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
	  ("melpa" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")
	  ("org" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/org/"))))
(package-initialize)

;;; install `use-package' if not already installed
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t) ; always ensure packages are installed

;;; string manipulation
(require 'subr-x)
(use-package s)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; parse arguments, get source and target
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; ess: EServer Static
(setq ess-source-dir nil
      ess-target-dir nil)

(setq ess-google-tag
      "<!-- Google tag (gtag.js) -->
<script async src=\"https://www.googletagmanager.com/gtag/js?id=G-21YM95T3BQ\"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-21YM95T3BQ');
</script>\n")

;;; parse arguments, preserving unknown args
(let (result)
  (while argv
    (let ((argi (pop argv)))
      (cond
       ;; source
       ((string-prefix-p "--source=" argi)
        (setq ess-source-dir
              (file-name-as-directory
               (string-remove-prefix "--source=" argi))))
       ;; target
       ((string-prefix-p "--target=" argi)
        (setq ess-target-dir
              (file-name-as-directory
               (string-remove-prefix "--target=" argi))))
       (t
        (if (string-prefix-p "--load=" argi)
            (message "Load: %s" (string-remove-prefix "--load=" argi))
          (message "Preserving unknown option: %s" argi))
        (push argi result)))))
  (setq argv (reverse result)))

;;; check correctness of source & target dir
(let ((check-dir
       (lambda (prefix dir)
         (if (and (file-name-absolute-p dir) ; must be absolute
                  (string-suffix-p "/" dir)  ; must end with "/"
                  (file-directory-p dir))    ; must be an existing directory
             (message "%s: %s" prefix dir)
           (error "%s is not an existing proper directory" prefix)))))
  (funcall check-dir "Source" ess-source-dir)
  (funcall check-dir "Target" ess-target-dir))
