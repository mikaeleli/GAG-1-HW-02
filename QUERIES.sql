-- HW2
-- Student names: Mikael, Hafsteinn, Ari

-- A. 447 different members attended at least one class on January 10th. How many different members attended at least one class on January 15th?
-- Explanation: 
-- Here we use a subquery to get the IDs of classes held on January 15th using the extract method to get the month and day from the date column.
-- We can then use the class IDs to get the member IDs that attended these classes and count them.
-- We need to use the distinct keyword to only count each member once since the same member can attend multiple classes on the same day.

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
-- Here we need to join the type table (since we want to count the class types) with the needs table (since we want to count the quantity of equipment needed)
-- and the equipment table (since we want to filter the equipment by name).
-- We use a where clause to filter the results to only include equipment with the name "yoga mat" and a quantity greater than 20.
-- We then count the results, tada!

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
-- We need the member table, since it has information on the member's name and quit date.
-- We also need the class table, since it has information on the date of the classes.
-- We need the attends table since it connects together the class and member tables.
-- Using a where clause, we can filter the results to only include members that have attended classes after their quit date.
-- The results can include the same name multiple times if the member has attended multiple classes after their quit date, 
-- so we use the distinct keyword to only include each name once.

select distinct(M.name)
from member M
join attends A on A.mid = M.id
join class C on C.id = A.cid
where C.date > M.quit_date;


-- D. How many members have a personal trainer with the same first name as themselves, but have never attended a class that their personal trainer led?
-- Explanation:
-- Here we use a subquery to count the number of classes a member and an instructor have shared.
-- If the count equals 0, then we know the member has never attended a class that their personal trainer led.
-- We then join the member and instructor tables and compare their first names using the split_part function.
-- If the first names match and the subquery count equals 0, we count the member in the result.

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
-- We need to use the type table since we want to return the name of the class type.
-- We also need the attends table since it contains the ratings for each class.
-- We aaaaalso need the class table so we can join the type and attends tables together.
-- To get the "Good" or "Bad" rating, we need to use a case statement.
-- If the rating is greater than or equal to 7, we return "Good", otherwise we return "Bad".
-- We group by the type id so we can calculate the average rating for each group (class type).

select T.name, case when avg(A.rating) >= 7 then 'Good' else 'Bad' end as Rating
from type T
join class C on C.tid = T.id
join attends A on A.cid = C.id
group by T.id;


-- F. Out of the members that have not quit, member with ID 6976 has been a customer for the shortest time. Out of the members that have not quit, return the ID of the member(s) that have been customer(s) for the longest time.
-- Explanation: 
-- We need to use the member table to get the start_date of each member.
-- We then use the member table again in a subquery to get the earliest start_date of all members.
-- If the member's start_date equals the earliest start_date of the member table, we count the member in the result.

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
-- If the group meets both conditions i.e. having equipment both more expensive than 100.000 and less expensive than 5.000, we count it in the result.

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
-- Here we left join the instructor and class tables in a subquery to count the number of different class types each instructor has taught.
-- Left joining the tables is necessary so we can include instructors that have not taught any classes in the result.
-- We then compare the number of class types taught by each instructor to the total number of class types in the type table.
-- If the number of class types taught by an instructor is less than the total number of class types, we count the instructor in the result.

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
-- Starting from the innermost subquery we select the Type table joining the needs table on type id and the equipment table on equipment id, we group by type and use the sum aggreate function to sum
-- cost per person for the class type ( Needs.Quantity * Equipment.Price / ClassType.Capacity), this select is then wrapped in a select max(*) to get the highest value of cost per person
-- finally this is wrapped in another query which is almost identical to the innermost query except it selects Type Name, HAVING cos per person equal to the max value given by the two subqueries

select T.Name
from type T
join needs N
    on N.TID = T.ID
join Equipment E
    on E.ID = N.EID
group by T.ID
having sum(N.quantity * E.price / T.capacity) = (
    select max(priceper)
    from (
        select sum(N.quantity * E.price / T.capacity) as priceper
        from type T
        join needs N
            on N.TID = T.ID
        join equipment E
            on E.ID = N.EID
        group by T.ID
    ) tmp
);


-- K (BONUS). The hacker revealed in query C has left a message for the database engineers. This message may save the database!
-- Return the 5th letter of all members that started the gym on December 24th of any year and have at least 3 different odd numbers in their phone number, in a descending order of their IDs,
-- followed by the 8th letter of all instructors that have not led any "Trampoline Burn" classes, in an ascending order of their IDs.
-- Explanation: 
-- 

select string_agg(Character, '')
from (
    select *
    from (
        select substring(M.Name, 5, 1) as Character
        from Member M
        where extract(month from M.start_date) = 12 and extract(day from M.start_date) = 24
        and M.ID in (
            select M.ID
            from (
                select M.ID, count(distinct M.Digit)
                from (
                    select M.ID, unnest(string_to_array(cast(M.Phone as varchar), null)) as Digit
                    from Member M
                ) as M
                where cast(Digit as integer) % 2 != 0
                group by M.ID
            ) as M
            where M.Count >= 3
        )
        order by M.ID desc
    ) tmp
    union all
    select *
    from (
        select substring(I.Name, 8, 1) as Character
        from Instructor I
        where I.ID not in (
            select distinct I.ID
            from Instructor I
            join Class C
                on C.IID = I.ID
            join Type T
                on T.ID = C.TID
            where T.Name ILIKE '%Trampoline Burn%'
        )
        order by I.ID asc
    ) tmp
) tmp;
