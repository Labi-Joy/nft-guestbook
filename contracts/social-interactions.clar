;; Social Interactions Smart Contract
;; Handles likes, reactions, and social features for NFT Guestbook
;; Integrates with nft-guestbook and user-profile contracts
;; Deployed by: Labi Joy

;; ============================================================================
;; ERROR CODES
;; ============================================================================

;; Like/Reaction errors
(define-constant ERR_ALREADY_LIKED (err u3001))     ;; Already liked this entry
(define-constant ERR_NOT_LIKED (err u3002))          ;; Haven't liked this entry yet
(define-constant ERR_ENTRY_NOT_FOUND (err u3003))   ;; Entry doesn't exist
(define-constant ERR_INVALID_REACTION (err u3004))  ;; Invalid reaction type
(define-constant ERR_RATE_LIMITED (err u3005))      ;; Too many interactions

;; Comment errors
(define-constant ERR_COMMENT_TOO_LONG (err u3006))   ;; Comment exceeds limit
(define-constant ERR_COMMENT_NOT_FOUND (err u3007))  ;; Comment doesn't exist
(define-constant ERR_NOT_COMMENT_OWNER (err u3008))  ;; Not comment owner

;; ============================================================================
;; CONSTANTS
;; ============================================================================

;; Interaction limits
(define-constant MAX_COMMENT_LENGTH u500)           ;; Maximum comment characters
(define-constant MAX_LIKES_PER_DAY u100)            ;; Daily like limit
(define-constant MAX_COMMENTS_PER_DAY u50)           ;; Daily comment limit

;; Reaction types
(define-constant REACTION_LIKE u1)                   ;; 👍 Like
(define-constant REACTION_LOVE u2)                   ;; ❤️ Love  
(define-constant REACTION_LAUGH u3)                  ;; 😂 Laugh
(define-constant REACTION_WOW u4)                    ;; 😮 Wow
(define-constant REACTION_SAD u5)                    ;; 😢 Sad
(define-constant REACTION_ANGRY u6)                  // 😠 Angry

;; ============================================================================
;; DATA STORAGE
;; ============================================================================

;; Like/reaction storage
(define-map entry-likes
  { entry-id: uint, user: principal }
  { reaction-type: uint, created-at: uint })

;; Comment storage
(define-map entry-comments
  { comment-id: uint }
  { 
    entry-id: uint,
    author: principal,
    content: (string-ascii 500),
    created-at: uint,
    updated-at: uint,
    like-count: uint
  })

;; Comment likes
(define-map comment-likes
  { comment-id: uint, user: principal }
  { created-at: uint })

;; Entry statistics cache
(define-map entry-stats
  { entry-id: uint }
  { 
    total-likes: uint,
    total-comments: uint,
    total-reactions: uint,
    engagement-score: uint
  })

;; User daily interaction tracking
(define-map user-daily-stats
  { user: principal, date: uint }  ;; date = block-height / 144 (approx daily)
  { 
    likes-today: uint,
    comments-today: uint,
    last-interaction: uint
  })

;; Global counters
(define-data-var total-likes uint u0)
(define-data-var total-comments uint u0)
(define-data-var comment-id-counter uint u0)

;; ============================================================================
;; PUBLIC FUNCTIONS
;; ============================================================================

