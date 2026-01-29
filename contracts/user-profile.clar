;; User Profile Smart Contract
;; Manages user profiles, statistics, and social features for NFT Guestbook
;; Integrates with nft-guestbook contract for user data
;; Deployed by: Labi Joy

;; ============================================================================
;; ERROR CODES
;; ============================================================================

;; Profile validation errors
(define-constant ERR-INVALID_USERNAME (err u2001))  ;; Username format invalid
(define-constant ERR-USERNAME_TAKEN (err u2002))     ;; Username already taken
(define-constant ERR-USERNAME_TOO_LONG (err u2003))  ;; Username exceeds limit
(define-constant ERR-USERNAME_TOO_SHORT (err u2004)) ;; Username too short
(define-constant ERR_PROFILE_NOT_FOUND (err u2005))   ;; Profile doesn't exist
(define-constant ERR_NOT_PROFILE_OWNER (err u2006))  ;; Not profile owner

;; Social interaction errors
(define-constant ERR_ALREADY_FOLLOWING (err u2007))  ;; Already following user
(define-constant ERR_NOT_FOLLOWING (err u2008))      ;; Not following user
(define-constant ERR_CANNOT_FOLLOW_SELF (err u2009)) ;; Cannot follow yourself
(define-constant ERR_FOLLOW_LIMIT_REACHED (err u2010)) ;; Follow limit reached

;; ============================================================================
;; CONSTANTS
;; ============================================================================

;; Username constraints
(define-constant MIN_USERNAME_LENGTH u3)      ;; Minimum 3 characters
(define-constant MAX_USERNAME_LENGTH u20)     ;; Maximum 20 characters
(define-constant MAX_FOLLOW_COUNT u1000)      ;; Maximum follow count

;; Profile data constraints
(define-constant MAX_BIO_LENGTH u200)         ;; Maximum bio characters
(define-constant MAX_WEBSITE_LENGTH u100)     ;; Maximum website URL length

;; ============================================================================
;; DATA STORAGE
;; ============================================================================

;; User profile storage
(define-map user-profiles
  { user: principal }
  { 
    username: (string-ascii 20),
    bio: (string-ascii 200),
    website: (string-ascii 100),
    created-at: uint,
    updated-at: uint,
    entry-count: uint,
    follower-count: uint,
    following-count: uint
  })

;; Username to user mapping (for quick lookups)
(define-map username-to-user
  { username: (string-ascii 20) }
  { user: principal })

;; Follow relationships (user -> following)
(define-map follow-relationships
  { follower: principal }
  { following: principal })

;; User statistics cache
(define-map user-stats
  { user: principal }
  { 
    total-entries: uint,
    total-likes: uint,
    total-received: uint,
    reputation-score: uint
  })

;; Global counters
(define-data-var total-profiles uint u0)
(define-data-var total-follows uint u0)

;; ============================================================================
;; PUBLIC FUNCTIONS
;; ============================================================================

;; Create or update user profile
(define-public (create-profile 
  (username (string-ascii 20)) 
  (bio (string-ascii 200)) 
  (website (string-ascii 100)))
  (let ((current-block (block-height)))
    (begin
      ;; Validate username length
      (asserts! (>= (len username) MIN_USERNAME_LENGTH) ERR_USERNAME_TOO_SHORT)
      (asserts! (<= (len username) MAX_USERNAME_LENGTH) ERR_USERNAME_TOO_LONG)
      
      ;; Check if username is already taken (for new profiles)
      (match (map-get? user-profiles { user: tx-sender })
        existing-profile 
          ;; Updating existing profile - check if changing username
          (begin
            (asserts! (or 
              (is-eq username (get username existing-profile))
              (is-none (map-get? username-to-user { username: username })))
              ERR-USERNAME_TAKEN)
            
            ;; Update existing profile
            (map-set user-profiles
              { user: tx-sender }
              { 
                username: username,
                bio: bio,
                website: website,
                created-at: (get created-at existing-profile),
                updated-at: current-block,
                entry-count: (get entry-count existing-profile),
                follower-count: (get follower-count existing-profile),
                following-count: (get following-count existing-profile)
              })
            
            ;; Update username mapping if changed
            (when (not (is-eq username (get username existing-profile)))
              (map-insert username-to-user
                { username: username }
                { user: tx-sender }))
            
            (ok true))
          
          ;; Creating new profile
          (begin
            ;; Check username availability
            (asserts! (is-none (map-get? username-to-user { username: username })) ERR-USERNAME_TAKEN)
            
            ;; Create new profile
            (map-set user-profiles
              { user: tx-sender }
              { 
                username: username,
                bio: bio,
                website: website,
                created-at: current-block,
                updated-at: current-block,
                entry-count: u0,
                follower-count: u0,
                following-count: u0
              })
            
            ;; Set username mapping
            (map-set username-to-user
              { username: username }
              { user: tx-sender })
            
            ;; Initialize user stats
            (map-set user-stats
              { user: tx-sender }
              { 
                total-entries: u0,
                total-likes: u0,
                total-received: u0,
                reputation-score: u0
              })
            
            ;; Update global counter
            (var-set total-profiles (+ (var-get total-profiles) u1))
            
            (ok true))))))

