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

;; Data vars 
(define-data-var minimum-collateral-ratio uint u150)
(define-data-var liquidation-ratio uint u120)
(define-data-var liquidation-penalty uint u10)
(define-data-var liquidator-reward uint u5)
(define-data-var protocol-fee uint u1) ;; 0.1% fee (1/1000)
(define-data-var paused bool false)
(define-data-var total-protocol-fees uint u0)
(define-data-var max-position-size uint u1000000000000) ;; 1M STX

;; Events
(define-data-var last-event-id uint u0)
(define-map events uint {
  event-type: (string-ascii 12),
  user: principal,
  amount: uint,
  timestamp: uint
})

;; Existing maps remain unchanged...

;; Helper functions
(define-private (emit-event (event-type (string-ascii 12)) (user principal) (amount uint))
  (let ((event-id (+ (var-get last-event-id) u1)))
    (var-set last-event-id event-id)
    (map-set events event-id {
      event-type: event-type,
      user: user,
      amount: amount,
      timestamp: block-height
    })
    event-id
  )
)

;; Create synthetic position
(define-public (create-position (collateral-amount uint) (synthetic-amount uint) (asset-identifier (string-ascii 12)))
  (let (
    (asset-price (unwrap! (get-price asset-identifier) err-invalid-price))
    (required-collateral (calculate-required-collateral synthetic-amount asset-price))
    (fee-amount (/ (* collateral-amount (var-get protocol-fee)) u1000))
  )
    (asserts! (not (var-get paused)) err-paused)
    (asserts! (> collateral-amount u0) err-zero-amount)
    (asserts! (> synthetic-amount u0) err-zero-amount)
    (asserts! (<= collateral-amount (var-get max-position-size)) err-max-position)
    (asserts! (>= collateral-amount required-collateral) err-insufficient-collateral)
    (begin 
      (try! (stx-transfer? collateral-amount tx-sender (as-contract tx-sender)))
      (var-set total-protocol-fees (+ (var-get total-protocol-fees) fee-amount))
      (map-set synthetic-positions tx-sender
        {
          collateral-amount: (- collateral-amount fee-amount),
          synthetic-amount: synthetic-amount,
          asset-identifier: asset-identifier
        }
      )
      (emit-event "create" tx-sender collateral-amount)
      (ok true))
  )
)

;; Partial position closure
(define-public (partial-close (close-percentage uint))
  (let (
    (position (unwrap! (map-get? synthetic-positions tx-sender) err-position-not-found))
    (close-amount (/ (* (get collateral-amount position) close-percentage) u100))
    (synthetic-close-amount (/ (* (get synthetic-amount position) close-percentage) u100))
  )
    (asserts! (not (var-get paused)) err-paused)
    (asserts! (<= close-percentage u100) err-invalid-ratio)
    (try! (stx-transfer? close-amount (as-contract tx-sender) tx-sender))
    (map-set synthetic-positions tx-sender
      {
        collateral-amount: (- (get collateral-amount position) close-amount),
        synthetic-amount: (- (get synthetic-amount position) synthetic-close-amount),
        asset-identifier: (get asset-identifier position)
      }
    )
    (emit-event "partial-close" tx-sender close-amount)
    (ok true)
  )
)

;; Position health check
(define-read-only (get-position-health (owner principal))
  (let (
    (position (unwrap! (map-get? synthetic-positions owner) (ok u0)))
    (asset-price (unwrap! (get-price (get asset-identifier position)) (ok u0)))
  )
    (ok (calculate-collateral-ratio 
      (get collateral-amount position)
      (get synthetic-amount position)
      asset-price))
  )
)

;; Emergency pause
(define-public (toggle-pause)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set paused (not (var-get paused)))
    (ok true)
  )
)

;; Collect protocol fees
(define-public (collect-protocol-fees)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (let ((fees (var-get total-protocol-fees)))
      (var-set total-protocol-fees u0)
      (try! (stx-transfer? fees (as-contract tx-sender) contract-owner))
      (ok fees)
    )
  )
)

;; [Previous functions remain unchanged...]
