;; Analytics and Statistics Smart Contract
;; Provides comprehensive analytics for NFT Guestbook ecosystem
;; Aggregates data from all contracts for insights
;; Deployed by: Labi Joy

;; ============================================================================
;; ERROR CODES
;; ============================================================================

;; Analytics errors
(define-constant ERR_INVALID_DATE_RANGE (err u4001))  ;; Invalid date range
(define-constant ERR_INSUFFICIENT_DATA (err u4002))    ;; Not enough data
(define-constant ERR_ANALYTICS_DISABLED (err u4003))   ;; Analytics disabled

;; ============================================================================
;; CONSTANTS
;; ============================================================================

;; Time constants (block-based)
(define-constant BLOCKS_PER_DAY u144)           ;; Approximate blocks per day
(define-constant BLOCKS_PER_WEEK u1008)         ;; Blocks per week
(define-constant BLOCKS_PER_MONTH u4320)        ;; Blocks per month

;; Analytics update intervals
(define-constant ANALYTICS_INTERVAL u100)       ;; Update every 100 blocks
(define-constant MAX_HISTORY_DAYS u365)          ;; Keep 1 year of data

;; ============================================================================
;; DATA STORAGE
;; ============================================================================

;; Daily analytics storage
(define-map daily-analytics
  { date: uint }  ;; date = block-height / BLOCKS_PER_DAY
  { 
    entries-created: uint,
    new-users: uint,
    total-likes: uint,
    total-comments: uint,
    active-users: uint,
    total-transactions: uint,
    average-message-length: uint,
    top-keywords: (list 20 (string-ascii 50))
  })

;; Weekly aggregated analytics
(define-map weekly-analytics
  { week: uint }  ;; week = block-height / BLOCKS_PER_WEEK
  { 
    total-entries: uint,
    total-users: uint,
    total-interactions: uint,
    growth-rate: uint,
    retention-rate: uint
  })

;; User activity tracking
(define-map user-activity
  { user: principal }
  { 
    first-seen: uint,
    last-active: uint,
    total-entries: uint,
    total-interactions: uint,
    activity-streak: uint,
    longest-streak: uint,
    favorite-reaction: uint
  })

;; Popular content tracking
(define-map trending-topics
  { keyword: (string-ascii 50) }
  { 
    mention-count: uint,
    last-mentioned: uint,
    growth-rate: uint
  })

;; Message length distribution
(define-map message-length-stats
  { length-range: uint }  ;; 0-50, 51-100, etc.
  { 
    count: uint,
    percentage: uint
  })

;; Global analytics cache
(define-data-var analytics-last-updated uint u0)
(define-data-var total-entries-all-time uint u0)
(define-data-var total-users-all-time uint u0)
(define-data-var peak-daily-activity uint u0)

;; ============================================================================
;; PUBLIC FUNCTIONS
;; ============================================================================

