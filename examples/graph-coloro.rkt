#lang racket
(require "../interface-definitions.rkt")
(require "./functional-graph-split.rkt")
(require (prefix-in australia: "./australia.rkt"))
(require (prefix-in america: "./america.rkt"))
(require (prefix-in canada: "./canada.rkt"))

(define-relation (membero x l)
  (fresh (car cdr)
    (== l `(,car . ,cdr))
    (conde ((== x car))
	   ((membero x cdr)))))

(define-relation (not-membero x l)
  (conde ((== l '()))
	 ((fresh (car cdr)
	    (== l `(,car . ,cdr))
	    (=/= x car)
	    (not-membero x cdr)))))

(define-relation (appendo xs ys zs)
  (conde ((== xs '()) (== ys zs))
	 ((fresh (x-head x-tail z-tail)
	    (== xs `(,x-head . ,x-tail))
	    (== zs `(,x-head . ,z-tail))
	    (appendo x-tail ys z-tail)))))

(define-relation (selecto x l l-x)
  (fresh (car cdr)
    (== l `(,car . ,cdr))
    (conde ((== x car)
	    (== l-x cdr))
	   ((fresh (cdr-x)
	      (== l-x `(,car . ,cdr-x))
	      (selecto x cdr cdr-x))))))

;; (define-relation (mapo p l)
;;   (conde ((== l '()))
;; 	 ((fresh (car cdr)
;; 	    (== l `(,car . ,cdr))
;; 	    (p car)
;; 	    (mapo p cdr)))))

(define-relation (mapo p l acc)
  (conde
   [(== l '())
    acc]
   [(fresh (car cdr)
	   (== l `(,car . ,cdr))
	   (mapo p cdr (fresh ()
			      acc
			      (p car))))]))

(define-relation (assoco key table value)
  (fresh (car table-cdr)
    (== table `(,car . ,table-cdr))
    (conde ((== `(,key . ,value) car))
	   ((assoco key table-cdr value)))))

(define-relation (same-lengtho l1 l2)
  (conde ((== l1 '()) (== l1 '()))
	 ((fresh (car1 cdr1 car2 cdr2)
	    (== l1 `(,car1 . ,cdr1))
	    (== l2 `(,car2 . ,cdr2))
	    (same-lengtho cdr1 cdr2)))))

(define-relation (make-assoc-tableo l1 l2 table)
  (conde ((== l1 '()) (== l1 '()) (== table '()))
	 ((fresh (car1 cdr1 car2 cdr2 cdr3)
	    (== l1 `(,car1 . ,cdr1))
	    (== l2 `(,car2 . ,cdr2))
	    (== table `((,car1 . ,car2) . ,cdr3))
	    (make-assoc-tableo cdr1 cdr2 cdr3)))))

(define-relation (coloro x)
  (membero x '(red green blue yellow)))

;; a higher-order goal, not my doing
(define (different-colors table)
  (lambda (constraint)
    (λ (s/c)
      (delay/name
       ((fresh (x y x-color y-color)
               (== constraint `(,x ,y))
               (assoco x table x-color)
               (assoco y table y-color)
               (=/= x-color y-color))
        s/c)))))

;; (define (my-mapo p l i)
;;   ;; This has to be done in a depth first search!
;;   ;; (display (make-list i '-)) (newline)
;;   (conde/dfs ((== l '()))
;; 	     ((fresh (car cdr)
;; 		(== l `(,car . ,cdr))
;; 		(p car)
;; 		(my-mapo p cdr (+ i 1))))))

(define-relation (color states edges colors)
  ;; This is a simple constrained generate and test solver
  ;; The interesting part was the graph reduction preprocessing
  ;; stage.
  (fresh (table)
    ;; make a list to hold the color of each state
    (make-assoc-tableo states colors table)

    ;; make sure each color is different to neighbours
    (mapo (different-colors table) edges (== 0 0))

    ;; brute force search for a valid coloring
    (mapo coloro colors (== 0 0))))

(define (do-australia)
  (let ((nodes (graph-good-ordering australia:nodes australia:edges)))
    ;;(display nodes)(newline)
    (run 1 (q) (color nodes australia:edges q))))

(define (do-canada)
  (let ((nodes (graph-good-ordering canada:nodes canada:edges)))
    ;;(display nodes)(newline)
    (run 1 (q) (color nodes canada:edges q))))

(define (do-america)
  (let ((nodes (graph-good-ordering america:nodes america:edges)))
    ;;(display nodes)(newline)
    (run 1 (q) (color nodes america:edges q))))


(module+ test

 (define loop-count 10000000)

 (define (test-loop-f f)
   (let loop ([i loop-count])
     (if (= i 0)
         (void)
         (let ([res (f)])
           (and res
                (loop (- i 1)))))))

 (define-syntax test-loop
   (syntax-rules () [(_ e) (test-loop-f (lambda () e))]))


 ;; (time (test-loop (do-australia)))
 ;; (time (test-loop (do-canada)))
 ;; (time (test-loop (do-america)))

 (time (do-america))


)