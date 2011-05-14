;; prefix ar:

;; 作成中

;; setting sample
;;
;; (require 'anything-rdefs)
;; (add-hook 'ruby-mode-hook
;;           (lambda ()
;;             (define-key ruby-mode-map (kbd "C-@") 'anything-rdefs)))


(defvar rdefs-buffer "*rdefs*")
(defvar ar:recenter-height 10)

(unless (executable-find "rdefs")
  (error "rdefs not found"))

(defvar ar:command (executable-find "rdefs"))

(setq anything-c-source-rdefs
  '((name . "rdefs")
    (init . anything-c-rdefs-init)
    (candidates-in-buffer)
    (action . anything-c-rdefs-action)
    ))

(defun anything-rdefs ()
  (interactive)
  (let ((anything-display-function 'ar:display-buffer))
    (letf (((symbol-function 'anything-create-anything-buffer)
            (symbol-function 'ar:anything-create-anything-buffer)))
      (anything-other-buffer '(anything-c-source-rdefs)
                             rdefs-buffer))))

(defun ar:display-buffer (buf)
  (delete-other-windows)
  (split-window (selected-window) nil t)
  (pop-to-buffer buf))

(defun ar:execute-rdefs (file-path)
  (interactive)
  (let ((command ar:command))
        (option "-n"))
    (call-process-shell-command (format "%s %s %s" command file-path option) nil t t)))

(defun anything-c-rdefs-init ()
  (let ((file-path (buffer-file-name)))
                (with-current-buffer (anything-candidate-buffer 'global)
                  (ar:execute-rdefs file-path))))

(defun anything-c-rdefs-action (candidate)
  (ar:awhen (ar:substring-line-number candidate)
         (goto-line (string-to-int it))
         (recenter ar:recenter-height)))

;; utility

(defun ar:substring-line-number (s)
  (when (string-match "\\([0-9]+\\):" s)
    (match-string 1 s)))

(defmacro ar:aif (test-form then-form &optional else-form)
  `(let ((it ,test-form))
     (if it ,then-form ,else-form)))

(defmacro* ar:awhen (test-form &body body)
  `(ar:aif ,test-form
        (progn ,@body)))

(defun ar:anything-create-anything-buffer (&optional test-mode)
  (when test-mode
    (setq anything-candidate-cache nil))
  (with-current-buffer (get-buffer-create anything-buffer)
    (anything-log "kill local variables: %S" (buffer-local-variables))
    (kill-all-local-variables)
    (buffer-disable-undo)
    (erase-buffer)

    (ruby-mode)
    ;;todo linum-mode がない場合の処理
    (linum-mode nil)

    (set (make-local-variable 'inhibit-read-only) t)
    (set (make-local-variable 'anything-last-sources-local) anything-sources)
    (set (make-local-variable 'anything-follow-mode) nil)
    (set (make-local-variable 'anything-display-function) anything-display-function)
    (anything-log-eval anything-display-function anything-let-variables)
    (loop for (var . val) in anything-let-variables
          do (set (make-local-variable var) val))
    (setq cursor-type nil)
    (setq mode-name "Anything"))
  (anything-initialize-overlays anything-buffer)
  (get-buffer anything-buffer))

(provide 'anything-rdefs)