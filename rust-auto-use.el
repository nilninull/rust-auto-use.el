;;; rust-auto-use.el --- Automatically inserts Rust `use` lines

;;; Homepage: https://github.com/vmalloc/rust-auto-use.el

;;; Version: 0.1.0

;;; Commentary:
;; Given a current symbol, this package allows developers to automatically insert Rust `use` statements for importing the symbol.

;;; Code:

(defvar rust-auto-use--symbol-cache)

(defvar rust-auto-use-cache-filename (concat user-emacs-directory "e.rust-auto-use-cache"))

(defun rust-auto-use ()
  "Attempts to insert a required `use` statement for the symbol at point."
  (interactive)
  (save-excursion (rust-auto-use--insert-use-line (rust-auto-use--deduce-use-line))))

(global-set-key (kbd "C-<f11>") 'rust-auto-use)


(defun rust-auto-use--insert-use-line (use-line)
  "Insert the actual use line USE-LINE into the code."
  (save-excursion
    (goto-char (point-min))
    (if (not (search-forward-regexp "^use" nil t))
        (progn (while (or (looking-at "/")
                          (looking-at "extern"))
                 (forward-line)
                 (beginning-of-line))
               (newline)
               (forward-line -1)))
    (end-of-line)
    (newline)
    (insert use-line)))

(defun rust-auto-use--deduce-use-line ()
  "Attempt to deduce which line to insert based on the cached values.  If none is found, prompt the user to enter the module to use."
  (let ((symbol (symbol-at-point)))
    (let ((cached-result (gethash symbol rust-auto-use--symbol-cache)))
      (if cached-result cached-result (rust-auto-use--cache-result symbol (format "use %s::%s;"
                                                                                (read-string (format
                                                                                              "import
 %s from? " symbol)) symbol))))))



(defun rust-auto-use--cache-result (symbol result)
  "Cache a use-line RESULT for a given symbol SYMBOL for future use."
  (progn (puthash symbol result rust-auto-use--symbol-cache)
         (rust-auto-use--dump-symbol-cache))
  result)


(defun rust-auto-use--dump-symbol-cache ()
  "Save the symbol cache to file."
  (with-temp-file rust-auto-use-cache-filename (emacs-lisp-mode)
                  (insert ";; this file was automatically generated by rust-auto-use.el")
                  (newline)
                  (insert "(setq rust-auto-use--symbol-cache (make-hash-table :test 'equal))")
                  (newline)
                  (maphash (lambda (key value)
                             (insert (format "(puthash \"%s\" \"%s\" rust-auto-use--symbol-cache)"
                                             key value))
                             (newline)) rust-auto-use--symbol-cache) rust-auto-use--symbol-cache))

(defun rust-auto-use--load-symbol-cache ()
  "Load the symbol cache from a file."
  (load rust-auto-use-cache-filename t)
  (if (not (boundp 'rust-auto-use--symbol-cache))
      (setq rust-auto-use--symbol-cache (make-hash-table :test 'equal))))


(rust-auto-use--load-symbol-cache)

(provide 'rust-auto-use)

;;; rust-auto-use.el ends here
