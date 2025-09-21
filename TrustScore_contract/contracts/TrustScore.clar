
;; title: TrustScore
;; version: 1.0.0
;; summary: A reputation system smart contract for general trustworthiness scoring across all Stacks interactions
;; description: This contract maintains trust scores for addresses based on their interactions and behavior on the Stacks blockchain

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_SCORE (err u101))
(define-constant ERR_SCORE_TOO_LOW (err u102))
(define-constant ERR_SCORE_TOO_HIGH (err u103))
(define-constant ERR_INVALID_WEIGHT (err u104))

;; Scoring constants
(define-constant MIN_SCORE u0)
(define-constant MAX_SCORE u1000)
(define-constant DEFAULT_SCORE u500)
(define-constant MIN_WEIGHT u1)
(define-constant MAX_WEIGHT u100)

;; data vars
(define-data-var contract-enabled bool true)
(define-data-var total-evaluations uint u0)

;; data maps
;; Main trust score storage
(define-map trust-scores principal
  {
    score: uint,
    total-interactions: uint,
    positive-interactions: uint,
    negative-interactions: uint,
    last-updated: uint
  }
)

;; Interaction records
(define-map interaction-history
  { evaluator: principal, target: principal, block-number: uint }
  {
    score-change: int,
    weight: uint,
    interaction-type: (string-ascii 50),
    timestamp: uint
  }
)

;; Admin list for authorized score updaters
(define-map authorized-evaluators principal bool)

;; public functions

;; Initialize or update a trust score for an address
(define-public (initialize-trust-score (target principal))
  (let (
    (current-score (default-to {
      score: DEFAULT_SCORE,
      total-interactions: u0,
      positive-interactions: u0,
      negative-interactions: u0,
      last-updated: block-height
    } (map-get? trust-scores target)))
  )
    (if (is-eq (get total-interactions current-score) u0)
      (begin
        (map-set trust-scores target current-score)
        (ok true)
      )
      (ok false) ;; Already initialized
    )
  )
)

;; Record a trust interaction (positive or negative)
(define-public (record-interaction
  (target principal)
  (score-change int)
  (weight uint)
  (interaction-type (string-ascii 50))
)
  (let (
    (caller tx-sender)
    (current-block block-height)
    (is-authorized (or (is-eq caller CONTRACT_OWNER) (default-to false (map-get? authorized-evaluators caller))))
  )
    (asserts! (var-get contract-enabled) ERR_UNAUTHORIZED)
    (asserts! is-authorized ERR_UNAUTHORIZED)
    (asserts! (and (>= weight MIN_WEIGHT) (<= weight MAX_WEIGHT)) ERR_INVALID_WEIGHT)

    (let (
      (current-data (default-to {
        score: DEFAULT_SCORE,
        total-interactions: u0,
        positive-interactions: u0,
        negative-interactions: u0,
        last-updated: u0
      } (map-get? trust-scores target)))
      (weighted-change (* score-change (to-int weight)))
      (new-score-int (+ (to-int (get score current-data)) weighted-change))
      (new-score (if (< new-score-int (to-int MIN_SCORE))
                   MIN_SCORE
                   (if (> new-score-int (to-int MAX_SCORE))
                     MAX_SCORE
                     (to-uint new-score-int))))
      (is-positive (> score-change 0))
    )
      ;; Update trust score
      (map-set trust-scores target {
        score: new-score,
        total-interactions: (+ (get total-interactions current-data) u1),
        positive-interactions: (if is-positive
                                 (+ (get positive-interactions current-data) u1)
                                 (get positive-interactions current-data)),
        negative-interactions: (if is-positive
                                 (get negative-interactions current-data)
                                 (+ (get negative-interactions current-data) u1)),
        last-updated: current-block
      })

      ;; Record interaction history
      (map-set interaction-history
        { evaluator: caller, target: target, block-number: current-block }
        {
          score-change: score-change,
          weight: weight,
          interaction-type: interaction-type,
          timestamp: current-block
        }
      )

      ;; Update total evaluations
      (var-set total-evaluations (+ (var-get total-evaluations) u1))

      (ok new-score)
    )
  )
)

;; Add or remove authorized evaluators (only contract owner)
(define-public (set-evaluator-authorization (evaluator principal) (authorized bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set authorized-evaluators evaluator authorized)
    (ok true)
  )
)

;; Enable or disable the contract (only contract owner)
(define-public (set-contract-enabled (enabled bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-enabled enabled)
    (ok true)
  )
)

;; Bulk score update for migration or administrative purposes
(define-public (admin-set-score (target principal) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (and (>= new-score MIN_SCORE) (<= new-score MAX_SCORE)) ERR_INVALID_SCORE)

    (let (
      (current-data (default-to {
        score: DEFAULT_SCORE,
        total-interactions: u0,
        positive-interactions: u0,
        negative-interactions: u0,
        last-updated: u0
      } (map-get? trust-scores target)))
    )
      (map-set trust-scores target (merge current-data {
        score: new-score,
        last-updated: block-height
      }))
      (ok true)
    )
  )
)

;; read only functions

;; Get trust score for an address
(define-read-only (get-trust-score (target principal))
  (match (map-get? trust-scores target)
    score-data (ok (get score score-data))
    (ok DEFAULT_SCORE)
  )
)

;; Get complete trust data for an address
(define-read-only (get-trust-data (target principal))
  (match (map-get? trust-scores target)
    score-data (ok score-data)
    (ok {
      score: DEFAULT_SCORE,
      total-interactions: u0,
      positive-interactions: u0,
      negative-interactions: u0,
      last-updated: u0
    })
  )
)

;; Get trust score category (Poor, Fair, Good, Excellent)
(define-read-only (get-trust-category (target principal))
  (let (
    (score (unwrap! (get-trust-score target) (err u999)))
  )
    (if (<= score u250)
      (ok "Poor")
      (if (<= score u500)
        (ok "Fair")
        (if (<= score u750)
          (ok "Good")
          (ok "Excellent")
        )
      )
    )
  )
)

;; Check if an address is authorized evaluator
(define-read-only (is-authorized-evaluator (evaluator principal))
  (or (is-eq evaluator CONTRACT_OWNER) (default-to false (map-get? authorized-evaluators evaluator)))
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  (ok {
    total-evaluations: (var-get total-evaluations),
    contract-enabled: (var-get contract-enabled),
    contract-owner: CONTRACT_OWNER
  })
)

;; Get interaction history for specific evaluator and target
(define-read-only (get-interaction (evaluator principal) (target principal) (block-number uint))
  (map-get? interaction-history { evaluator: evaluator, target: target, block-number: block-number })
)

;; Calculate trust percentage (0-100)
(define-read-only (get-trust-percentage (target principal))
  (let (
    (score (unwrap! (get-trust-score target) (err u999)))
  )
    (ok (/ (* score u100) MAX_SCORE))
  )
)

;; Check if score is within valid range
(define-read-only (is-valid-score (score uint))
  (and (>= score MIN_SCORE) (<= score MAX_SCORE))
)

;; private functions

;; Calculate weighted score impact
(define-private (calculate-weighted-impact (base-change int) (weight uint))
  (* base-change (to-int weight))
)

;; Validate interaction parameters
(define-private (validate-interaction-params (score-change int) (weight uint))
  (and
    (>= weight MIN_WEIGHT)
    (<= weight MAX_WEIGHT)
  )
)

