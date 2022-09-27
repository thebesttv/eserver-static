;;; EServer, but Static

;;; most important functions
;;; - `org-html-template'
;;; - `org-html-inner-template'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; prepare needed packages
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

(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t) ; always ensure packages are installed

;; string manipulation
(require 'subr-x)
(use-package s)

;; org publish
(require 'org)
;; (require 'ox)
(require 'ox-publish)

;; for citation
(use-package citeproc)
(require 'oc-csl)

(require 'font-lock)
(use-package htmlize)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; parse arguments, get source and target
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; ess: EServer Static
(setq ess-source-dir nil
      ess-target-dir nil)
(setq ess-raw-url
      "<a href=\"https://github.com/thebesttv/thebesttv.github.io/blob/main/%s\">%s</a>")
(setq ess-google-tag
      "<!-- Google tag (gtag.js) -->
<script async src=\"https://www.googletagmanager.com/gtag/js?id=G-06N8YBQEG3\"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-06N8YBQEG3');
</script>\n")

;;; parse arguments
(while argv
  (let ((argi (pop argv)))
    (cond
     ((string-prefix-p "--source=" argi)
      (setq ess-source-dir
            (file-name-as-directory
             (string-remove-prefix "--source=" argi))))
     ((string-prefix-p "--target=" argi)
      (setq ess-target-dir
            (file-name-as-directory
             (string-remove-prefix "--target=" argi))))
     (t
      (message "Unknown option: %s" argi)))))

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pre/post-amble, head
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ess-input-file-level (info)
  "Return a cons pair of input file and its nested level."
  (let* ((input-file (string-remove-prefix
                     ess-source-dir
                     (plist-get info :input-file)))
         (level (s-count-matches "/" input-file)))
    (cons input-file level)))

(defun ess-html-table (class rows)
  "Builds a HTML table.

CLASS should be a string to be inserted in <table class=...>.  If it is nil, the table has no class.

ROWS is a list of rows.  Each row is surrounded by <tr>...</tr>.
It can be obtained from `ess-html-table-row'."
  (concat (if class
              (format "<table class=\"%s\">\n" class)
            "<table>\n")
          (mapconcat (lambda (row)
                       (concat "  <tr>" row "</tr>"))
                     rows "\n")
          "\n</table>"))

(defun ess-html-table-row (pairs)
  "Builds a row to be used in a HTML table.

Each column in the returned row is surrounded by <td class=...>...</td>.

PAIRS is a list of cons pairs of the form (class . content)"
  (mapconcat (lambda (pair)
               (format "<td class=\"%s\">%s</td>" (car pair) (cdr pair)))
             pairs ""))

;; (ess-html-table-row '(("org-right" . "1")
;;                       ("org-left" . "2")))
;; => "<td class=\"org-right\">1</td><td class=\"org-left\">2</td>"

;; (ess-html-table "postamble" '("r1" "r2" "r3")) =>
;; "<table class=\"postamble\">
;;   <tr>r1</tr>
;;   <tr>r2</tr>
;;   <tr>r3</tr>
;; </table>"

(defun ess-html-postamble (info)
  "Returns a table to be used as postamble.

Mose entries have the same format as in
`org-html-postamble-format'.  They are generated just as in
`org-html--build-pre/postamble', by getting `spec' from `info',
and calling `format-spec'.

Entries:
- Author: %a
- Created: %d
- Modified: %C
- Generated: %T
- Version: %c
- Raw: link to the raw .org file, obtained from property
  `:input-file' in `info'.
"
  (let* ((spec (org-html-format-spec info))
         (input-file (car (ess-input-file-level info))))
    (concat "<hr>"
            (ess-html-table
             "postamble"
             ;; append two different rows
             (append
              ;; 1. rows interpreted from `spec', same as in
              ;; `org-html-postamble-format'
              (mapcar (lambda (pair)
                        (ess-html-table-row
                         (list (cons "org-right" (car pair))
                               (cons "org-left" (format-spec (cdr pair) spec)))))
                      '(("Author"    . "%a")
                        ("Created"   . "%d")
                        ("Modified"  . "%C")
                        ("Generated" . "%T")
                        ("Version"   . "%c")))
              ;; 2. rows directly built from properties in `info', such
              ;; as `:input-file'
              (list
               (ess-html-table-row
                (list (cons "org-right" "Raw")
                      (cons "org-left" (format ess-raw-url
                                               input-file input-file))))))))))

(defun ess-html-preamble (info)
  (let* ((pair (ess-input-file-level info))
         (input-file (car pair))
         (level (cdr pair)))
    (concat "<nav class=\"org-center\">\n"
            (format "<a href=\"%s%s\">Home</a>\n"
                    (s-repeat level "../")
                    "index.html")
            "</nav>\n")))

(defun ess-local-css (level path)
  (format "<link rel=\"stylesheet\" type=\"text/css\" href=\"%s%s\"/>\n"
          (s-repeat level "../") path))

(defun ess-remote-css (url)
  (format "<link rel=\"stylesheet\" type=\"text/css\" href=\"%s\"/>\n"
          url))

(defun ess-html-head (org-html--build-head &rest args)
  "Add some more headlines."
  (let* ((info (car args))
         (pair (ess-input-file-level info))
         (input-file (car pair))
         (level (cdr pair)))
    (concat (apply org-html--build-head args)
            ;; input-file "\n"
            "<!-- CSS -->\n"
            (ess-remote-css "https://unpkg.com/latex.css/style.css")
            (ess-local-css level "css/org-default.css")
            (ess-local-css level "css/style.css")
            ess-google-tag)))

(advice-add 'org-html--build-head :around #'ess-html-head)

(defun ess-html-inner-template (org-html-inner-template contents info)
  "Add <hr> tag before CONTENTS"
  (let ((args (list (concat "<hr style=\"width: 80%;\">\n"
                            contents) info)))
    (apply org-html-inner-template args)))

(advice-add 'org-html-inner-template
            :around #'ess-html-inner-template)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ess-org-macro (name template)
  (cons name
        (if (stringp template)
            template
          (string-trim (with-output-to-string (print template))))))

(setq
 org-export-global-macros
 (list
  ;; usage: {{{image(html-width, [latex-width])}}}
  ;; - html-width: width in percentage, e.g. 80 means 80%
  ;; - latex-width: optional, e.g. 10cm
  (ess-org-macro
   "image"
   '(eval (concat
           (format "#+attr_html: :width %s%% :style margin-left: auto; margin-right: auto;\n" $1)
           (unless (string-empty-p $2)
             (format "#+attr_latex: :width %s" $2)))))
  ;; usage: {{{fig(aption, name, [html-width], [latex-width])}}}
  (ess-org-macro
   "fig"
   '(eval (concat
           ;; name & caption
           (format "#+caption: %s\n#+name: %s\n" $1 $2)
           ;; html-width
           (unless (string-empty-p $3)
             (format "#+attr_html: :width %s%% :style margin-left: auto; margin-right: auto;\n" $3))
           ;; latex-width
           (unless (string-empty-p $4)
             (format "#+attr_latex: :width %s" $4)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; publishing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; no timestamp checking, always publish all files
(setq org-publish-use-timestamps-flag nil)

(setq org-publish-project-alist
      `(("ess-notes"
         :base-directory ,ess-source-dir
         :base-extension "org"
         :publishing-directory ,ess-target-dir
         :publishing-function org-html-publish-to-html
         :recursive t

         ;;
         ;; Generic properties
         ;;
         :with-toc t

         ;;
         ;; HTML specific properties
         ;;

         :html-head ""
         :html-head-extra ""
         :html-head-include-default-style nil
         :html-head-include-scripts nil

         :html-checkbox-type unicode

         ;; set time format, e.g. 2022-09-25 09:13
         :html-metadata-timestamp-format "%Y-%m-%d %H:%M"

         ;; preamble & postamble
         :html-preamble ess-html-preamble
         :html-postamble ess-html-postamble

         ;; make headlines contain a link to themselves
         :html-self-link-headlines t

         ;; export using HTML5
         :html-doctype "html5"
         ;; enable new block elements introduced with the HTML5 standard
         :html-html5-fancy t

         ;;
         ;; Sitemap
         ;;
         ;; Automatically generates a sitemap to .sitemap.org.  The
         ;; file contains only a list of links, so it can be
         ;; included to any file by simply using:
         ;;   #+include: .sitemap.org
         :auto-sitemap t
         :sitemap-filename ".sitemap.org"
         :sitemap-function (lambda (title list)
                             ;; do not add title, only export the list
                             (concat (org-list-to-org list)))
         ;; sort files from newest to oldest
         :sitemap-sort-files anti-chronologically
         ;; add timestamp
         ;; :sitemap-format-entry
         ;; (lambda (entry style project)
         ;;   (let ((filename (org-publish-find-title entry project)))
         ;;     (if (= (length filename) 0)
         ;;         (format "*%s*" entry)
         ;;       (format "<%s> [[file:%s][%s]]"
         ;;               (format-time-string "%Y-%m-%d"
         ;;                                   (org-publish-find-date entry project))
         ;;               entry
         ;;               filename))))
         )

        ("ess-files"
         :base-directory ,ess-source-dir
         :base-extension any          ; copy all files
         ;; :exclude "^.*\\.\\(org\\)$"  ; exclude files with extension: org
         :publishing-directory ,ess-target-dir
         :recursive t
         :publishing-function org-publish-attachment
         )
        ("ess"
         :components ("ess-notes" "ess-files"))))

(org-publish-all t)