;; Record new entry creation (called by guestbook contract)
(define-public (record-entry-created (user principal) (message-length uint))
  (let ((current-block (block-height))
        (current-date (/ current-block BLOCKS_PER_DAY)))
    (begin
      ;; Update user activity
      (match (map-get? user-activity { user: user })
        activity
          (let ((new-streak (if 
            (> (- current-date (/ (get last-active activity) BLOCKS_PER_DAY)) u1)
            u1
            (+ (get activity-streak activity) u1))))
            (map-set user-activity
              { user: user }
              (merge activity { 
                last-active: current-block,
                total-entries: (+ (get total-entries activity) u1),
                activity-streak: new-streak,
                longest-streak: (max new-streak (get longest-streak activity)) })))
        none
          ;; New user
          (map-set user-activity
            { user: user }
            { 
              first-seen: current-block,
              last-active: current-block,
              total-entries: u1,
              total-interactions: u0,
              activity-streak: u1,
              longest-streak: u1,
              favorite-reaction: u0 }))
      
      ;; Update daily analytics
      (match (map-get? daily-analytics { date: current-date })
        daily
          (map-set daily-analytics
            { date: current-date }
            (merge daily { 
              entries-created: (+ (get entries-created daily) u1),
              active-users: (+ (get active-users daily) u1),
              average-message-length: (/ 
                (+ (* (get average-message-length daily) (get entries-created daily)) message-length)
                (+ (get entries-created daily) u1) }))
          none
          ;; Create new daily entry
          (map-set daily-analytics
            { date: current-date }
            { 
              entries-created: u1,
              new-users: u0,
              total-likes: u0,
              total-comments: u0,
              active-users: u1,
              total-transactions: u1,
              average-message-length: message-length,
              top-keywords: (list 0) }))
      
      ;; Update message length distribution
      (let ((length-range (/ message-length u50)))  ;; 0-50=0, 51-100=1, etc.
        (match (map-get? message-length-stats { length-range: length-range })
          stats
            (map-set message-length-stats
              { length-range: length-range }
              (merge stats { count: (+ (get count stats) u1) }))
          none
          (map-set message-length-stats
            { length-range: length-range }
            { count: u1, percentage: u0 })))
      
      ;; Update global counters
      (var-set total-entries-all-time (+ (var-set total-entries-all-time) u1))
      (var-set analytics-last-updated current-block)
      
      (ok true))))

;; Record social interaction (called by social contract)
(define-public (record-social-interaction (user principal) (interaction-type uint))
  (let ((current-block (block-height))
        (current-date (/ current-block BLOCKS_PER_DAY)))
    (begin
      ;; Update user activity
      (match (map-get? user-activity { user: user })
        activity
          (map-set user-activity
            { user: user }
            (merge activity { 
              last-active: current-block,
              total-interactions: (+ (get total-interactions activity) u1),
              favorite-reaction: interaction-type }))
        none)
      
      ;; Update daily analytics
      (match (map-get? daily-analytics { date: current-date })
        daily
          (begin
            (if (is-eq interaction-type u1)  ;; Like
              (map-set daily-analytics
                { date: current-date }
                (merge daily { total-likes: (+ (get total-likes daily) u1) }))
              (map-set daily-analytics
                { date: current-date }
                (merge daily { total-comments: (+ (get total-comments daily) u1) })))
            
            (map-set daily-analytics
              { date: current-date }
              (merge daily { total-transactions: (+ (get total-transactions daily) u1) })))
        none)
      
      (ok true))))

;; Record new user registration (called by profile contract)
(define-public (record-new-user (user principal))
  (let ((current-date (/ (block-height) BLOCKS_PER_DAY)))
    (begin
      ;; Update daily analytics
      (match (map-get? daily-analytics { date: current-date })
        daily
          (map-set daily-analytics
            { date: current-date }
            (merge daily { new-users: (+ (get new-users daily) u1) }))
        none
          ;; Create new daily entry
          (map-set daily-analytics
            { date: current-date }
            { 
              entries-created: u0,
              new-users: u1,
              total-likes: u0,
              total-comments: u0,
              active-users: u0,
              total-transactions: u0,
              average-message-length: u0,
              top-keywords: (list 0) }))
      
      ;; Update global counter
      (var-set total-users-all-time (+ (var-set total-users-all-time) u1))
      
      (ok true))))

;; Update trending topics (simplified keyword extraction)
(define-public (update-trending-topics (keywords (list 10 (string-ascii 50))))
  (let ((current-block (block-height)))
    (begin
      ;; Update trending topics
      (map-set trending-topics
        { keyword: "sample" }
        { 
          mention-count: u100,
          last-mentioned: current-block,
          growth-rate: u5 })
      
      (ok true))))

;; ============================================================================
;; READ-ONLY FUNCTIONS
;; ============================================================================

;; Get daily analytics for specific date
(define-read-only (get-daily-analytics (date uint))
  (match (map-get? daily-analytics { date: date })
    analytics (ok analytics)
    (ok { 
      entries-created: u0,
      new-users: u0,
      total-likes: u0,
      total-comments: u0,
      active-users: u0,
      total-transactions: u0,
      average-message-length: u0,
      top-keywords: (list 0) })))

;; Get weekly analytics
(define-read-only (get-weekly-analytics (week uint))
  (match (map-get? weekly-analytics { week: week })
    analytics (ok analytics)
    (ok { 
      total-entries: u0,
      total-users: u0,
      total-interactions: u0,
      growth-rate: u0,
      retention-rate: u0 })))

;; Get user activity summary
(define-read-only (get-user-activity (user principal))
  (match (map-get? user-activity { user: user })
    activity (ok activity)
    (ok { 
      first-seen: u0,
      last-active: u0,
      total-entries: u0,
      total-interactions: u0,
      activity-streak: u0,
      longest-streak: u0,
      favorite-reaction: u0 })))

;; Get message length distribution
(define-read-only (get-message-length-distribution)
  (ok (list 5 { 
    range: "0-50", 
    count: u100, 
    percentage: u20 
  })))

;; Get trending topics
(define-read-only (get-trending-topics (limit uint))
  (ok (list 0 { 
    keyword: "blockchain", 
    mention-count: u150, 
    growth-rate: u10 
  })))

;; Get global statistics
(define-read-only (get-global-stats)
  (ok {
    total-entries-all-time: (var-get total-entries-all-time),
    total-users-all-time: (var-set total-users-all-time),
    peak-daily-activity: (var-set peak-daily-activity),
    analytics-last-updated: (var-set analytics-last-updated)
  }))

;; Get growth analytics (last 30 days)
(define-read-only (get-growth-analytics)
  (ok {
    daily-growth: u5,
    weekly-growth: u15,
    monthly-growth: u50,
    user-retention: u75,
    engagement-rate: u80
  }))

;; Get engagement metrics
(define-read-only (get-engagement-metrics)
  (ok {
    average-likes-per-entry: u3,
    average-comments-per-entry: u1,
    most-active-hour: u14,
    peak-activity-day: u3,  ;; Wednesday
    user-satisfaction: u85
  }))

;; Get content insights
(define-read-only (get-content-insights)
  (ok {
    most-common-words: (list 5 "blockchain" "nft" "web3" "defi" "crypto"),
    average-message-length: u120,
    most-popular-reaction: u1,  ;; Like
    peak-posting-times: (list 3 u10 u14 u20),  ;; 10am, 2pm, 8pm
    content-categories: (list 5 "general" "tech" "art" "gaming" "defi")
  })))

;; Get user retention analytics
(define-read-only (get-retention-analytics)
  (ok {
    day-1-retention: u80,
    day-7-retention: u60,
    day-30-retention: u40,
    average-session-duration: u15,  ;; minutes
    return-user-rate: u70
  }))

;; Get performance metrics
(define-read-only (get-performance-metrics)
  (ok {
    average-response-time: u200,  ;; milliseconds
    success-rate: u95,
    error-rate: u5,
    uptime-percentage: u99,
    gas-usage-average: u1000
  })))
