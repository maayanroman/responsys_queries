/*
Developed by: Maayan ROman
Developed on: 12/8/2015

Criteria:
 - paid off customers
 - no active products
 - paid off yesterday
 - not yet declined

Postgres Version:
select c.email
from loans l
inner join customers c on c.id = l.customer_id
inner join loan_tasks lt on lt.id = (
  select id
  from loan_tasks
  where loan_id = l.id
  and type = 'take_payment'
  and status = 'completed'
  order by eff_date desc limit 1)
and left join credit_decisions cd on cd.id = (
  select id
  from credit_decisions
  where customer_id = l.customer_Id
  order by created_at desc limit 1)
where l.status = 'paid_off'
and lt.eff_date = tzcorrect(current_date) - interval '1 day'
and not exists (
  select 1
  from loans
  where customer_id = l.customer_id
  and status in ('current','late','approved','charged_off'))
and cd.approved is true

Aliases:
$A$ = customers
$B$ = loans
$C$ = loan_tasks
$D$ = credit_decisions
*/

select 
c.email_address_, c.riid_
from $B$ l
inner join $A$ c on c.ac_id = l.customer_id
inner join (
  select $C$.loan_id, Row_number () over (
    partition by $C$.loan_id
    order by $C$.eff_date desc)
  from $C$
  where $C$.status = 'completed'
  and $C$.type = 'take_payment'
  ) lt on lt.loan_id = l.ac_id and lt.row_num = 1
