-- Violation dimension for restaurant health inspections
WITH all_violations AS (
   SELECT DISTINCT
       violation_code,
       violation_description AS violation_desc,
       CASE 
           WHEN UPPER(TRIM(critical_flag)) = 'Y' THEN TRUE 
           ELSE FALSE 
       END AS is_critical
   FROM {{ ref('stg_restaurant_inspections') }}
   WHERE violation_code IS NOT NULL
),

violation_dimension AS (
   SELECT
       {{ dbt_utils.generate_surrogate_key([
           'violation_code', 
           'violation_desc',
           'is_critical'
       ]) }} AS violation_key,
       
       violation_code,
       violation_desc,
       is_critical
   FROM all_violations
)

SELECT 
    violation_key,
    violation_code,
    violation_desc,
    is_critical
FROM violation_dimension