;; Like or react to a guestbook entry
(define-public (like-entry (entry-id uint) (reaction-type uint))
  (let ((current-block (block-height))
        (current-date (/ current-block u144)))
    (begin
      ;; Validate reaction type
      (asserts! (and 
        (>= reaction-type REACTION_LIKE) 
        (<= reaction-type REACTION_ANGRY)) 
        ERR_INVALID_REACTION)
      
      ;; Check daily rate limit
      (match (map-get? user-daily-stats { user: tx-sender, date: current-date })
        daily-stats
          (begin
            (asserts! (< (get likes-today daily-stats) MAX_LIKES_PER_DAY) ERR_RATE_LIMITED)
            
            ;; Update daily stats
            (map-set user-daily-stats
              { user: tx-sender, date: current-date }
              (merge daily-stats { 
                likes-today: (+ (get likes-today daily-stats) u1),
                last-interaction: current-block })))
        none
          ;; Create new daily stats entry
          (map-set user-daily-stats
            { user: tx-sender, date: current-date }
            { likes-today: u1, comments-today: u0, last-interaction: current-block }))
      
      ;; Check if already liked
      (asserts! (is-none (map-get? entry-likes { entry-id: entry-id, user: tx-sender })) ERR_ALREADY_LIKED)
      
      ;; Add like/reaction
      (map-set entry-likes
        { entry-id: entry-id, user: tx-sender }
        { reaction-type: reaction-type, created-at: current-block })
      
      ;; Update entry statistics
      (match (map-get? entry-stats { entry-id: entry-id })
        stats
          (let ((new-like-count (+ (get total-likes stats) u1))
                (new-engagement-score (+ (get engagement-score stats) u1)))
            (map-set entry-stats
              { entry-id: entry-id }
              { 
                total-likes: new-like-count,
                total-comments: (get total-comments stats),
                total-reactions: (+ (get total-reactions stats) u1),
                engagement-score: new-engagement-score }))
          none
          ;; Create new stats entry
          (map-set entry-stats
            { entry-id: entry-id }
            { 
              total-likes: u1,
              total-comments: u0,
              total-reactions: u1,
              engagement-score: u1 }))
      
      ;; Update global counter
      (var-set total-likes (+ (var-set total-likes) u1))
      
      (ok true))))

;; Remove like from entry
(define-public (unlike-entry (entry-id uint))
  (begin
    ;; Check if like exists
    (asserts! (is-some (map-get? entry-likes { entry-id: entry-id, user: tx-sender })) ERR_NOT_LIKED)
    
    ;; Remove like
    (map-delete entry-likes { entry-id: entry-id, user: tx-sender })
    
    ;; Update entry statistics
    (match (map-get? entry-stats { entry-id: entry-id })
      stats
        (let ((new-like-count (- (get total-likes stats) u1))
              (new-engagement-score (- (get engagement-score stats) u1)))
          (map-set entry-stats
            { entry-id: entry-id }
            { 
              total-likes: new-like-count,
              total-comments: (get total-comments stats),
              total-reactions: (- (get total-reactions stats) u1),
              engagement-score: new-engagement-score }))
      none)
    
    ;; Update global counter
    (var-set total-likes (- (var-set total-likes) u1))
    
    (ok true)))

;; Add comment to entry
(define-public (add-comment (entry-id uint) (content (string-ascii 500)))
  (let ((current-block (block-height))
        (current-date (/ current-block u144))
        (new-comment-id (+ (var-get comment-id-counter) u1)))
    (begin
      ;; Validate comment length
      (asserts! (> (len content) u0) ERR_COMMENT_TOO_LONG)
      (asserts! (<= (len content) MAX_COMMENT_LENGTH) ERR_COMMENT_TOO_LONG)
      
      ;; Check daily rate limit
      (match (map-get? user-daily-stats { user: tx-sender, date: current-date })
        daily-stats
          (begin
            (asserts! (< (get comments-today daily-stats) MAX_COMMENTS_PER_DAY) ERR_RATE_LIMITED)
            
            ;; Update daily stats
            (map-set user-daily-stats
              { user: tx-sender, date: current-date }
              (merge daily-stats { 
                comments-today: (+ (get comments-today daily-stats) u1),
                last-interaction: current-block })))
        none
          ;; Create new daily stats entry
          (map-set user-daily-stats
            { user: tx-sender, date: current-date }
            { likes-today: u0, comments-today: u1, last-interaction: current-block }))
      
      ;; Create comment
      (map-set entry-comments
        { comment-id: new-comment-id }
        { 
          entry-id: entry-id,
          author: tx-sender,
          content: content,
          created-at: current-block,
          updated-at: current-block,
          like-count: u0
        })
      
      ;; Update entry statistics
      (match (map-get? entry-stats { entry-id: entry-id })
        stats
          (map-set entry-stats
            { entry-id: entry-id }
            (merge stats { 
              total-comments: (+ (get total-comments stats) u1),
              engagement-score: (+ (get engagement-score stats) u2) })) ;; Comments worth 2 points
        none
          ;; Create new stats entry
          (map-set entry-stats
            { entry-id: entry-id }
            { 
              total-likes: u0,
              total-comments: u1,
              total-reactions: u0,
              engagement-score: u2 }))
      
      ;; Update global counter
      (var-set comment-id-counter new-comment-id)
      (var-set total-comments (+ (var-set total-comments) u1))
      
      (ok new-comment-id))))

