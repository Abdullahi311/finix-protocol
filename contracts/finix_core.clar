;; Finix Protocol Core Contract
;; Handles creation and management of synthetic assets

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-collateral (err u101))
(define-constant err-position-not-found (err u102))
(define-constant err-invalid-price (err u103))
(define-constant err-not-liquidatable (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-zero-amount (err u106))
(define-constant err-invalid-ratio (err u107))
(define-constant err-paused (err u108))
(define-constant err-max-position (err u109))
(define-constant err-min-position (err u110))
(define-constant err-invalid-modification (err u111))

;; Data vars 
(define-data-var minimum-collateral-ratio uint u150)
(define-data-var liquidation-ratio uint u120)
(define-data-var liquidation-penalty uint u10)
(define-data-var liquidator-reward uint u5)
(define-data-var protocol-fee uint u1)
(define-data-var paused bool false)
(define-data-var total-protocol-fees uint u0)
(define-data-var max-position-size uint u1000000000000)
(define-data-var min-position-size uint u1000000) ;; New: 1000 STX minimum
(define-data-var total-collateral-locked uint u0) ;; New: Track total collateral

;; Helper functions
(define-private (calculate-safe-ratio (amount-a uint) (amount-b uint))
  (if (is-eq amount-b u0)
    u0
    (/ (* amount-a u100) amount-b)))

(define-private (update-total-collateral (delta int))
  (var-set total-collateral-locked 
    (if (> delta 0)
      (+ (var-get total-collateral-locked) (to-uint delta))
      (- (var-get total-collateral-locked) (to-uint (* delta -1))))))

;; Enhanced event emission
(define-private (emit-event (event-type (string-ascii 12)) (user principal) (amount uint))
  (let ((event-id (+ (var-get last-event-id) u1)))
    (var-set last-event-id event-id)
    (map-set events event-id {
      event-type: event-type,
      user: user,
      amount: amount,
      timestamp: block-height
    })
    event-id))

;; New: Modify position collateral
(define-public (modify-collateral (delta int))
  (let (
    (position (unwrap! (map-get? synthetic-positions tx-sender) err-position-not-found))
    (new-collateral (+ (get collateral-amount position) delta))
  )
    (asserts! (not (var-get paused)) err-paused)
    (asserts! (>= new-collateral (var-get min-position-size)) err-min-position)
    (asserts! (<= new-collateral (var-get max-position-size)) err-max-position)
    
    (if (> delta 0)
      (try! (stx-transfer? (to-uint delta) tx-sender (as-contract tx-sender)))
      (try! (stx-transfer? (to-uint (* delta -1)) (as-contract tx-sender) tx-sender)))
    
    (update-total-collateral delta)
    (map-set synthetic-positions tx-sender
      (merge position { collateral-amount: new-collateral }))
    (emit-event (if (> delta 0) "add-coll" "remove-coll") tx-sender (to-uint (abs delta)))
    (ok true)))

;; [Previous functions with safety enhancements...]
