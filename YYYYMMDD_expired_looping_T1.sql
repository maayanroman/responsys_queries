/*
 Table 	 Symbolic Name 
 Data/customers 	 $A$ 
 Data/loan_status_logs 	 $B$ 
 Data/loans 	 $C$ 
 Data/credit_decisions 	 $D$ 
*/

SELECT DISTINCT c.riid_, 
                c.email_address_ 
FROM   (SELECT a.customer_id, 
               a.loan_id, 
               a.status_date, 
               First_value(cd.approved) 
                 OVER ( 
                   partition BY cd.customer_id 
                   ORDER BY cd.created_at DESC rows UNBOUNDED PRECEDING ) AS 
                      cd_approved_flg, 
               /* pull the latest approved flag from credit_decisions for each customer*/ 
               First_value(l.ac_id) 
                 OVER ( 
                   partition BY l.customer_id 
                   ORDER BY l.ac_id rows UNBOUNDED PRECEDING)             AS 
                      active_loan 
       /* if more than one active product per custoer simply selects the earleast by id*/ 
        FROM   (SELECT l.customer_id, 
                       l.ac_id 
                       AS 
                       loan_id, 
                       l.apr_percentage, 
                       l.status, 
                       First_value(ls.created_at) 
                         OVER ( 
                           partition BY ls.loan_id 
                           ORDER BY ls.created_at DESC rows UNBOUNDED PRECEDING 
                         ) AS 
                               status_date, 
                       /* pull the last loan status time stamp available for the loan*/ 
                       Row_number() 
                         OVER ( 
                           partition BY l.customer_id 
                           ORDER BY ls.created_at DESC) 
                       AS 
                       row_id 
/* assign row number based on the latest updated loan for the customer*/ 
                FROM   $c$ l 
                       JOIN $b$ ls 
                         ON ls.loan_id = l.ac_id)a 
               /* all customer loans with most recent status dates*/ 
               LEFT JOIN $c$ l 
                      ON a.customer_id = l.customer_id 
                         AND l.status IN ( 'applied', 'late', 'current', 
                                           'approved', 
                                           'paid_off' 
                                         ) 
               /* pull any active loans for the customer if they exist*/ 
               LEFT JOIN $d$ cd 
                      ON a.customer_id = cd.customer_id 
        WHERE  a.row_id = 1 
               AND a.status = 'cancelled' 
               AND Cast(a.apr_percentage AS DECIMAL(9, 4)) < 0.40 
               AND ( Mod(( ( Trunc(CURRENT_DATE) - Trunc( 
                             From_tz(Cast(a.status_date AS 
                                          TIMESTAMP), 
                                   'utc') 
                             ) 
                           ) - 160 ), 140) >= 1 
                     AND Mod(( ( Trunc(CURRENT_DATE) - Trunc( 
                                 From_tz(Cast(a.status_date 
                                              AS 
                                              TIMESTAMP), 
                                     'utc') 
                                                           ) 
                               ) - 160 ), 140) < 14 ) 
       /*If remainder of ((# of days since their app expired - 160) / 140) falls between [1,14), email sent.*/)b
       JOIN $a$ c 
         ON b.customer_id = c.ac_id 
WHERE  b.cd_approved_flg = 'true' 
       /* ensure that the customers most recent approval decision was positve*/ 
       AND b.active_loan IS NULL 
/* ensure that the customer does not have any currently active products*/ 
       AND c.riid_ IS NOT NULL 
