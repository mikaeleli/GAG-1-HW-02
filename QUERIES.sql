-- HW2
-- Student names: Mikael

-- A. 447 different members attended at least one class on January 10th. How many different members attended at least one class on January 15th?
-- Explanation: 
-- First we query for all IDs of classed held on January 15th. 
-- We then select the distinct members that attended these classes and count them.

select count(*)
from (
    select distinct A.mid
    from attends A
    where A.cid in (
        select C.id
        from class C
        where extract(month from C.date) = 1
        and extract(day from C.date) = 15
    )
) tmp;



-- B. 4 different class types require more than 20 light dumbbells. How many class types require more than 20 yoga mats?
-- Explanation: 
-- Here we need to join the type, needs and equipment tables. 
-- We then do a simple filter on the equipment name (yoga mat) and quantity (more than 20).

select count(*)
from (
    select *
    from type T
    join needs N on N.tid = T.id
    join equipment E on N.eid = E.id
    where N.quantity > 20
    and E.name ilike 'yoga mat'
) tmp;


-- C. Oh no! Some member hacked the database and is still attending classes but has quit according to the database. Write a query to reveal their name!
-- Explanation: 
-- Here we need to join the member, attends and class tables.
-- We apply a simple filter, checking to see if the member has attended any classes after his quit_date
-- We then select from the results distinct names to reveal the hacker's name

select distinct(M.name)
from member M
join attends A on A.mid = M.id
join class C on C.id = A.cid
where C.date > M.quit_date;


-- D. How many members have a personal trainer with the same first name as themselves, but have never attended a class that their personal trainer led?
-- Explanation:
-- Here we use a subquery to count the number of classes a member and an instructor have shared
-- We then join the member and instructor tables and filter the results so their first names are the same.

select count(*)
from (
    select *
    from member M
    join instructor I on I.id = M.iid
    where split_part(M.name, ' ', 1) = split_part(I.name, ' ', 1)
    and (
        select count(*)
        from class C
        join attends A on A.cid = C.id
        where C.iid = I.id
        and A.mid = M.id
    ) = 0
) tmp;

-- E. For every class type, return its name and whether it has an average rating higher or equal to 7, or lower than 7, in a column named "Rating" with values "Good" or "Bad", respectively.
-- Explanation: 
-- Here we join the type, class and attends tables.
-- We group by the type id so we can calculate the average rating for each group (class type).
-- We then use a case statement to check if the average rating is greater than or equal to 7 and return "Good" or "Bad" based on the result.

select T.name, case when avg(A.rating) >= 7 then 'Good' else 'Bad' end as Rating
from type T
join class C on C.tid = T.id
join attends A on A.cid = C.id
group by T.id;


-- F. Out of the members that have not quit, member with ID 6976 has been a customer for the shortest time. Out of the members that have not quit, return the ID of the member(s) that have been customer(s) for the longest time.
-- Explanation: 
-- Here we simply match the start_date of a member against a subquery that returns the earliest start_date for the whole member table.

select M.id
from member M
where M.start_date = (
    select min(start_date)
    from member
);



-- G. How many class types have at least one equipment that costs more than 100.000 and at least one other equipment that costs less than 5.000?
-- Explanation: 
-- Here we join the type, needs and equipment tables.
-- We group them by the type id so we get groups of the different equipment for each class type.
-- We then use a having clause to filter the results so that the max price of the group is greater than 100.000 and the min price of the group is less than 5.000.
-- Tada!

select count(*)
from (
    select T.id
    from type T
    join needs N on N.tid = T.id
    join equipment E on E.id = N.eid
    group by T.id
    having max(E.price) > 100000
    and min(E.price) < 5000
) tmp;


-- H. How many instructors have led a class in all gyms on the same day?
-- Explanation: 
-- Here we join the instructor table with the class table in a subquery to count the number of different gyms each instructor has taught at on the same day.
-- We then compare the number of gyms taught at by each instructor to the total number of gyms in the gym table.
-- There are no instructors in the given database that fit the criteria, so the result is 0 but you can uncomment the inserts below to test the query.

-- =========
-- TEST DATA
-- =====================================================
-- insert into class (id, iid, tid, gid, date, minutes)
-- values (5000, 1, 1, 0, '2024-01-01', 50);

-- insert into class (id, iid, tid, gid, date, minutes)
-- values (5001, 1, 1, 1, '2024-01-01', 50);

-- insert into class (id, iid, tid, gid, date, minutes)
-- values (5002, 1, 1, 2, '2024-01-01', 50);

-- insert into class (id, iid, tid, gid, date, minutes)
-- values (5003, 1, 1, 3, '2024-01-01', 50);

-- insert into class (id, iid, tid, gid, date, minutes)
-- values (5004, 1, 1, 4, '2024-01-01', 50);
-- =====================================================

select count(*)
from (
    select I.id, count(distinct C.gid) as num_gyms
    from instructor I
    join class C on C.iid = I.id
    group by I.id, C.date
) tmp
where num_gyms = (
    select count(*)
    from gym
);


-- I. How many instructors have not led classes of all different class types?
-- Explanation: 
-- Here we join the instructor and class tables in a subquery to count the number of different class types each instructor has taught.
-- We then compare the number of class types taught by each instructor to the total number of class types in the type table.

select count(*)
from (
    select I.id, count(distinct C.tid) as num_class_types_taught
    from instructor I
    left join class C on C.iid = I.id
    group by I.id
) tmp
where num_class_types_taught < (
    select count(*)
    from type
);


-- J. The class type "Circuit training" has the lowest equipment cost per member, based on full capacity. Return the name of the class type that has the highest equipment cost per person, based on full capacity.
-- Explanation: 
-- Here we create a view that contains the name and cost per member of each class type.
-- The view is so we can use the same subquery twice without having to repeat the code.
-- We can then select the name of the class type that has the highest cost per member.
-- Piazza link allowing usage of views to reuse queries: https://piazza.com/class/lr37tug59z65fe/post/71

drop view if exists ClassTypeEquipmentCostPerMember;
create view ClassTypeEquipmentCostPerMember
as
select T.name, (E.price * N.quantity) / T.capacity as cost_per_member
from class C
join type T on T.id = C.tid
join needs N on N.tid = T.id
join equipment E on E.id = N.eid;

select distinct name
from ClassTypeEquipmentCostPerMember
where cost_per_member = (
    select max(cost_per_member)
    from ClassTypeEquipmentCostPerMember
);


-- K (BONUS). The hacker revealed in query C has left a message for the database engineers. This message may save the database!
-- Return the 5th letter of all members that started the gym on December 24th of any year and have at least 3 different odd numbers in their phone number, in a descending order of their IDs,
-- followed by the 8th letter of all instructors that have not led any "Trampoline Burn" classes, in an ascending order of their IDs.
-- Explanation: 

-- select substring(M.name, 5, 1) as letter
-- from member M
-- where cast(M.start_date as varchar) like '%-12-24'
-- order by M.id desc;

-- -- Union

-- select substring(I.name, 8, 1) as letter
-- from instructor I
-- where I.id not in (
--     select C.iid
--     from class C
--     join type T on T.id = C.tid
--     where T.name ilike 'Trampoline Burn'
-- )
-- order by I.id asc;


