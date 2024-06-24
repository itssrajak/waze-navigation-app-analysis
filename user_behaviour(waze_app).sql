USE dataset;

-- 1. Top 5 Users by Total Sessions
SELECT ID, total_sessions
FROM waze_app_dataset
ORDER BY total_sessions DESC
LIMIT 5;

-- 2. Users Retained vs Churned
SELECT label, COUNT(*) AS user_count
FROM waze_app_dataset
GROUP BY 1;

-- 3.Users with Most Navigations to favorite 1 location
SELECT ID, total_navigations_fav1
FROM waze_app_dataset
ORDER BY 2 DESC
LIMIT 10;

-- 4. Average Driven Kilometers and Duration by Device
SELECT device, 
       CEIL(AVG(driven_km_drives)) AS avg_driven_km, 
       CEIL(AVG(duration_minutes_drives))AS avg_duration_minutes
FROM waze_app_dataset
GROUP BY device;

-- 5. Total Distance Driven by Device Type
SELECT device, SUM(driven_km_drives) AS total_driven_km
FROM waze_app_dataset
GROUP BY device;

-- 6 Average Number of Drives by Retention Status
SELECT label, AVG(drives) AS avg_drives
FROM waze_app_dataset
GROUP BY label;

-- 7.User Engagement Score
WITH user_metrics AS (
	SELECT 
		ID,
		AVG(sessions) AS avg_sessions,
		AVG(driven_km_drives) AS avg_driven_km,
		AVG(duration_minutes_drives) AS avg_duration_minutes
	FROM waze_app_dataset
	GROUP BY ID
),
engagement_score AS (
	SELECT 
		ID,
        (avg_sessions * 0.4) + (avg_driven_km * 0.3) + (avg_duration_minutes * 0.3) as score
	From user_metrics
)
SELECT ID, score
FROM engagement_score
ORDER BY 2 DESC;


-- 8 User Lifetime Value (LTV)
WITH user_ltv AS (
    SELECT
        ID,
        SUM(sessions) AS total_sessions,
        SUM(drives) AS total_drives,
        SUM(driven_km_drives) AS total_driven_km,
        (SUM(sessions) * 0.5) + (SUM(drives) * 0.3) + (SUM(driven_km_drives) * 0.2) AS ltv
    FROM waze_app_dataset
    GROUP BY ID
)
SELECT
    ID,
    ltv
FROM user_ltv
ORDER BY ltv DESC;

-- 9. Monthly Active Users Over Time
WITH active_users AS (
    SELECT
        ID,
        DATE_ADD('1970-01-01', INTERVAL n_days_after_onboarding DAY) AS activity_date
    FROM waze_app_dataset
),
monthly_activity AS (
    SELECT
        ID,
        DATE_FORMAT(activity_date, '%Y-%m') AS month
    FROM active_users
    GROUP BY ID, DATE_FORMAT(activity_date, '%Y-%m')
)
SELECT
    month,
    COUNT(DISTINCT ID) AS monthly_active_users
FROM monthly_activity
GROUP BY month
ORDER BY month;



 -- 10. Top 5 Retained Users by Total Sessions with Detailed Insights
 -- Step 1: Filter retained users
WITH retained_users AS (
    SELECT *
    FROM waze_app_dataset
    WHERE label = 'retained'
),

-- Step 2: Rank users by total sessions
ranked_users AS (
    SELECT
        ID,
        total_sessions,
        sessions,
        drives,
        total_navigations_fav1,
        driven_km_drives,
        duration_minutes_drives,
        activity_days,
        driving_days,
        device,
        RANK() OVER (ORDER BY total_sessions DESC) AS user_rank
    FROM retained_users
)

-- Step 3: Select top 5 users with detailed insights
SELECT
    ID,
    total_sessions,
    sessions,
    drives,
    total_navigations_fav1,
    driven_km_drives,
    duration_minutes_drives,
    activity_days,
    driving_days,
    device
FROM ranked_users
WHERE user_rank <= 5
ORDER BY user_rank;

-- 11. User Rank Based on Average Drive Distance 
WITH user_drive_distances AS (
    SELECT
        ID,
        AVG(driven_km_drives) AS avg_drive_distance
    FROM waze_app_dataset
    GROUP BY ID
)
SELECT
    ID,
    avg_drive_distance,
    RANK() OVER (ORDER BY avg_drive_distance DESC) AS distance_rank
FROM user_drive_distances
ORDER BY distance_rank;

-- 12. Average Duration of Drives per Session Category
WITH session_categories AS (
    SELECT
        ID,
        CASE
            WHEN sessions > 200 THEN 'High'
            WHEN sessions BETWEEN 100 AND 200 THEN 'Medium'
            ELSE 'Low'
        END AS session_category,
        duration_minutes_drives
    FROM waze_app_dataset
)
SELECT
    session_category,
    AVG(duration_minutes_drives) AS avg_drive_duration
FROM session_categories
GROUP BY session_category
ORDER BY avg_drive_duration DESC;


-- 13.  User Retention Rate by Device
WITH retention_rate AS (
    SELECT
        device,
        label,
        COUNT(*) AS user_count
    FROM waze_app_dataset
    GROUP BY device, label
),
device_totals AS (
    SELECT
        device,
        SUM(user_count) AS total_users
    FROM retention_rate
    GROUP BY device
)
SELECT
    r.device,
    r.label,
    r.user_count,
    (r.user_count / d.total_users) * 100 AS retention_rate
FROM retention_rate r
JOIN device_totals d ON r.device = d.device
WHERE r.label = 'retained'
ORDER BY retention_rate DESC;

-- 14.  Number of Drives Initiated from Favorite Locations
WITH drives_from_fav AS (
    SELECT
        ID,
        total_navigations_fav1 + total_navigations_fav2 AS total_fav_drives
    FROM waze_app_dataset
)
SELECT
    ID,
    total_fav_drives,
    RANK() OVER (ORDER BY total_fav_drives DESC) AS drive_rank
FROM drives_from_fav
ORDER BY drive_rank;

