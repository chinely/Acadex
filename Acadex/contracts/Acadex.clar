;; Acadex Smart Contract
;; Description- Academic Achievement Platform

;; Configuration Values
(define-constant institution-administrator tx-sender)
(define-constant failure-unauthorized-operation (err u100))
(define-constant failure-learner-not-registered (err u101))
(define-constant failure-inadequate-learning-points (err u102))
(define-constant failure-invalid-point-amount (err u103))
(define-constant failure-registration-process-failed (err u104))
(define-constant failure-action-forbidden (err u105))
(define-constant failure-invalid-pricing-structure (err u106))
(define-constant failure-learner-previously-registered (err u107))
(define-constant failure-invalid-profile-information (err u108))
(define-constant failure-term-halted (err u109))

;; System Variables
(define-data-var module-pricing-multiplier uint u0)
(define-data-var institutional-fee-percentage uint u150) ;; 1.5% processing charge, in basis points
(define-data-var term-halt-flag bool false) ;; Emergency stop mechanism

;; Data Storage
(define-map learning-point-registry principal uint)
(define-map learner-profiles   
  principal   
  { participant-name: (string-ascii 55),     
    participant-identifier: (string-ascii 22) })
(define-map assessment-authorities principal bool)

;; Query Functions
(define-read-only (retrieve-learning-point-total (participant principal))
  (default-to u0 (map-get? learning-point-registry participant)))

(define-read-only (retrieve-learner-profile (participant principal))
  (map-get? learner-profiles participant))

(define-read-only (retrieve-current-module-pricing)
  (ok (var-get module-pricing-multiplier)))

(define-read-only (verify-assessment-authority (participant principal))
  (default-to false (map-get? assessment-authorities participant)))

(define-read-only (verify-term-halt-status)
  (var-get term-halt-flag))

;; Internal Validation Functions
(define-private (validate-participant-name (name (string-ascii 55)))
  (and (> (len name) u0) (<= (len name) u55)))

(define-private (validate-participant-identifier (identifier (string-ascii 22)))
  (and (> (len identifier) u0) (<= (len identifier) u22)))

;; External Interface Methods
(define-public (register-participant (participant-name (string-ascii 55)) (participant-identifier (string-ascii 22)))
  (begin
    (asserts! (is-none (retrieve-learner-profile tx-sender)) failure-learner-previously-registered)
    (asserts! (validate-participant-name participant-name) failure-invalid-profile-information)
    (asserts! (validate-participant-identifier participant-identifier) failure-invalid-profile-information)
    (asserts! (not (verify-term-halt-status)) failure-term-halted)
    
    (map-set learner-profiles tx-sender 
      { participant-name: participant-name, 
        participant-identifier: participant-identifier })
    (map-set learning-point-registry tx-sender u0)
    (ok true)))

(define-public (allocate-learning-points (recipient principal) (point-quantity uint))
  (begin
    (asserts! (is-eq tx-sender institution-administrator) failure-unauthorized-operation)
    (asserts! (> point-quantity u0) failure-invalid-point-amount)
    (asserts! (is-some (retrieve-learner-profile recipient)) failure-learner-not-registered)
    (asserts! (not (verify-term-halt-status)) failure-term-halted)
    
    (let ((current-balance (retrieve-learning-point-total recipient)))
      (map-set learning-point-registry recipient (+ current-balance point-quantity))
      (ok point-quantity))))

(define-public (deduct-learning-points (participant principal) (point-quantity uint))
  (begin
    (asserts! (verify-assessment-authority tx-sender) failure-unauthorized-operation)
    (asserts! (> point-quantity u0) failure-invalid-point-amount)
    (asserts! (is-some (retrieve-learner-profile participant)) failure-learner-not-registered)
    (asserts! (not (verify-term-halt-status)) failure-term-halted)
    
    (let ((current-balance (retrieve-learning-point-total participant)))
      (asserts! (>= current-balance point-quantity) failure-inadequate-learning-points)
      (map-set learning-point-registry participant (- current-balance point-quantity))
      (ok point-quantity))))

(define-public (transfer-learning-points (recipient principal) (point-quantity uint))
  (begin
    (asserts! (> point-quantity u0) failure-invalid-point-amount)
    (asserts! (is-some (retrieve-learner-profile tx-sender)) failure-learner-not-registered)
    (asserts! (is-some (retrieve-learner-profile recipient)) failure-learner-not-registered)
    (asserts! (not (verify-term-halt-status)) failure-term-halted)
    
    (let ((sender-balance (retrieve-learning-point-total tx-sender))
          (recipient-balance (retrieve-learning-point-total recipient))
          (processing-fee (/ (* point-quantity (var-get institutional-fee-percentage)) u10000)))
      (asserts! (>= sender-balance (+ point-quantity processing-fee)) failure-inadequate-learning-points)
      
      (map-set learning-point-registry tx-sender (- sender-balance (+ point-quantity processing-fee)))
      (map-set learning-point-registry recipient (+ recipient-balance point-quantity))
      (ok point-quantity))))

(define-public (update-module-pricing (new-multiplier uint))
  (begin
    (asserts! (is-eq tx-sender institution-administrator) failure-unauthorized-operation)
    (asserts! (> new-multiplier u0) failure-invalid-pricing-structure)
    (var-set module-pricing-multiplier new-multiplier)
    (ok new-multiplier)))

(define-public (modify-institutional-fee (new-percentage uint))
  (begin
    (asserts! (is-eq tx-sender institution-administrator) failure-unauthorized-operation)
    (asserts! (<= new-percentage u1000) failure-invalid-pricing-structure) ;; Max 10%
    (var-set institutional-fee-percentage new-percentage)
    (ok new-percentage)))

(define-public (authorize-assessment-authority (evaluator principal))
  (begin
    (asserts! (is-eq tx-sender institution-administrator) failure-unauthorized-operation)
    (asserts! (not (is-eq evaluator institution-administrator)) failure-invalid-profile-information)
    (asserts! (is-some (retrieve-learner-profile evaluator)) failure-learner-not-registered)
    (map-set assessment-authorities evaluator true)
    (ok true)))

(define-public (revoke-assessment-authority (evaluator principal))
  (begin
    (asserts! (is-eq tx-sender institution-administrator) failure-unauthorized-operation)
    (asserts! (not (is-eq evaluator institution-administrator)) failure-invalid-profile-information)
    (asserts! (verify-assessment-authority evaluator) failure-learner-not-registered)
    (map-set assessment-authorities evaluator false)
    (ok true)))

(define-public (toggle-term-halt-status)
  (begin
    (asserts! (is-eq tx-sender institution-administrator) failure-unauthorized-operation)
    (var-set term-halt-flag (not (var-get term-halt-flag)))
    (ok (var-get term-halt-flag))))

(define-public (purchase-module-access (module-cost uint))
  (begin
    (asserts! (> module-cost u0) failure-invalid-point-amount)
    (asserts! (is-some (retrieve-learner-profile tx-sender)) failure-learner-not-registered)
    (asserts! (not (verify-term-halt-status)) failure-term-halted)
    
    (let ((participant-balance (retrieve-learning-point-total tx-sender))
          (total-cost (* module-cost (var-get module-pricing-multiplier))))
      (asserts! (>= participant-balance total-cost) failure-inadequate-learning-points)
      (map-set learning-point-registry tx-sender (- participant-balance total-cost))
      (ok total-cost))))
