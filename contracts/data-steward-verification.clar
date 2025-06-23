;; Data Steward Verification Contract
;; Manages verification and authorization of data stewards

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STEWARD (err u103))

;; Data steward information
(define-map stewards
  { steward: principal }
  {
    verified: bool,
    verification-date: uint,
    verification-level: uint,
    active: bool
  }
)

;; Steward verification tokens
(define-map steward-tokens
  { steward: principal }
  { token-id: uint, issued-at: uint }
)

(define-data-var next-token-id uint u1)

;; Verify a data steward
(define-public (verify-steward (steward principal) (level uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? stewards { steward: steward })) ERR_ALREADY_VERIFIED)
    (asserts! (> level u0) ERR_INVALID_STEWARD)

    (let ((token-id (var-get next-token-id)))
      (map-set stewards
        { steward: steward }
        {
          verified: true,
          verification-date: block-height,
          verification-level: level,
          active: true
        }
      )
      (map-set steward-tokens
        { steward: steward }
        { token-id: token-id, issued-at: block-height }
      )
      (var-set next-token-id (+ token-id u1))
      (ok token-id)
    )
  )
)

;; Check if steward is verified
(define-read-only (is-verified-steward (steward principal))
  (match (map-get? stewards { steward: steward })
    steward-data (and (get verified steward-data) (get active steward-data))
    false
  )
)

;; Get steward verification level
(define-read-only (get-steward-level (steward principal))
  (match (map-get? stewards { steward: steward })
    steward-data (some (get verification-level steward-data))
    none
  )
)

;; Revoke steward verification
(define-public (revoke-steward (steward principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? stewards { steward: steward })) ERR_NOT_FOUND)

    (map-set stewards
      { steward: steward }
      (merge (unwrap-panic (map-get? stewards { steward: steward }))
             { active: false })
    )
    (ok true)
  )
)

;; Get steward token
(define-read-only (get-steward-token (steward principal))
  (map-get? steward-tokens { steward: steward })
)
