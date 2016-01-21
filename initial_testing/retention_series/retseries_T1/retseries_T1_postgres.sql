/* 
Primary developer: Maayan Roman
Criteria: 
 - Customers whose most recently paid off loan was paid off 5 days ago
 - Exclude customers with active products
 - Exclude customers who were already declined
*/

select c.email

from customers c
/* take the most recently created, paid_off loan as a proxy for most recently paid-off loan */
inner join loans l on l.id = (
  select id
  from loans
  where customer_id = c.id
  and status = 'paid_off'
  order by created_at desc limit 1)
/* join loan_tasks to get the pay-off date of the loan*/
inner join loan_tasks lt on lt.id = (
  select id
  from loan_tasks
  where loan_id = l.id
  and type = 'take_payment'
  and status = 'completed'
  order by eff_date desc limit 1)
/* take the most recently created credit_decision to check whether they were declined*/
left join credit_decisions cd on cd.id = (
  select id
  from credit_decisions
  where customer_id = c.id
  order by created_at desc limit 1)
 /* arbitrary change note */
where cd.approved is true
/* exclude any customers with active products or active loan applications */
and not exists (
  select 1
  from loans
  where status in ('current','applied','approved','late','charged_off')
  and customer_id = c.id)
