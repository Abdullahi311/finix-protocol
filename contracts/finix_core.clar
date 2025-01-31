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

;; Data vars 
(define-data-var minimum-collateral-ratio uint u150) ;; 150% collateralization required
(define-data-var liquidation-ratio uint u120) ;; Positions can be liquidated below 120%
(define-data-var liquidation-penalty uint u10) ;; 10% penalty on liquidation
(define-data-var liquidator-reward uint u5) ;; 5% reward for liquidators

;; Data maps
(define-map synthetic-positions principal
  {
    collateral-amount: uint,
    synthetic-amount: uint,
    asset-identifier: (string-ascii 12)
  }
)

(define-map price-feeds (string-ascii 12) uint)

;; Create synthetic position
(define-public (create-position (collateral-amount uint) (synthetic-amount uint) (asset-identifier (string-ascii 12)))
  (let (
    (asset-price (unwrap! (get-price asset-identifier) err-invalid-price))
    (required-collateral (calculate-required-collateral synthetic-amount asset-price))
  )
    (if (>= collateral-amount required-collateral)
      (begin 
        (try! (stx-transfer? collateral-amount tx-sender (as-contract tx-sender)))
        (map-set synthetic-positions tx-sender
          {
            collateral-amount: collateral-amount,
            synthetic-amount: synthetic-amount,
            asset-identifier: asset-identifier
          }
        )
        (ok true))
      err-insufficient-collateral
    )
  )
)

;; Add collateral to existing position
(define-public (add-collateral (amount uint))
  (let (
    (position (unwrap! (map-get? synthetic-positions tx-sender) err-position-not-found))
  )
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set synthetic-positions tx-sender
      (merge position {
        collateral-amount: (+ (get collateral-amount position) amount)
      })
    )
    (ok true)
  )
)

;; Close position
(define-public (close-position)
  (let (
    (position (unwrap! (map-get? synthetic-positions tx-sender) err-position-not-found))
  )
    (try! (stx-transfer? (get collateral-amount position) (as-contract tx-sender) tx-sender))
    (map-delete synthetic-positions tx-sender)
    (ok true)
  )
)

;; Liquidate undercollateralized position
(define-public (liquidate-position (owner principal))
  (let (
    (position (unwrap! (map-get? synthetic-positions owner) err-position-not-found))
    (asset-price (unwrap! (get-price (get asset-identifier position)) err-invalid-price))
    (collateral-ratio (calculate-collateral-ratio 
      (get collateral-amount position)
      (get synthetic-amount position)
      asset-price))
  )
    (if (<= collateral-ratio (var-get liquidation-ratio))
      (let (
        (penalty-amount (/ (* (get collateral-amount position) (var-get liquidation-penalty)) u100))
        (reward-amount (/ (* (get collateral-amount position) (var-get liquidator-reward)) u100))
        (return-amount (- (get collateral-amount position) (+ penalty-amount reward-amount)))
      )
        (try! (stx-transfer? reward-amount (as-contract tx-sender) tx-sender))
        (try! (stx-transfer? return-amount (as-contract tx-sender) owner))
        (map-delete synthetic-positions owner)
        (ok true))
      err-not-liquidatable
    )
  )
)

;; Read only functions
(define-read-only (get-position (owner principal))
  (map-get? synthetic-positions owner)
)

(define-read-only (get-price (asset-identifier (string-ascii 12)))
  (map-get? price-feeds asset-identifier)
)

(define-read-only (calculate-required-collateral (synthetic-amount uint) (price uint))
  (* (* synthetic-amount price) (/ (var-get minimum-collateral-ratio) u100))
)

(define-read-only (calculate-collateral-ratio (collateral-amount uint) (synthetic-amount uint) (price uint))
  (/ (* collateral-amount u100) (* synthetic-amount price))
)

;; Admin functions
(define-public (set-price (asset-identifier (string-ascii 12)) (price uint))
  (if (is-eq tx-sender contract-owner)
    (begin
      (map-set price-feeds asset-identifier price)
      (ok true)
    )
    err-owner-only
  )
)

(define-public (set-minimum-collateral-ratio (new-ratio uint))
  (if (is-eq tx-sender contract-owner)
    (begin
      (var-set minimum-collateral-ratio new-ratio)
      (ok true)
    )
    err-owner-only
  )
)

(define-public (set-liquidation-ratio (new-ratio uint))
  (if (is-eq tx-sender contract-owner)
    (begin 
      (var-set liquidation-ratio new-ratio)
      (ok true)
    )
    err-owner-only
  )
)

(define-public (set-liquidation-penalty (new-penalty uint))
  (if (is-eq tx-sender contract-owner)
    (begin
      (var-set liquidation-penalty new-penalty)
      (ok true)
    )
    err-owner-only
  )
)