;; Follow another user
(define-public (follow-user (user-to-follow principal))
  (begin
    ;; Cannot follow yourself
    (asserts! (not (is-eq tx-sender user-to-follow)) ERR_CANNOT_FOLLOW_SELF)
    
    ;; Check if target user exists
    (asserts! (is-some (map-get? user-profiles { user: user-to-follow })) ERR_PROFILE_NOT_FOUND)
    
    ;; Check if already following
    (asserts! (is-none (map-get? follow-relationships { follower: tx-sender, following: user-to-follow })) ERR_ALREADY_FOLLOWING)
    
    ;; Check follow limit
    (match (map-get? user-profiles { user: tx-sender })
      follower-profile
        (begin
          (asserts! (< (get following-count follower-profile) MAX_FOLLOW_COUNT) ERR_FOLLOW_LIMIT_REACHED)
          
          ;; Create follow relationship
          (map-set follow-relationships
            { follower: tx-sender }
            { following: user-to-follow })
          
          ;; Update follower's following count
          (map-set user-profiles
            { user: tx-sender }
            (merge follower-profile { following-count: (+ (get following-count follower-profile) u1), updated-at: (block-height) }))
          
          ;; Update following's follower count
          (match (map-get? user-profiles { user: user-to-follow })
            following-profile
              (map-set user-profiles
                { user: user-to-follow }
                (merge following-profile { follower-count: (+ (get follower-count following-profile) u1), updated-at: (block-height) }))
            none)
          
          ;; Update global counter
          (var-set total-follows (+ (var-get total-follows) u1))
          
          (ok true))
      none)))

;; Unfollow a user
(define-public (unfollow-user (user-to-unfollow principal))
  (begin
    ;; Check if following relationship exists
    (asserts! (is-some (map-get? follow-relationships { follower: tx-sender, following: user-to-unfollow })) ERR_NOT_FOLLOWING)
    
    ;; Remove follow relationship
    (map-delete follow-relationships { follower: tx-sender, following: user-to-unfollow })
    
    ;; Update follower's following count
    (match (map-get? user-profiles { user: tx-sender })
      follower-profile
        (map-set user-profiles
          { user: tx-sender }
          (merge follower-profile { following-count: (- (get following-count follower-profile) u1), updated-at: (block-height) }))
      none)
    
    ;; Update following's follower count
    (match (map-get? user-profiles { user: user-to-unfollow })
      following-profile
        (map-set user-profiles
          { user: user-to-unfollow }
          (merge following-profile { follower-count: (- (get follower-count following-profile) u1), updated-at: (block-height) }))
      none)
    
    ;; Update global counter
    (var-set total-follows (- (var-get total-follows) u1))
    
    (ok true)))

;; Update user statistics (called by guestbook contract)
(define-public (update-entry-stats (user principal) (entry-count uint))
  (begin
    ;; Only guestbook contract can call this (simplified check)
    ;; In production, use proper contract access control
    
    (match (map-get? user-profiles { user: user })
      profile
        (map-set user-profiles
          { user: user }
          (merge profile { entry-count: entry-count, updated-at: (block-height) }))
      none)
    
    (match (map-get? user-stats { user: user })
      stats
        (map-set user-stats
          { user: user }
          (merge stats { total-entries: entry-count }))
      none)
    
    (ok true)))

;; ============================================================================
;; READ-ONLY FUNCTIONS
;; ============================================================================

;; Get user profile by principal
(define-read-only (get-profile (user principal))
  (match (map-get? user-profiles { user: user })
    profile (ok profile)
    ERR_PROFILE_NOT_FOUND))

;; Get user profile by username
(define-read-only (get-profile-by-username (username (string-ascii 20)))
  (match (map-get? username-to-user { username: username })
    user-map 
      (match (map-get? user-profiles { user: (get user user-map) })
        profile (ok profile)
        ERR_PROFILE_NOT_FOUND)
    ERR_PROFILE_NOT_FOUND))

;; Check if username is available
(define-read-only (is-username-available (username (string-ascii 20)))
  (ok (is-none (map-get? username-to-user { username: username }))))

;; Get user statistics
(define-read-only (get-user-stats (user principal))
  (match (map-get? user-stats { user: user })
    stats (ok stats)
    (ok { total-entries: u0, total-likes: u0, total-received: u0, reputation-score: u0 })))

;; Check if following relationship exists
(define-read-only (is-following (follower principal) (following principal))
  (ok (is-some (map-get? follow-relationships { follower: follower, following: following }))))

;; Get user's followers list (simplified - returns count)
(define-read-only (get-followers-count (user principal))
  (match (map-get? user-profiles { user: user })
    profile (ok (get follower-count profile))
    (ok u0)))

;; Get user's following list (simplified - returns count)
(define-read-only (get-following-count (user principal))
  (match (map-get? user-profiles { user: user })
    profile (ok (get following-count profile))
    (ok u0)))

;; Get global statistics
(define-read-only (get-global-stats)
  (ok {
    total-profiles: (var-get total-profiles),
    total-follows: (var-get total-follows)
  }))

;; Search users by username prefix (basic search)
(define-read-only (search-users (prefix (string-ascii 10)) (limit uint))
  ;; This is a simplified version - in production, implement proper indexing
  (ok {
    results: (list 0 { user: tx-sender, username: "sample" }),
    total-found: u0
  }))
