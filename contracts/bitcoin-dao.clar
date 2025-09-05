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