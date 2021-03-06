;; MIT License
;;
;; Copyright (c) 2018 Joseph Eib
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

#!r6rs
(library (threading)
  (export ~> ~>> some~> some~>> <> ~<> ~<>> some~<> some~<>>)
  (import (rnrs))

  (define-syntax ~?
    (lambda (stx)
      (syntax-case stx ()
        ((_ pred init form)
	 (pair? (syntax->datum #'form))
	 (syntax-case #'form (before after)
	   ((f f1 ...)
	    (identifier? #'pred)
	    (cond
	     ((free-identifier=? #'pred #'before) #'(f init f1 ...))
	     ((free-identifier=? #'pred #'after) #'(f f1 ... init))))))
        ((_ _ init form)
	 #'(if (procedure? form) (form init) form)))))

  (define-syntax wand~?
    (lambda (stx)
      (syntax-case stx ()
        ((_ _ init (forms ...))
	 (memq '<> (syntax->datum #'(forms ...)))
	 #`#,(map
	      (lambda (x) (if (and (identifier? x) (free-identifier=? x #'<>))
                              #'init
                              x))
	      #'(forms ...)))
        ((_ pred init form) #'(~? pred init form)))))

  (define-syntax define-threading-macro
    (lambda (stx)
      (syntax-case stx ()
        ((_ name where arrow? some?)
	 (and
	  (boolean? (syntax->datum #'arrow?))
	  (boolean? (syntax->datum #'some?)))
	 #'(define-syntax name
             (lambda (stx)
               (syntax-case stx ()
		 ((_ init) #'init)
		 ((_ init form)
		  (if (syntax->datum #'arrow?)
                      #'(~? where init form)
                      #'(wand~? where init form)))
		 ((_ init form forms (... ...))
		  (if (syntax->datum #'some?)
                      #'(let ((i (name init form))) (if i (name i forms (... ...)) #f))
                      #'(let ((i (name init form))) (name i forms (... ...))))))))))))

  (define-threading-macro ~> before #t #f)

  (define-threading-macro ~>> after #t #f)

  (define-threading-macro some~> before #t #t)

  (define-threading-macro some~>> after #t #t)

  (define-syntax <>
    (lambda (stx) (syntax-violation '<> "misplaced aux keyword" stx)))

  (define-threading-macro ~<> before #f #f)

  (define-threading-macro ~<>> after #f #f)

  (define-threading-macro some~<> before #f #t)

  (define-threading-macro some~<>> after #f #t)
  )
