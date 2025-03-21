;; -*- lexical-binding: t; -*-
;; My config of built-in or other small stuff
(require 'fejfighter-platform)

;; Custom File - keep the churn somewhere else
(setq custom-file (concat cache-dir "/fejfighter-custom.el"))
;; this requires emacs 27
(if (not (file-exists-p custom-file)) (make-empty-file custom-file))
(load custom-file)

(use-package svg-lib
  :config
  (setq svg-lib-icons-dir (expand-file-name "svg-lib/" cache-dir)))

(use-package display-line-numbers
  :hook (prog-mode . display-line-numbers-mode))

(use-package compile
  :bind (("<f8>" . recompile)
	 ("C-<f8>" . compile)))

(use-package imenu
  :bind (("M-i" . imenu)))

(use-package hl-line
  :config
  (set-face-attribute 'hl-line nil :inherit nil :background "gray6")
  :init (global-hl-line-mode t))

(use-package flymake
  :hook ((prog-mode . flymake-mode))
  :bind (:map flymake-mode-map
	      ("M-p" . flymake-goto-prev-error)
	      ("M-n" . flymake-goto-next-error)))

(use-package eshell
  :config
  (setq eshell-directory-name (concat cache-dir "/eshell")))

(use-package tramp
  :defer 1
  :config
  (setq tramp-persistency-file-name (concat cache-dir "/tramp")))

(use-package bookmark
  :config
  (setq bookmark-default-file (concat cache-dir "/bookmarks")))

(use-package desktop
  :config
  (desktop-save-mode t)
  (setq desktop-restore-eager 10))

;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :init
  (savehist-mode t)
  :config
  (setq savehist-file (concat cache-dir "/history")))

;; I only really use git, stamp on vc-mode....
(with-eval-after-load 'vc
  (remove-hook 'find-file-hook 'vc-find-file-hook)
  (remove-hook 'find-file-hook 'vc-refresh-state))
  (setq vc-handled-backends '(Git))

;; As the built-in project.el support expects to use vc-mode hooks to
;; find the root of projects we need to provide something equivalent
;; for it.
(defun git-project-finder (dir)
  "Integrate .git project roots."
  (let ((dotgit (and (setq dir (locate-dominating-file dir ".git"))
                     (expand-file-name dir))))
    (and dotgit
         (cons 'transient (file-name-directory dotgit)))))

(use-package project
  :bind (:map project-prefix-map
	      ("l" . vc-print-log))
  :custom
  (project-list-file (concat cache-dir "/projects"))
  :init
  (setq project-switch-commands
	'((project-find-regexp "Find regexp")
	 (project-find-dir "Find directory")
	 (project-vc-dir "VC-Dir")
	 (project-eshell "Eshell")))
  )

(use-package cc-mode
  :after eglot
  :hook (((c-mode c++-mode) . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs '((c++-mode c-mode) . ("clangd"
						      "-j=4"
						      "--background-index"))))

(use-package eglot
  :defer 2)
  ;; :custom
  ;; (eglot-events-buffer-size 0))

(use-package eldoc
  :config
  (setq eldoc-idle-delay 1.5))

(use-package emacs
  :init
  (setq completion-cycle-threshold 3)

  ;; Emacs 28: Hide commands in M-x which do not apply to the current mode.
  ;; Corfu commands are hidden, since they are not supposed to be used via M-x.
  (setq read-extended-command-predicate
        #'command-completion-default-include-p)

  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  (setq tab-always-indent 'complete)

  ;; Add prompt indicator to `completing-read-multiple'.
  ;; Alternatively try `consult-completing-read-multiple'.
  (defun crm-indicator (args)
    (cons (concat "[CRM] " (car args)) (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

  ;; Enable recursive minibuffers
  (setq enable-recursive-minibuffers nil)

  ;;parens
  (show-paren-mode t);

  (setq indent-tabs-mode nil)

  ;; leave emacs blank when started
  (setq inhibit-startup-screen t)

  ; shorten yes or no
  (setq use-short-answers t)

  (setq column-number-mode t)
  (setq x-gtk-use-system-tooltips t)

  (setq auto-save-list-file-prefix (concat cache-dir "/auto-save-list/.saves-"))

  ;; Emoji set
  (set-fontset-font t 'unicode "Noto Color Emoji" nil 'prepend)

  ;; hide the menu bar and tool bar
  (if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
  (if (fboundp 'menu-bar-mode) (menu-bar-mode -1))
  (if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

  :custom
   (auth-sources '("~/.authinfo.gpg" "~/.netrc")))

(setq default-directory "~/dev/")

;; often build emacs from source and prefix with /usr/local
;; packages with emacs support normally add files to /usr/share/emacs/site-lisp.
;; building locally means it won't get picked up, add it here
(add-to-list 'load-path "/usr/share/emacs/site-lisp/")

(provide 'fejfighter-init)
