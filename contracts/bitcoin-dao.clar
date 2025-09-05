;; BitcoinDAO - Decentralized Investment Fund

;; Summary
;; A sophisticated decentralized autonomous organization (DAO) built on Stacks,
;; enabling collective Bitcoin-backed investments through democratic governance
;; and transparent fund management.

;; Description  
;; BitcoinDAO harnesses the security of Bitcoin through the Stacks layer-2 to create
;; a trustless investment vehicle. Members stake STX tokens to gain voting rights,
;; propose funding allocations, and collectively govern treasury distributions.
;; The contract enforces time-locks, minimum thresholds, and democratic consensus
;; to ensure responsible capital deployment while maintaining full transparency
;; and decentralization principles.

;; CONSTANTS & ERROR CODES

(define-constant CONTRACT_OWNER tx-sender)

;; Error Constants
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_NOT_INITIALIZED (err u101))
(define-constant ERR_ALREADY_INITIALIZED (err u102))
(define-constant ERR_INSUFFICIENT_BALANCE (err u103))
(define-constant ERR_UNAUTHORIZED (err u105))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u106))
(define-constant ERR_PROPOSAL_EXPIRED (err u107))
(define-constant ERR_ALREADY_VOTED (err u108))
(define-constant ERR_BELOW_MINIMUM (err u109))
(define-constant ERR_STAKE_LOCKED (err u110))
(define-constant ERR_INVALID_AMOUNT (err u113))
(define-constant ERR_INVALID_TARGET (err u114))
(define-constant ERR_INVALID_DESCRIPTION (err u115))
(define-constant ERR_INVALID_PROPOSAL_ID (err u116))

;; Protocol Constants
(define-constant MIN_STAKE_AMOUNT u1000000) ;; 1 STX minimum stake
(define-constant STAKE_LOCK_PERIOD u1440) ;; ~10 days lock period
(define-constant MIN_PROPOSAL_DURATION u144) ;; 1 day minimum
(define-constant MAX_PROPOSAL_DURATION u20160) ;; 14 days maximum

;; STATE VARIABLES

(define-data-var total-staked uint u0)
(define-data-var minimum-stake uint MIN_STAKE_AMOUNT)
(define-data-var lock-period uint STAKE_LOCK_PERIOD)
(define-data-var is-initialized bool false)
(define-data-var proposal-counter uint u0)

;; DATA MAPS

;; Member voting power and stakes
(define-map member-stakes
  principal
  uint
)

;; Stake details with time-lock
(define-map stake-records
  principal
  {
    amount: uint,
    unlock-height: uint,
    stake-height: uint,
  }
)

;; Investment proposals
(define-map investment-proposals
  uint
  {
    proposer: principal,
    title: (string-ascii 256),
    funding-amount: uint,
    beneficiary: principal,
    expiry-height: uint,
    is-executed: bool,
    votes-for: uint,
    votes-against: uint,
  }
)

;; Voting records to prevent double-voting
(define-map member-votes
  {
    proposal-id: uint,
    member: principal,
  }
  bool
)

;; PRIVATE HELPER FUNCTIONS

(define-private (is-owner)
  (is-eq tx-sender CONTRACT_OWNER)
)

(define-private (ensure-initialized)
  (ok (asserts! (var-get is-initialized) ERR_NOT_INITIALIZED))
)

(define-private (validate-proposal-exists (proposal-id uint))
  (ok (asserts! (<= proposal-id (var-get proposal-counter)) ERR_INVALID_PROPOSAL_ID))
)

(define-private (get-voting-power (member principal))
  (default-to u0 (map-get? member-stakes member))
)

(define-private (mint-voting-tokens
    (member principal)
    (amount uint)
  )
  (let ((current-stake (default-to u0 (map-get? member-stakes member))))
    (map-set member-stakes member (+ current-stake amount))
    (var-set total-staked (+ (var-get total-staked) amount))
    (ok true)
  )
)

(define-private (burn-voting-tokens
    (member principal)
    (amount uint)
  )
  (let ((current-stake (default-to u0 (map-get? member-stakes member))))
    (asserts! (>= current-stake amount) ERR_INSUFFICIENT_BALANCE)
    (map-set member-stakes member (- current-stake amount))
    (var-set total-staked (- (var-get total-staked) amount))
    (ok true)
  )
)

;; PUBLIC FUNCTIONS

;; Initialize the DAO (owner-only)
(define-public (initialize-dao)
  (begin
    (asserts! (is-owner) ERR_OWNER_ONLY)
    (asserts! (not (var-get is-initialized)) ERR_ALREADY_INITIALIZED)
    (var-set is-initialized true)
    (ok true)
  )
)

