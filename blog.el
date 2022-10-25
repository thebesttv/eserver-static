;;; /blog

;;; most important functions
;;; - `org-html-template'
;;; - `org-html-inner-template'

(message "ESS: blog.el")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Dependencies
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; org publish
(require 'org)
(require 'ox-publish)

;; for citation
(use-package citeproc)
(require 'oc-csl)

(require 'font-lock)
(use-package htmlize)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Global variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq ess-raw-url
      "<a href=\"https://github.com/thebesttv/thebesttv.github.io/blob/main/%s\">%s</a>")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Fix org-mode Chinese spacing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; 下面一段是 zwz 的, 作者声明只适应 org-mode 8.0 以及以上版本
(defun clear-single-linebreak-in-cjk-string (string)
  "clear single line-break between cjk characters that is usually soft line-breaks"
  (let* ((regexp "\\([\u4E00-\u9FA5]\\)\n\\([\u4E00-\u9FA5]\\)")
         (start (string-match regexp string)))
    (while start
      (setq string (replace-match "\\1\\2" nil nil string)
            start (string-match regexp string start))))
  string)

(defun ox-html-clear-single-linebreak-for-cjk (string backend info)
  (when (org-export-derived-backend-p backend 'html)
    (clear-single-linebreak-in-cjk-string string)))

(defun tbt-org-fix-chinese-spacing ()
  (require 'ox)
  (unless (and (boundp 'org-chinese-spacing-fixed)
               org-chinese-spacing-fixed)
    (setq org-chinese-spacing-fixed t)
    (add-to-list 'org-export-filter-final-output-functions
                 'ox-html-clear-single-linebreak-for-cjk)))

(tbt-org-fix-chinese-spacing)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Preamble, postamble, head
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
            ;; link to home
            (format "<a href=\"%s%s\">Home</a>\n"
                    (s-repeat level "../")
                    "index.html")
            ;; search block
            "<div id=\"search\"></div>\n"
            "<hr>\n"
            "</nav>\n")))

(defun ess-html-link (rel type href &optional level)
  (if (null level)
      ;; remove link, no level
      (format "<link rel=\"%s\" type=\"%s\" href=\"%s\">\n"
              rel type href)
    ;; local link, with level
    (format "<link rel=\"%s\" type=\"%s\" href=\"%s%s\">\n"
            rel type (s-repeat level "../") href)))

(defun ess-html-favicon (path level)
  (ess-html-link "icon" "image/x-icon" path level))

(defun ess-html-css (path &optional level)
  (ess-html-link "stylesheet" "text/css" path level))

(defun ess-html-head-pagefind (level)
  (concat "<!-- pagefind -->\n"
          (ess-html-css "_pagefind/pagefind-ui.css" level)
          (format "<script src=\"%s%s\" type=\"text/javascript\"></script>\n"
                  (s-repeat level "../") "_pagefind/pagefind-ui.js")
          "<script>
  window.addEventListener('DOMContentLoaded', (event) => {
      new PagefindUI({element: \"#search\", showImages: false, resetStyles: false});
  });
</script>\n"))

(defun ess-html-head (org-html--build-head &rest args)
  "Add some more headlines."
  (let* ((info (car args))
         (pair (ess-input-file-level info))
         (input-file (car pair))
         (level (cdr pair)))
    (concat ess-google-tag
            "<!-- favicon -->\n"
            (ess-html-favicon "favicon.ico" level)
            (apply org-html--build-head args)
            "<!-- CSS -->\n"
            (ess-html-css "https://unpkg.com/latex.css/style.css")
            (ess-html-css "css/org-default.css" level)
            (ess-html-css "css/style.css" level)
            (ess-html-head-pagefind level)
            )))

(advice-add 'org-html--build-head :around #'ess-html-head)

(defun ess-html-inner-template (org-html-inner-template contents info)
  "Add <hr> tag before CONTENTS"
  (let ((args (list (concat "<hr style=\"width: 80%;\">\n"
                            contents) info)))
    (apply org-html-inner-template args)))

(advice-add 'org-html-inner-template
            :around #'ess-html-inner-template)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Process produced HTML doc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ess/blog-html-template (org-html-template &rest args)
  (replace-regexp-in-string
   (regexp-quote "\u200B") ""           ; remove ZERO WIDTH SPACE
   (apply org-html-template args)))

(advice-add 'org-html-template
            :around #'ess/blog-html-template)

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
           (format "#+attr_html: :width %s%% :style margin-left: auto; margin-right: auto;" $1)
           (when (and (stringp $2) (not (string-empty-p $2)))
             (format "\n#+attr_latex: :width %s" $2)))))
  ;; usage: {{{fig(aption, name, [html-width], [latex-width])}}}
  (ess-org-macro
   "fig"
   '(eval (concat
           ;; name & caption
           (format "#+caption: %s\n#+name: %s" $1 $2)
           ;; html-width
           (when (and (stringp $3) (not (string-empty-p $3)))
             (format "\n#+attr_html: :width %s%% :style margin-left: auto; margin-right: auto;" $3))
           ;; latex-width
           (when (and (stringp $4) (not (string-empty-p $4)))
             (format "\n#+attr_latex: :width %s" $4)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; publishing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; No timestamp checking, always publish all files
(setq org-publish-use-timestamps-flag nil)

;;; Evaluate codeblocks without confirmation when export
(setq org-confirm-babel-evaluate nil)
;;; Use smart quotes on export
(setq org-export-with-smart-quotes t)

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
         :language "zh-CN"

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
