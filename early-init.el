;; early-init.el -*- lexical-binding: t; -*-

;; Emacs HEAD (27+) introduces early-init.el, which is run before init.el,
;; before package and UI initialization happens.

;; Defer garbage collection further back in the startup process
(unless 'mps
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6))

;; In Emacs 27+, package initialization occurs before `user-init-file' is
;; loaded, but after `early-init-file'. We need to set
(require 'xdg)
(require 'package)
(setq package-user-dir (concat (xdg-state-home) "/emacs/elpa")
      package-gnupghome-dir (concat (xdg-state-home) "/elpa")
      package-quickstart-file (concat (xdg-state-home) "/package-quickstart.el")
      package-enable-at-startup nil
      package-quickstart t)

;; Prevent the glimpse of un-styled Emacs by disabling these UI elements early.
(setq default-frame-alist
      '((menu-bar-lines . 0)
        (tool-bar-lines . 0)
        (horizontal-scroll-bars)
        (vertical-scroll-bars)))


(setq load-prefer-newer noninteractive)

(unless (or (daemonp) noninteractive)
  (let ((old-file-name-handler-alist file-name-handler-alist))
    ;; `file-name-handler-alist' is consulted on each `require', `load' and
    ;; various path/io functions. You get a minor speed up by unsetting this.
    ;; Some warning, however: this could cause problems on builds of Emacs where
    ;; its site lisp files aren't byte-compiled and we're forced to load the
    ;; *.el.gz files (e.g. on Alpine).
    (setq-default file-name-handler-alist nil)
    ;; ...but restore `file-name-handler-alist' later, because it is needed for
    ;; handling encrypted or compressed files, among other things.
    (defun doom-reset-file-handler-alist-h ()
      (setq file-name-handler-alist
            ;; Merge instead of overwrite because there may have bene changes to
            ;; `file-name-handler-alist' since startup we want to preserve.
            (delete-dups (append file-name-handler-alist
                                 old-file-name-handler-alist))))
    (add-hook 'emacs-startup-hook #'doom-reset-file-handler-alist-h 101))

  ;; Premature redisplays can substantially affect startup times and produce
  ;; ugly flashes of unstyled Emacs.
  (setq-default inhibit-redisplay t
                inhibit-message t)
  (add-hook 'window-setup-hook
            (lambda ()
              (setq-default inhibit-redisplay nil
                            inhibit-message nil)
              (redisplay)))

  ;; Site files tend to use `load-file', which emits "Loading X..." messages in
  ;; the echo area, which in turn triggers a redisplay. Redisplays can have a
  ;; substantial effect on startup times and in this case happens so early that
  ;; Emacs may flash white while starting up.
  (define-advice load-file (:override (file) silence)
    (load file nil 'nomessage))

  ;; Undo our `load-file' advice above, to limit the scope of any edge cases it
  ;; may introduce down the road.
  (define-advice startup--load-user-init-file (:before (&rest _) init-doom)
    (advice-remove #'load-file #'load-file@silence)))

;;
;;; Bootstrap

;; Contrary to what many Emacs users have in their configs, you don't need
;; more than this to make UTF-8 the default coding system:
(set-language-environment "UTF-8")

;; set-language-enviornment sets default-input-method, which is unwanted
(setq default-input-method nil)


;; Resizing the Emacs frame can be a terribly expensive part of changing the
;; font. By inhibiting this, we easily halve startup times with fonts that are
;; larger than the system default.
(setq frame-inhibit-implied-resize t)

;; Ignore X resources; its settings would be redundant with the other settings
;; in this file and can conflict with later config (particularly where the
;; cursor color is concerned).
(advice-add #'x-apply-session-resources :override #'ignore)

(provide 'early-init)