;; Stake STX to join the DAO and gain voting rights
(define-public (stake-tokens (amount uint))
  (begin
    (try! (ensure-initialized))
    (asserts! (>= amount (var-get minimum-stake)) ERR_BELOW_MINIMUM)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)

    ;; Transfer STX to contract treasury
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; Record stake with time-lock
    (map-set stake-records tx-sender {
      amount: amount,
      unlock-height: (+ stacks-block-height (var-get lock-period)),
      stake-height: stacks-block-height,
    })

    ;; Mint voting power
    (mint-voting-tokens tx-sender amount)
  )
)

;; Unstake tokens after lock period expires
(define-public (unstake-tokens (amount uint))
  (begin
    (try! (ensure-initialized))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)

    (let (
        (stake-info (unwrap! (map-get? stake-records tx-sender) ERR_UNAUTHORIZED))
        (member-power (get-voting-power tx-sender))
      )
      (asserts! (>= stacks-block-height (get unlock-height stake-info))
        ERR_STAKE_LOCKED
      )
      (asserts! (>= member-power amount) ERR_INSUFFICIENT_BALANCE)

      ;; Burn voting tokens
      (try! (burn-voting-tokens tx-sender amount))

      ;; Return STX to member
      (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender))
    )
  )
)

;; Create investment proposal
(define-public (propose-investment
    (title (string-ascii 256))
    (funding-amount uint)
    (beneficiary principal)
    (duration uint)
  )
  (begin
    (try! (ensure-initialized))

    ;; Validate proposal parameters
    (asserts! (> (len title) u0) ERR_INVALID_DESCRIPTION)
    (asserts! (> funding-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (not (is-eq beneficiary (as-contract tx-sender)))
      ERR_INVALID_TARGET
    )
    (asserts!
      (and
        (>= duration MIN_PROPOSAL_DURATION)
        (<= duration MAX_PROPOSAL_DURATION)
      )
      ERR_INVALID_AMOUNT
    )

    (let (
        (proposer-power (get-voting-power tx-sender))
        (new-proposal-id (+ (var-get proposal-counter) u1))
      )
      ;; Ensure proposer has voting power
      (asserts! (> proposer-power u0) ERR_UNAUTHORIZED)

      ;; Create proposal
      (map-set investment-proposals new-proposal-id {
        proposer: tx-sender,
        title: title,
        funding-amount: funding-amount,
        beneficiary: beneficiary,
        expiry-height: (+ stacks-block-height duration),
        is-executed: false,
        votes-for: u0,
        votes-against: u0,
      })

      (var-set proposal-counter new-proposal-id)
      (ok new-proposal-id)
    )
  )
)

;; Cast vote on proposal
(define-public (cast-vote
    (proposal-id uint)
    (support bool)
  )
  (begin
    (try! (ensure-initialized))
    (try! (validate-proposal-exists proposal-id))

    (let (
        (proposal (unwrap! (map-get? investment-proposals proposal-id)
          ERR_PROPOSAL_NOT_FOUND
        ))
        (voter-power (get-voting-power tx-sender))
      )
      ;; Validate voting conditions
      (asserts! (> voter-power u0) ERR_UNAUTHORIZED)
      (asserts! (< stacks-block-height (get expiry-height proposal))
        ERR_PROPOSAL_EXPIRED
      )
      (asserts!
        (is-none (map-get? member-votes {
          proposal-id: proposal-id,
          member: tx-sender,
        }))
        ERR_ALREADY_VOTED
      )

      ;; Record vote
      (map-set member-votes {
        proposal-id: proposal-id,
        member: tx-sender,
      }
        support
      )

      ;; Update vote tallies
      (map-set investment-proposals proposal-id
        (merge proposal {
          votes-for: (if support
            (+ (get votes-for proposal) voter-power)
            (get votes-for proposal)
          ),
          votes-against: (if support
            (get votes-against proposal)
            (+ (get votes-against proposal) voter-power)
          ),
        })
      )

      (ok true)
    )
  )
)

;; Execute approved proposal
(define-public (execute-proposal (proposal-id uint))
  (begin
    (try! (ensure-initialized))
    (try! (validate-proposal-exists proposal-id))

    (let (
        (proposal (unwrap! (map-get? investment-proposals proposal-id)
          ERR_PROPOSAL_NOT_FOUND
        ))
        (treasury-balance (stx-get-balance (as-contract tx-sender)))
      )
      ;; Validate execution conditions
      (asserts! (not (get is-executed proposal)) ERR_UNAUTHORIZED)
      (asserts! (>= stacks-block-height (get expiry-height proposal))
        ERR_PROPOSAL_EXPIRED
      )
      (asserts! (> (get votes-for proposal) (get votes-against proposal))
        ERR_UNAUTHORIZED
      )
      (asserts! (>= treasury-balance (get funding-amount proposal))
        ERR_INSUFFICIENT_BALANCE
      )