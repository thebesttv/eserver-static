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
      "<a href=\"https://raw.githubusercontent.com/thebesttv/thebesttv.github.io/main/%s\">%s</a>")

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
                      (cons "org-left"
                            (format ess-raw-url
                                    input-file
                                    (file-name-nondirectory input-file))))))
              )))))

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
;;; Info manual
;;;
;;; The original functions link to a mono info page (a single HTML page
;;; containing all the nodes).  Two functions are modified here so they
;;; link to a smaller HTML page (one page per node).
;;;
;;; Link to the Top page of a manual, e.g. the Org manual:
;;;   https://www.gnu.org/software/emacs/manual/html_node/org/
;;; Link to a node in the manual, e.g. the User-Input node of the Emacs manual:
;;;   https://www.gnu.org/software/emacs/manual/html_node/emacs/User-Input.html
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'ol-info)

(defun org-info-map-html-url (filename)
  "Return URL or HTML file associated to Info FILENAME.
If FILENAME refers to an official GNU document, return a URL pointing to
the official page for that document, e.g., use \"gnu.org\" for all Emacs
related documents.  Otherwise, append \".html\" extension to FILENAME.
See `org-info-emacs-documents' and `org-info-other-documents' for details."
  (cond ((member filename org-info-emacs-documents)
	 (format "https://www.gnu.org/software/emacs/manual/html_node/%s"
		 filename))
	((cdr (assoc filename org-info-other-documents)))
	(t (concat filename ".html"))))

(defun org-info-export (path desc format)
  "Export an info link.
See `org-link-parameters' for details about PATH, DESC and FORMAT."
  (let* ((parts (split-string path "#\\|::"))
	 (manual (car parts))
	 (node (or (nth 1 parts) "Top")))
    (pcase format
      (`html
       (let ((url (org-info-map-html-url manual))
             (node-name (org-info--expand-node-name node)))
         (format "<a href=\"%s/%s\">%s</a>"
	         url
                 (if (string= node-name "Top")
                     ;; the top page, add nothing
                     ""
                   ;; a specific node, add node-name.html
                   (concat node-name ".html"))
	         (or desc path))))
      (`texinfo
       (let ((title (or desc "")))
	 (format "@ref{%s,%s,,%s,}" node title manual)))
      (_ nil))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Sitemap
;;;
;;; Sort sitemap using file system's modification date.
;;; `org-publish-find-date' is used to retrieve the date of a file.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun org-publish-find-date (file project)
  "Find the date of FILE in PROJECT.
This function assumes FILE is either a directory or an Org file.
Return the file system's modification time in `current-time'
format."
  (let ((file (org-publish--expand-file-name file project)))
    (if (file-directory-p file)
        ;; for directory
	(file-attribute-modification-time (file-attributes file))
      ;; for org file
      (cond ((file-exists-p file)
	     (file-attribute-modification-time (file-attributes file)))
	    (t (error "No such file: \"%s\"" file))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; publishing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; No timestamp checking, always publish all files
(setq org-publish-use-timestamps-flag nil)

;;; Evaluate codeblocks without confirmation when export
(setq org-confirm-babel-evaluate nil)
;;; Use smart quotes on export
(setq org-export-with-smart-quotes t)

;;; Exclude sitemap from pagefind
(setq ess-exclude-sitemap-begin
      (concat
       "# exclude sitemap from pagefind processing by wrapping it around a div\n"
       "# block tagged with \"data-pagefind-ignore\"\n"
       "#+begin_export html\n"
       "<div data-pagefind-ignore=\"all\" class=\"sitemap-list\">\n"
       "#+end_export\n"))

(setq ess-exclude-sitemap-end
      (concat
       "\n"
       "#+begin_export html\n"
       "</div>\n"
       "#+end_export\n"))

(defun ess-sitemap-function (title list)
  (require 'ox-org)            ; needed for org backend
  ;; do not add title, only export the list
  (concat
   ess-exclude-sitemap-begin
   ;; preserve '@@html:...@@' exports using the raw parameter
   (org-list-to-generic list '(:backend org :raw t))
   ess-exclude-sitemap-end))

(defun ess-sitemap-format-entry (entry style project)
  "Format for each site map ENTRY, as a string.
For list style, add timestamp and dir name.  Otherwise, use the
default implementation."
  (if (eq style 'list)
      (let ((title (org-publish-find-title entry project))
            ;; Inner dir name, usually in the form of "content/xxx/".
            ;; Will be nil when entry has no dir name.
            (dir-name (string-remove-suffix
                       "/" (string-remove-prefix
                            "content/" (file-name-directory entry))))
            (date (org-publish-find-date entry project)))
        (s-replace
         ;; Merge consecutive inline HTML exports into one.  The
         ;; consecutive exports are in the form of:
         ;;   '@@html:...@@·@@html:...@@'
         ;; The '·' in between the two exports is only for visual
         ;; separation.  After merging, the '@@·@@html:' in the middle
         ;; is removed.
         "@@@@html:" ""
         (concat
          "@@html:<span>@@"
          ;; link to post
          (format "[[file:%s][%s]]" entry title)
          ;; directory name, grayed out
          (when (and (stringp dir-name)
                     (not (string-empty-p dir-name)))
            (concat
             "@@html:<span style=\"color:gray\">@@"
             " (" dir-name ")" ; use space to separate link and dir name
             "@@html:</span>@@"))
          "@@html:</span>@@"

          ;; modification time, right aligned
          "@@html:<span>@@"
          (format-time-string "%Y-%m-%d %H:%M" date)
          "@@html:</span>@@")))
    (org-publish-sitemap-default-entry entry style project)))

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
         ;; export sitemap as a list instead of a tree, so that newly
         ;; modified posts always appear on top
         :sitemap-style list
         ;; function to generate the sitemap Org file
         :sitemap-function ess-sitemap-function
         ;; sort files from newest to oldest
         :sitemap-sort-files anti-chronologically
         ;; format each sitemap entry
         :sitemap-format-entry ess-sitemap-format-entry
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
