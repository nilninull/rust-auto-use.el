(defun rust-auto-use ()
  (interactive)
  (save-excursion
    (rust-auto-use/insert-use-line (rust-auto-use/deduce-use-line))))

(global-set-key (kbd "C-<f11>") 'rust-auto-use)


(defun rust-auto-use/insert-use-line (use-line)
  (save-excursion
    (beginning-of-buffer)
    (while (or (looking-at "/")
               (looking-at "extern"))
      (forward-line)
      (beginning-of-line))

      (insert use-line)
      (newline)
      (if (and (not (looking-at "[[:space:]]*$"))
               (not (looking-at "use ")))
          (newline))))


  (defun rust-auto-use/deduce-use-line ()
    (let ((symbol (symbol-at-point)))
      (let ((cached-result (gethash symbol rust-auto-use/symbol-cache)))
        (if cached-result
            cached-result
          (rust-auto-use/save-result symbol (rust-auto-use/parse-import-string-from-symbol symbol))))))


(defun rust-auto-use/parse-import-string-from-symbol (symbol)
  (format "use %s::%s;" (read-string (format "import %s from? " symbol)) symbol))


(defun rust-auto-use/save-result (symbol result)
  (progn
    (puthash symbol result rust-auto-use/symbol-cache)
    (rust-auto-use/dump-symbol-cache))
  result
  )

(defvar rust-auto-use-cache-filename "~/.emacs.d/.rust-auto-use-cache")

(defun rust-auto-use/dump-symbol-cache ()
  (with-temp-file rust-auto-use-cache-filename
    (emacs-lisp-mode)
    (insert ";; this file was automatically generated by rust-auto-use.el")
    (newline)
    (insert "(setq rust-auto-use/symbol-cache (make-hash-table :test 'equal))")
    (newline)
    (maphash (lambda (key value)
               (insert (format "(puthash \"%s\" \"%s\" rust-auto-use/symbol-cache)" key value))
               (newline))
             rust-auto-use/symbol-cache)
    rust-auto-use/symbol-cache))

(defun rust-auto-use/load-symbol-cache ()
  (load rust-auto-use-cache-filename t)
  (if (not (boundp 'rust-auto-use/symbol-cache))
      (setq rust-auto-use/symbol-cache (make-hash-table :test 'equal))))

(rust-auto-use/load-symbol-cache)

(provide 'rust-auto-use)
