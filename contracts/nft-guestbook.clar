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

;; Contract owner (receives minting fees) - REPLACE WITH YOUR MAINNET ADDRESS  
(define-constant CONTRACT-OWNER 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)

;; Mint price: 1 STX = 1,000,000 micro-STX
(define-constant MINT-PRICE u1000000)

;; Maximum message length: 280 characters
(define-constant MAX-MESSAGE-LENGTH u280)

;; SIP-009 NFT implementation
(define-non-fungible-token nft-guestbook-token uint)

;; Data maps
(define-map token-metadata
  { token-id: uint }
  { message: (string-ascii 280), 
    minter: principal })

;; Counter for sequential token IDs
(define-data-var last-token-id uint u0)
;; Mint function - creates a new guestbook entry
(define-public (mint-entry (message (string-ascii 280)))
  (let ((new-token-id (+ (var-get last-token-id) u1)))
    (begin
      ;; Validate message length
      (asserts! (<= (len message) MAX-MESSAGE-LENGTH) ERR-MESSAGE-TOO-LONG)
      
      ;; Update token counter
      (var-set last-token-id new-token-id)
      
      ;; Store token metadata
      (map-set token-metadata
        { token-id: new-token-id }
        { message: message,
          minter: tx-sender })
      
      ;; Mint the NFT to the minter
      (try! (nft-mint? nft-guestbook-token new-token-id tx-sender))
      
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
  (ok (some "https://example.com/metadata")))

;; Read-only function to get token owner (SIP-009 compliance)
(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? nft-guestbook-token token-id)))

;; Transfer function - DISABLED for soul-bound NFTs
(define-public (transfer (recipient principal) (token-id uint))
  (begin
    ;; Always fail - these NFTs are soul-bound
    ERR-TRANSFER-DISABLED))

;; Helper function to check if a token exists
(define-read-only (token-exists? (token-id uint))
  (is-some (nft-get-owner? nft-guestbook-token token-id)))

;; Get total number of entries
(define-read-only (get-total-entries)
  (ok (var-get last-token-id)))

