;Exercise 5.15: Add instruction counting to the register machine simulation. That is, have the machine model keep track of the number of instructions executed. Extend the machine model’s interface to accept a new message that prints the value of the instruction count and resets the count to zero.
(load "/Users/soulomoon/git/SICP/Chapter5/ch5-regsim.scm")

(define (make-new-machine)
  (let ((pc (make-register 'pc))
        (flag (make-register 'flag))
        (stack (make-stack))
        (the-instruction-sequence '())
        (instruction-counter 0))
    (let ((the-ops
           (list (list 'initialize-stack
                       (lambda () (stack 'initialize)))
                 ;;**next for monitored stack (as in section 5.2.4)
                 ;;  -- comment out if not wanted
                 (list 'print-stack-statistics
                       (lambda () (stack 'print-statistics)))
                 (list 'instruction-counter
                       (lambda () (display "instruction-counter: ")
                                  (display instruction-counter)
                                  (newline )
                                  (set! instruction-counter 0)))))
          (register-table
           (list (list 'pc pc) (list 'flag flag))))
      (define (allocate-register name)
        (if (assoc name register-table)
            (error "Multiply defined register: " name)
            (set! register-table
                  (cons (list name (make-register name))
                        register-table)))
        'register-allocated)
      (define (lookup-register name)
        (let ((val (assoc name register-table)))
          (if val
              (cadr val)
              (error "Unknown register:" name))))
      (define (execute)
        (let ((insts (get-contents pc)))
          (if (null? insts)
              'done
              (begin
                (set! instruction-counter (+ instruction-counter 1))
                ((instruction-execution-proc (car insts)))
                (execute)))))
      (define (dispatch message)
        (cond ((eq? message 'start)
               (set-contents! pc the-instruction-sequence)
               (execute))
              ((eq? message 'install-instruction-sequence)
               (lambda (seq) (set! the-instruction-sequence seq)))
              ((eq? message 'allocate-register) allocate-register)
              ((eq? message 'get-register) lookup-register)
              ((eq? message 'install-operations)
               (lambda (ops) (set! the-ops (append the-ops ops))))
              ((eq? message 'stack) stack)
              ((eq? message 'operations) the-ops)
              (else (error "Unknown request -- MACHINE" message))))
      dispatch)))

(define (print x)
  (newline )
  (display x)
  (newline ))

;Recursive exponentiation:
(define fib-machine
(make-machine
  '(n val continue)
  (list (list '< <) (list '- -) (list 'print print) (list '+ +))
  '(
     (assign continue (label fib-done))
    fib-loop
     (test (op <) (reg n) (const 2))
     (branch (label immediate-answer))
     ;; set up to compute Fib(n − 1)
     (save continue)
     (assign continue (label afterfib-n-1))
     (save n)           ; save old value of n
     (assign n
             (op -)
             (reg n)
             (const 1)) ; clobber n to n-1
     (goto
      (label fib-loop)) ; perform recursive call
    afterfib-n-1 ; upon return, val contains Fib(n − 1)
     (restore n)
    ; (restore continue) ;here extra-restore
     ;; set up to compute Fib(n − 2)
     (assign n (op -) (reg n) (const 2))
    ; (save continue) ;here extra-save
     (assign continue (label afterfib-n-2))
     (save val)         ; save Fib(n − 1)
     (goto (label fib-loop))
    afterfib-n-2 ; upon return, val contains Fib(n − 2)
     (assign n
             (reg val)) ; n now contains Fib(n − 2)
     (restore val)      ; val now contains Fib(n − 1)
     (restore continue)
     (assign val        ; Fib(n − 1) + Fib(n − 2)
             (op +)
             (reg val)
             (reg n))
     (goto              ; return to caller,
      (reg continue))   ; answer is in val
    immediate-answer
     (assign val
             (reg n))   ; base case: Fib(n) = n
     (goto (reg continue))
    fib-done
    (perform (op print) (reg val))
    (perform (op instruction-counter))
)))

(set-register-contents! fib-machine 'n 8)
(start fib-machine)
(set-register-contents! fib-machine 'n 9)
(start fib-machine)

;Welcome to DrRacket, version 6.8 [3m].
;Language: SICP (PLaneT 1.18); memory limit: 128 MB.
;(REGISTER SIMULATOR LOADED)
;'done
;
;21
;instruction-counter: 700
;'done
;'done
;
;34
;instruction-counter: 1141
;'done
;>
