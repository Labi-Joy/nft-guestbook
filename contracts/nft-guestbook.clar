;; NFT Guestbook Smart Contract
;; Implements SIP-009 NFT standard for soul-bound guestbook entries
;; Each NFT represents a guestbook entry with a message and minter info

;; Constants
(define-constant ERR-INVALID-MESSAGE (err u1001))
(define-constant ERR-MESSAGE-TOO-LONG (err u1002))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u1003))
(define-constant ERR-TOKEN-NOT-FOUND (err u1004))
(define-constant ERR-NOT-AUTHORIZED (err u1005))
(define-constant ERR-TRANSFER-DISABLED (err u1006))

;; Contract owner (receives minting fees)
(define-constant CONTRACT-OWNER tx-sender)

;; Mint price: 1 STX = 1,000,000 micro-STX
(define-constant MINT-PRICE u1000000)

;; Maximum message length: 280 characters
(define-constant MAX-MESSAGE-LENGTH u280)

;; NFT trait for SIP-009 compliance
(define-fungible-token guestbook-token)

;; Data maps
(define-map token-owners
  { token-id: uint }
  { owner: principal })

(define-map token-metadata
  { token-id: uint }
  { message: (string-ascii 280) 
    minter: principal 
    block-height: uint })

;; Counter for sequential token IDs
(define-data-var last-token-id uint u0)

;; SIP-009 NFT Trait Implementation
(define-trait nft-trait
  ((transfer? (principal principal uint) (response bool uint))
   (owner? (uint) (response principal uint))
   (token-uri? (uint) (response (string-utf8 256) uint))
   (get-last-token-id () (response uint uint))))

;; Mint function - creates a new guestbook entry
(define-public (mint-entry (message (string-ascii 280)))
  (begin
    ;; Validate message length
    (asserts! (<= (len-of message) MAX-MESSAGE-LENGTH) ERR-MESSAGE-TOO-LONG)
    
    ;; Validate payment
    (asserts! (>= (stx-get-balance tx-sender) MINT-PRICE) ERR-INSUFFICIENT-PAYMENT)
    
    ;; Transfer payment to contract owner
    (try! (stx-transfer? MINT-PRICE tx-sender CONTRACT-OWNER))
    
    ;; Generate new token ID
    (let ((new-token-id (+ (var-get last-token-id) u1)))
      ;; Update token counter
      (var-set last-token-id new-token-id)
      
      ;; Store token ownership
      (map-set token-owners 
        { token-id: new-token-id } 
        { owner: tx-sender })
      
      ;; Store token metadata
      (map-set token-metadata
        { token-id: new-token-id }
        { message: message
          minter: tx-sender
          block-height: block-height })
      
      ;; Mint the NFT to the minter
      (ft-mint? guestbook-token u1 tx-sender)
      
      (ok new-token-id))))

;; Read-only function to get entry details
(define-read-only (get-entry (token-id uint))
  (match (map-get? token-metadata { token-id: token-id })
    metadata (ok metadata)
    ERR-TOKEN-NOT-FOUND))

;; Read-only function to get the last token ID
(define-read-only (get-last-token-id)
  (ok (var-get last-token-id)))

;; Read-only function to get token URI (SIP-009 compliance)
(define-read-only (get-token-uri (token-id uint))
  (ok (some (string-utf8 "https://example.com/metadata"))))

;; Read-only function to get token owner (SIP-009 compliance)
(define-read-only (get-owner (token-id uint))
  (match (map-get? token-owners { token-id: token-id })
    ownership (ok (get owner ownership))
    ERR-TOKEN-NOT-FOUND))

;; Transfer function - DISABLED for soul-bound NFTs
(define-public (transfer (recipient principal) (token-id uint))
  (begin
    ;; Always fail - these NFTs are soul-bound
    ERR-TRANSFER-DISABLED))

;; Helper function to check if a token exists
(define-read-only (token-exists? (token-id uint))
  (match (map-get? token-owners { token-id: token-id })
    ownership true
    false))

;; Helper function to get all entries for a user
(define-read-only (get-user-entries (user principal))
  (begin
    (let ((last-id (var-get last-token-id))
          (user-entries (list 0)))
      ;; Iterate through all tokens and collect user's entries
      (fold get-user-entry-helper
        user-entries
        (range u1 (+ last-id u1))))))

;; Helper function for folding through user entries
(define-private (get-user-entry-helper (current-list (list 0)) (token-id uint))
  (match (map-get? token-owners { token-id: token-id })
    ownership
      (if (is-eq (get owner ownership) tx-sender)
        (append current-list token-id)
        current-list)
    current-list))

;; Get total number of entries
(define-read-only (get-total-entries)
  (ok (var-get last-token-id)))
