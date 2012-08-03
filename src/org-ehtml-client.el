;;; org-ehtml-client.el -- export of Org-mode to editable HTML

;; Copyright (C) 2012 Eric Schulte <eric.schulte@gmx.com>

;; Author: Eric Schulte <eric.schulte@gmx.com>
;; Keywords: org elnode javascript html

;; This file is not (yet) part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:
(require 'org-export)
(require 'org-element)
(require 'org-e-html)
(require 'org-ehtml-util)

(defvar org-ehtml-client-style
  (concat
   "<style type=\"text/css\">\n<!--/*--><![CDATA[/*><!--*/\n"
   (file-contents (expand-file-name "org-ehtml-client.css" org-ehtml-base))
   "/*]]>*/-->\n</style>"))

(defvar org-ehtml-client-jquery
  "https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js")

(defvar org-ehtml-client-scripts
  (concat
   "<script type=\"text/javascript\" src=\""
   org-ehtml-client-jquery "\"></script>"
   "<script type=\"text/javascript\">\n<!--/*--><![CDATA[/*><!--*/\n"
   (file-contents (expand-file-name "org-ehtml-client.js" org-ehtml-base))
   "/*]]>*///-->\n</script>\n"))

(defvar org-ehtml-client-wrap-template
  (concat
   "<div class=\"edit_in_place\">%html-text</div>"
   "<div class=\"raw-org\" contents-begin=\"%begin\" contents-end=\"%end\">"
   "%org-text</div>"))

(defun org-ehtml-client-editable-p (element info)
  (let ((parent (org-export-get-parent element)))
    (cond ((eq (car parent) 'headline)
           (member "ehtml" (org-export-get-tags parent info)))
          ((eq (car parent) 'org-data)
           (member "EDITABLE"
                   (mapcar (lambda (it) (plist-get (cadr it) :key))
                           (remove-if-not (lambda (it) (equal 'keyword (car it)))
                                          (cdaddr parent)))))
          ((member (car parent) '(paragraph plain-list)) nil)
          (t (org-ehtml-client-editable-p parent info)))))

(defmacro def-ehtml-wrap (e-html-function)
  "Defines and returns an ehtml-wrapped version of E-HTML-FUNCTION."
  (let ((fname (intern (concat "org-ehtml-client"
                               (substring (symbol-name e-html-function) 10)))))
    `(defun ,fname (element contents info)
       ,(format "ehtml wrapper around `%s'." e-html-function)
       (let* ((original-contents (copy-seq contents))
              (original-info     (copy-seq info))
              (html-text (,e-html-function element contents info))
              (org-text  (or (org-element-interpret-data element)
                             original-contents
                             (error "no org-text found for %s" (car element)))))
         (push info my-info)
         (if (org-ehtml-client-editable-p element info)
             (org-fill-template org-ehtml-client-wrap-template
              `(("html-text" . ,html-text)
                ("org-text"  . ,org-text)
                ("begin"     . ,(number-to-string
                                 (plist-get (cadr element) :begin)))
                ("end"       . ,(number-to-string
                                 (plist-get (cadr element) :end)))))
           html-text)))))

(eval `(org-export-define-derived-backend ehtml e-html
         :translate-alist
         ((paragraph   . ,(def-ehtml-wrap org-e-html-paragraph))
          (plain-list  . ,(def-ehtml-wrap org-e-html-plain-list))
          (table       . ,(def-ehtml-wrap org-e-html-table))
          (verbatim    . ,(def-ehtml-wrap org-e-html-verbatim))
          (quote-block . ,(def-ehtml-wrap org-e-html-quote-block))
          ;; (src-block   . ,(def-ehtml-wrap org-e-html-src-block))
          (verse-block . ,(def-ehtml-wrap org-e-html-verse-block)))))

(defun org-ehtml-client-export-to-html
  (&optional subtreep visible-only body-only ext-plist pub-dir)
  "Export current buffer to an editable HTML file."
  (interactive)
  (let* ((extension (concat "." org-e-html-extension))
	 (file (org-export-output-file-name extension subtreep pub-dir))
	 (org-export-coding-system org-e-html-coding-system)
         ;; custom headers
         (org-e-html-style-extra org-ehtml-client-style)
         (org-e-html-scripts org-ehtml-client-scripts))
    (org-export-to-file 'ehtml file subtreep visible-only body-only ext-plist)))

(defun org-ehtml-client-export-file (file)
  "Export FILE's contents to editable HTML."
  (save-window-excursion
    (find-file file)
    (org-ehtml-client-export-to-html)))

(provide 'org-ehtml-client)
;;; org-ehtml-client.el ends here
