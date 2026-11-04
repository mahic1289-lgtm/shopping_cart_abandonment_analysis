-- Verify data and column quality for the KPIs in the reconciliation process.

SELECT
    COUNT(*) AS total_sessions,
    COUNT(DISTINCT session_id) AS unique_sessions,
    COUNT(*) FILTER (
        WHERE drop_off_stage = 'Success'
    ) AS successful_purchases,
    COUNT(*) FILTER (
        WHERE drop_off_stage <> 'Success'
    ) AS abandoned_sessions
FROM shopping_analysis;


-- Overall conversion rate
SELECT
    COUNT(*) FILTER (
        WHERE drop_off_stage = 'Success'
    ) AS successful_purchases,

    COUNT(*) AS total_sessions,

    ROUND(
        COUNT(*) FILTER (
            WHERE drop_off_stage = 'Success'
        ) * 100.0 / COUNT(*),
        2
    ) AS conversion_rate
FROM shopping_analysis;


-- Calculate cart abandonment rate
SELECT
    COUNT(*) FILTER (
        WHERE drop_off_stage = 'Cart'
    ) AS abandoned_carts,

    COUNT(*) FILTER (
        WHERE drop_off_stage IN ('Cart', 'Checkout', 'Payment', 'Success')
    ) AS sessions_reached_cart,

    ROUND(
        COUNT(*) FILTER (
            WHERE drop_off_stage = 'Cart'
        ) * 100.0 /
        NULLIF(
            COUNT(*) FILTER (
                WHERE drop_off_stage IN ('Cart', 'Checkout', 'Payment', 'Success')
            ), 0
        ),
        2
    ) AS cart_abandonment_rate
FROM shopping_analysis;


-- Funnel drop_off_rate (Homepage -> Product Page -> Cart -> Checkout -> Payment -> Success)
WITH funnel AS (
    SELECT
        COUNT(*) FILTER (WHERE drop_off_stage = 'Home Page') AS home_drop,
        COUNT(*) FILTER (WHERE drop_off_stage = 'Product Page') AS product_drop,
        COUNT(*) FILTER (WHERE drop_off_stage = 'Cart') AS cart_drop,
        COUNT(*) FILTER (WHERE drop_off_stage = 'Checkout') AS checkout_drop,
        COUNT(*) FILTER (WHERE drop_off_stage = 'Payment') AS payment_drop,
        COUNT(*) FILTER (WHERE drop_off_stage = 'Success') AS purchases
    FROM shopping_analysis
)
SELECT
    'Home Page' AS stage,
    home_drop AS drop_off_sessions,
    home_drop + product_drop + cart_drop + checkout_drop + payment_drop + purchases AS sessions_reached_stage,
    ROUND(home_drop * 100.0 / NULLIF(home_drop + product_drop + cart_drop + checkout_drop + payment_drop + purchases, 0), 2) AS drop_off_rate
FROM funnel

UNION ALL

SELECT
    'Product Page',
    product_drop,
    product_drop + cart_drop + checkout_drop + payment_drop + purchases,
    ROUND(product_drop * 100.0 / NULLIF(product_drop + cart_drop + checkout_drop + payment_drop + purchases, 0), 2)
FROM funnel

UNION ALL

SELECT
    'Cart',
    cart_drop,
    cart_drop + checkout_drop + payment_drop + purchases,
    ROUND(cart_drop * 100.0 / NULLIF(cart_drop + checkout_drop + payment_drop + purchases, 0), 2)
FROM funnel

UNION ALL

SELECT
    'Checkout',
    checkout_drop,
    checkout_drop + payment_drop + purchases,
    ROUND(checkout_drop * 100.0 / NULLIF(checkout_drop + payment_drop + purchases, 0), 2)
FROM funnel

UNION ALL

SELECT
    'Payment',
    payment_drop,
    payment_drop + purchases,
    ROUND(payment_drop * 100.0 / NULLIF(payment_drop + purchases, 0), 2)
FROM funnel;


-- Checkout and Payment Abandonment
SELECT
    COUNT(*) FILTER (
        WHERE drop_off_stage IN ('Checkout', 'Payment')
    ) AS checkout_payment_abandonments,

    COUNT(*) FILTER (
        WHERE drop_off_stage IN ('Checkout', 'Payment', 'Success')
    ) AS sessions_reached_checkout,

    ROUND(
        COUNT(*) FILTER (
            WHERE drop_off_stage IN ('Checkout', 'Payment')
        ) * 100.0 /
        NULLIF(
            COUNT(*) FILTER (
                WHERE drop_off_stage IN ('Checkout', 'Payment', 'Success')
            ), 0
        ),
        2
    ) AS checkout_payment_abandonment_rate

FROM shopping_analysis;

-- Average Abandonment Rate 
SELECT
    ROUND(AVG(total_cart_value),2) AS average_cart_value
FROM shopping_analysis
WHERE drop_off_stage = 'Cart';


-- Revenue at risk
SELECT 
ROUND(SUM(total_cart_value),2) AS revenue_at_risk
FROM shopping_analysis
WHERE drop_off_stage = 'Cart';


-- Prime VS Non-Prime Gap Analysis
WITH membership_rates AS (
    SELECT
        prime_member_status,
        COUNT(*) AS total_sessions,
        COUNT(*) FILTER (
            WHERE drop_off_stage = 'Cart'
        ) AS abandoned_carts,
        COUNT(*) FILTER (
            WHERE drop_off_stage = 'Cart'
        ) * 100.0 / NULLIF(COUNT(*), 0) AS abandonment_rate
    FROM shopping_analysis
    WHERE prime_member_status IN ('Prime', 'Non-Prime')
    GROUP BY prime_member_status
)
SELECT
    ROUND(
        MAX(abandonment_rate) FILTER (
            WHERE prime_member_status = 'Non-Prime'
        )
        -
        MAX(abandonment_rate) FILTER (
            WHERE prime_member_status = 'Prime'
        ),
        2
    ) AS prime_vs_non_prime_gap_percentage_points
FROM membership_rates;


-- Average successful session duration by outcome.
SELECT
    ROUND(AVG(session_duration_mins), 2) AS avg_successful_session_duration
FROM shopping_analysis
WHERE drop_off_stage = 'Success';


-- Average Abandoned session duration by outcome
SELECT
    ROUND(AVG(session_duration_mins), 2) AS avg_abandoned_session_duration
FROM shopping_analysis
WHERE drop_off_stage  NOT IN ('Success', 'Unknown');


-- Difference in average session duration between successful and abandoned sessions
SELECT
    ROUND(AVG(session_duration_mins) FILTER (
        WHERE drop_off_stage = 'Success'
    ), 2) AS avg_successful_duration,

    ROUND(AVG(session_duration_mins) FILTER (
        WHERE drop_off_stage NOT IN ('Success','Unknown')
    ), 2) AS avg_abandoned_duration,

    ROUND(
        AVG(session_duration_mins) FILTER (
            WHERE drop_off_stage = 'Success'
        ) -
        AVG(session_duration_mins) FILTER (
            WHERE drop_off_stage NOT IN ('Success','Unknown')
        ), 2
    ) AS duration_difference
FROM shopping_analysis;


-- Customer Segmentation Analysis based on session outcomes
SELECT
    customer_segment,
    COUNT(*) AS total_sessions
FROM shopping_analysis
GROUP BY customer_segment
ORDER BY total_sessions DESC;