;; NFT Guestbook Smart Contract
;; Implements SIP-009 NFT standard for soul-bound guestbook entries
;; Each NFT represents a guestbook entry with a message and minter info
;; Deployed by: Labi Joy

;; ============================================================================
;; ERROR CODES
;; All errors return (err uXXXX) format for consistent error handling
;; ============================================================================

;; Message validation errors
(define-constant ERR-INVALID-MESSAGE (err u1001))  ;; Message contains invalid characters
(define-constant ERR-MESSAGE-TOO-LONG (err u1002))  ;; Message exceeds 280 character limit
(define-constant ERR-MESSAGE-EMPTY (err u1003))    ;; Message cannot be empty

;; Payment errors (for future payment implementation)
(define-constant ERR-INSUFFICIENT-PAYMENT (err u1004))  ;; Not enough STX sent for minting

;; Token and access errors
(define-constant ERR-TOKEN-NOT-FOUND (err u1005))     ;; Token ID does not exist
(define-constant ERR-NOT-AUTHORIZED (err u1006))      ;; Caller not authorized for action
(define-constant ERR-TRANSFER-DISABLED (err u1007))   ;; Transfer is disabled (soul-bound)

;; System errors
(define-constant ERR_MINT_FAILED (err u1008))         ;; NFT minting operation failed

;; ============================================================================
;; CONSTANTS
;; ============================================================================

;; Contract owner (receives minting fees) - REPLACE WITH YOUR MAINNET ADDRESS  
(define-constant CONTRACT-OWNER 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

;; Economic constants
(define-constant MINT-PRICE u1000000)  ;; 1 STX = 1,000,000 micro-STX

;; Message constraints
(define-constant MAX-MESSAGE-LENGTH u280)  ;; Twitter-style character limit
(define-constant MIN-MESSAGE-LENGTH u1)    ;; Minimum 1 character required

;; ============================================================================
;; SIP-009 NFT IMPLEMENTATION
;; ============================================================================

;; Non-fungible token definition
(define-non-fungible-token nft-guestbook-token uint)

;; ============================================================================
;; DATA STORAGE
;; ============================================================================

;; Token metadata storage - maps token ID to message and minter info
(define-map token-metadata
  { token-id: uint }
  { message: (string-ascii 280), 
    minter: principal,
    created-at: uint })  ;; Block height when minted

;; Global counter for sequential token IDs
(define-data-var last-token-id uint u0)

;; Optional: Track total supply for efficient queries
(define-data-var total-supply uint u0)
;; ============================================================================
;; PUBLIC FUNCTIONS
;; ============================================================================

;; Mint function - creates a new guestbook entry
;; Validates message, updates counters, stores metadata, and mints NFT
(define-public (mint-entry (message (string-ascii 280)))
  (let ((new-token-id (+ (var-get last-token-id) u1))
        (current-block (block-height)))
    (begin
      ;; Validate message is not empty
      (asserts! (> (len message) u0) ERR-MESSAGE-EMPTY)
      
      ;; Validate message length
      (asserts! (<= (len message) MAX-MESSAGE-LENGTH) ERR-MESSAGE-TOO-LONG)
      
      ;; Update token counter
      (var-set last-token-id new-token-id)
      
      ;; Update total supply
      (var-set total-supply (+ (var-get total-supply) u1))
      
      ;; Store token metadata with creation timestamp
      (map-set token-metadata
        { token-id: new-token-id }
        { message: message,
          minter: tx-sender,
          created-at: current-block })
      
      ;; Mint the NFT to the minter with error handling
      (try! (nft-mint? nft-guestbook-token new-token-id tx-sender))
      
      (ok new-token-id))))

;; ============================================================================
;; READ-ONLY FUNCTIONS
;; ============================================================================

;; Get complete entry details including message, minter, and creation time
;; Returns (ok {message: string-ascii, minter: principal, created-at: uint}) or error
(define-read-only (get-entry (token-id uint))
  (match (map-get? token-metadata { token-id: token-id })
    metadata (ok metadata)
    ERR-TOKEN-NOT-FOUND))

;; Get the last minted token ID (useful for pagination and knowing next ID)
;; Returns (ok uint) with the current highest token ID
(define-read-only (get-last-token-id)
  (ok (var-get last-token-id)))

;; Get total number of entries minted so far
;; Returns (ok uint) with total supply count
(define-read-only (get-total-entries)
  (ok (var-get total-supply)))

;; Get token URI for SIP-009 compliance (metadata endpoint)
;; Returns (ok (some string)) with metadata URL or none if not set
(define-read-only (get-token-uri (token-id uint))
  (ok (some (concat "https://api.yourdomain.com/metadata/" (uint-to-string token-id)))))

;; Get current owner of a specific token (SIP-009 compliance)
;; Returns (ok (some principal)) with owner address or none if token doesn't exist
(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? nft-guestbook-token token-id)))

;; Check if a token exists (more efficient than get-owner for existence checks)
;; Returns true if token exists, false otherwise
(define-read-only (token-exists? (token-id uint))
  (is-some (nft-get-owner? nft-guestbook-token token-id)))

;; Get all entries by a specific minter (useful for user profiles)
;; Returns (ok {message: string-ascii, token-id: uint, created-at: uint}) for each entry
;; Note: This is a simplified version - in production you might want pagination
(define-read-only (get-entries-by-minter (minter principal) (limit uint))
  (begin
    ;; This is a placeholder - full implementation would require iteration
    ;; For now, return a sample response
    (ok { message: "Use frontend to fetch user entries", token-id: u1, created-at: u1000 })))

;; ============================================================================
;; SIP-009 COMPLIANCE FUNCTIONS
;; ============================================================================

;; Transfer function - DISABLED for soul-bound NFTs
;; These NFTs cannot be transferred once minted (soul-bound property)
(define-public (transfer (recipient principal) (token-id uint))
  (begin
    ;; Always fail - these NFTs are soul-bound and cannot be transferred
    ERR-TRANSFER-DISABLED))

;; ============================================================================
;; UTILITY FUNCTIONS
;; ============================================================================

;; Get contract information for frontend integration
;; Returns contract name, version, and total supply
(define-read-only (get-contract-info)
  (ok {
    name: "NFT Guestbook",
    version: u1,
    total-supply: (var-get total-supply),
    max-message-length: MAX-MESSAGE-LENGTH,
    mint-price: MINT_PRICE
  }))

;; Validate message format without minting (useful for frontend validation)
;; Returns ok if valid, error with details if invalid
(define-read-only (validate-message (message (string-ascii 280)))
  (begin
    (asserts! (> (len message) u0) ERR-MESSAGE-EMPTY)
    (asserts! (<= (len message) MAX-MESSAGE-LENGTH) ERR-MESSAGE-TOO-LONG)
    (ok true)))