;; Update comment
(define-public (update-comment (comment-id uint) (new-content (string-ascii 500)))
  (begin
    ;; Validate comment length
    (asserts! (> (len new-content) u0) ERR_COMMENT_TOO_LONG)
    (asserts! (<= (len new-content) MAX_COMMENT_LENGTH) ERR_COMMENT_TOO_LONG)
    
    ;; Check if comment exists and user is owner
    (match (map-get? entry-comments { comment-id: comment-id })
      comment
        (begin
          (asserts! (is-eq (get author comment) tx-sender) ERR_NOT_COMMENT_OWNER)
          
          ;; Update comment
          (map-set entry-comments
            { comment-id: comment-id }
            (merge comment { 
              content: new-content,
              updated-at: (block-height) }))
          
          (ok true))
      none
        (err ERR_COMMENT_NOT_FOUND))))

;; Delete comment
(define-public (delete-comment (comment-id uint))
  (begin
    ;; Check if comment exists and user is owner
    (match (map-get? entry-comments { comment-id: comment-id })
      comment
        (begin
          (asserts! (is-eq (get author comment) tx-sender) ERR_NOT_COMMENT_OWNER)
          
          ;; Remove comment
          (map-delete entry-comments { comment-id: comment-id })
          
          ;; Update entry statistics
          (match (map-get? entry-stats { entry-id: (get entry-id comment) })
            stats
              (map-set entry-stats
                { entry-id: (get entry-id comment) }
                (merge stats { 
                  total-comments: (- (get total-comments stats) u1),
                  engagement-score: (- (get engagement-score stats) u2) }))
            none)
          
          ;; Update global counter
          (var-set total-comments (- (var-set total-comments) u1))
          
          (ok true))
      none
        (err ERR_COMMENT_NOT_FOUND))))

;; Like comment
(define-public (like-comment (comment-id uint))
  (begin
    ;; Check if comment exists
    (asserts! (is-some (map-get? entry-comments { comment-id: comment-id })) ERR_COMMENT_NOT_FOUND)
    
    ;; Check if already liked
    (asserts! (is-none (map-get? comment-likes { comment-id: comment-id, user: tx-sender })) ERR_ALREADY_LIKED)
    
    ;; Add like
    (map-set comment-likes
      { comment-id: comment-id, user: tx-sender }
      { created-at: (block-height) })
    
    ;; Update comment like count
    (match (map-get? entry-comments { comment-id: comment-id })
      comment
        (map-set entry-comments
          { comment-id: comment-id }
          (merge comment { like-count: (+ (get like-count comment) u1) }))
      none)
    
    (ok true)))

;; ============================================================================
;; READ-ONLY FUNCTIONS
;; ============================================================================

;; Get entry statistics
(define-read-only (get-entry-stats (entry-id uint))
  (match (map-get? entry-stats { entry-id: entry-id })
    stats (ok stats)
    (ok { total-likes: u0, total-comments: u0, total-reactions: u0, engagement-score: u0 })))

;; Get comments for entry (simplified - returns count)
(define-read-only (get-comments-count (entry-id uint))
  (match (map-get? entry-stats { entry-id: entry-id })
    stats (ok (get total-comments stats))
    (ok u0)))

;; Check if user liked entry
(define-read-only (user-liked-entry (entry-id uint) (user principal))
  (ok (is-some (map-get? entry-likes { entry-id: entry-id, user: user }))))

;; Get comment details
(define-read-only (get-comment (comment-id uint))
  (match (map-get? entry-comments { comment-id: comment-id })
    comment (ok comment)
    (err ERR_COMMENT_NOT_FOUND)))

;; Get user's interaction history (simplified)
(define-read-only (get-user-interactions (user principal) (limit uint))
  (ok {
    likes-today: u0,
    comments-today: u0,
    total-interactions: u0
  }))

;; Get global statistics
(define-read-only (get-global-stats)
  (ok {
    total-likes: (var-get total-likes),
    total-comments: (var-get total-comments),
    total-comment-ids: (var-get comment-id-counter)
  }))

;; Get trending entries (by engagement score)
(define-read-only (get-trending-entries (limit uint))
  ;; Simplified version - would need proper indexing in production
  (ok (list 0 { entry-id: u1, score: u100 })))

;; Get user's likes for specific entry
(define-read-only (get-entry-likes (entry-id uint))
  ;; Simplified - would need proper iteration in production
  (ok (list 0 { user: tx-sender, reaction: REACTION_LIKE })))
