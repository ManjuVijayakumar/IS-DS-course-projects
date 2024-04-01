
-- IPL_matches

create table IPL_matches
(
id	 	integer,
city	varchar(150),
date	date,
player_of_match	varchar(150),	
venue	varchar(255),
neutral_venue	integer,
team1	varchar(255),
team2	varchar(255),
toss_winner	varchar(255),
toss_decision	varchar(50),
winner	varchar(255),
result	varchar(50),
result_margin	double precision,
eliminator	varchar(10),
method	varchar(10),
umpire1	varchar(150),
umpire2 varchar(150)
);


-- from csv file
copy IPL_matches
from 'C:\Program Files\PostgreSQL\16\data\Data\IPL_matches.csv' csv header;

select * from IPL_matches where id = 335982;

create table IPL_ball
(
id		integer,	
inning	integer,
over	integer,
ball	integer,
batsman	varchar(150), 
non_striker	 varchar(150),
bowler	varchar(150),
batsman_runs	integer,
extra_runs	integer,
total_runs	integer,
is_wicket	integer,
dismissal_kind	varchar(150), 
player_dismissed	varchar(150),
fielder	 varchar(150),
extras_type	varchar(150),
batting_team	varchar(250),
bowling_team varchar(250)
);

-- from csv file
copy IPL_ball
from 'C:\Program Files\PostgreSQL\16\data\Data\IPL_Ball.csv' csv header;

select * from IPL_ball limit 10;


-- #Task 1: Bidding on Batters
-- Aggressive Batsmen

-- total runs / no. of balls faced

select * from ipl_ball where extras_type <> 'wides' limit 10;
select distinct extras_type from ipl_ball;

select 'BB McCullum',count(ball),sum(total_runs) from ipl_ball where batsman = 'BB McCullum'
and extras_type <> 'wides';


select	a.batsman,
		a.no_of_balls_faced,
		a.total_no_of_runs,
		round((cast(a.total_no_of_runs as numeric) / cast(a.no_of_balls_faced as numeric)) * 100, 2) as strike_rate
from	(
		select 	batsman,
				count(ball) as no_of_balls_faced,
				sum(batsman_runs) as total_no_of_runs
		from 	IPL_ball 
		where 	extras_type <> 'wides'
		group by batsman
		) as a
where	a.no_of_balls_faced >= 500
order by strike_rate desc
limit 10;

/*
select *,(a.total_runs/a.total_balls)*100 as strike_rate
from (select batsman,sum(batsman_runs) as total_runs,
	 count(ball) as total_balls
	 from ipl_ball where extras_type <> 'wides' group by batsman ) as a
	where total_balls >= 500 order by strike_rate desc limit 10;
	*/

-- Anchor batsmen

-- total runs scores divided by number of time batsman has been dismissed 

select 	a.batsman,
		sum(a.batsman_runs) as total_runs,
		sum(case when a.is_wicket = 1 then 1 else 0 end) as dismissal_count,
		round(sum(cast(a.batsman_runs as numeric))/sum(case when a.is_wicket = 1 then 1 else 0 end), 2) as strike_rate
from 	ipl_ball as a
	left join ipl_matches as b
		on a.id = b.id
group by a.batsman
having sum(case when a.is_wicket = 1 then 1 else 0 end) > 0
 		and count( distinct extract(year from b.date)) > 2
order by strike_rate desc 
limit 10;

-- Hard hitters

-- have player more than 2 ipl seasons
-- have scored most runs in boundaries
-- runs in boundaries divided by total runs
-- batsman_runs considered since its run scored by batsman, not through extras


-- select	* from ipl_ball limit 10;
-- select max(batsman_runs) from ipl_ball;
-- select distinct extras_type from ipl_ball;


-- batsman_runs - 4 & 6 = boundaries

select 	a.batsman,
		sum(a.batsman_runs) as total_runs,
		sum(case when a.batsman_runs = 4 then 4
				else 0 end) as fours,
		sum(case when a.batsman_runs = 6 then 6
		   		else 0 end) as sixes,
		sum(case when a.batsman_runs = 4 then 4
				when a.batsman_runs = 6 then 6
			else 0 end) as runs_in_boundaries,
		round((sum(case when a.batsman_runs = 4 then 4
				when a.batsman_runs = 6 then 6
			else 0 end) / sum(cast (a.batsman_runs as numeric))) * 100, 2) as boundary_percentage
from 	ipl_ball as a
	left join ipl_matches as b
		on a.id = b.id
group by a.batsman
having count( distinct extract(year from b.date)) > 2
order by boundary_percentage desc 
limit 10;


-- Bidding on Bowlers

-- Economy bowlers

-- bowled atleast 500 balls in ipl so far
-- dividing total runs conceded with total overs bowled
-- no. of runs divided by no. of overs less runs..more economy

select	bowler,
		sum(total_runs) as runs_conceded,
		count(ball)/6 as no_of_overs,
		round(sum(cast(total_runs as numeric)) / (count(cast(ball as numeric))/6), 2) as economy_rate
from	ipl_ball
where	extras_type not in ('byes','legbyes','noballs','penalty','wides')
group by bowler
having count(ball) >= 500
order by economy_rate
limit 10;


-- Bowlers with best strike rate

-- bowled atleast 500 balls in ipl so far
-- number of balls bowled divided by total wickets taken

select	i.bowler,
		i.total_balls,
		i.total_wickets,
		round(cast(i.total_balls as numeric) / cast(i.total_wickets as numeric),2) as bowler_strike_rate
from
		(select	bowler,
				count(ball) as total_balls,
				sum(case when is_wicket = 1 then 1
						else 0 end) as total_wickets
		from	ipl_ball
		-- where	bowler = 'Z Khan'
		group by bowler
		having count(ball) >= 500 ) as i
order	by bowler_strike_rate
limit 10;

-- All Rounders

-- faced at least 500 balls
-- bowled minimum 300 balls
-- total number of runs divided by number of deliveries faced

select	batting.batsman,
		round(batting.strike_rate,2) as strike_rate,
		bowling.bowler,
		round(bowling.bowler_strike_rate,2) as bowling_strike_rate
from
(select 	batsman,
		(sum(cast(batsman_runs as numeric)) / count(ball)) * 100 as strike_rate
from 	IPL_ball as a 
where 	extras_type <> 'wides'
group by batsman
having count(ball) >= 500
order by strike_rate desc) as batting
join
(select	bowler,
		count(ball) / cast(sum(case when is_wicket = 1 then 1
						else 0 end) as numeric) as bowler_strike_rate
from	IPL_ball as b
group by bowler
having count(ball) >= 300
order by bowler_strike_rate asc) as bowling
	on		batting.batsman	= bowling.bowler
-- order by batting.strike_rate desc, bowling.bowler_strike_rate
limit 10;

-- Wicketkeeper

/*
A good wicketkeeper does not allow many byes
Should have a minimum of 100 dismissals
Player with a good batting average
A keeper should be flexible in his game and should know how to bat in different situations at different positions
Person who is required to encourage the team in every situation
A wicket keeper should be mentally strong and physically fit

fielders while dismissal_kind - caught, run out & stumped
*/

select 	fielder,
		count(fielder) as no_of_times
from	ipl_ball
where	dismissal_kind in ('caught','run out','stumped')
and		fielder != 'NA'
group by fielder
order by no_of_times desc
limit 5;

select * from ipl_ball where	dismissal_kind in ('caught','run out','stumped');

-- Additional Questions for Final Assessment

create table deliveries
as
select * from IPL_Ball;
-- 193468

create table matches
as
select * from IPL_Matches;
-- 816

-- 1. Get the count of cities that have hosted an IPL match

select  'IPL hosted in ' || count(distinct city) || ' cities' as Host_count
from	ipl_matches;

select	city,
		count(city) as no_of_times_city_hosted
from	ipl_matches
group by city
order by no_of_times_city_hosted desc;

select * from matches where city = 'NA';

-- 2 Table deliveries_v02


create table deliveries_v02
as
select 	*,
		case when total_runs >= 4 then 'boundary'
			 when total_runs = 0 then 'dot'
			 else 'other' end as ball_result
from ipl_ball;

-- 3.Write a query to fetch total number of boundaries and dot balls from deliveries_v02

select 	ball_result,
		count(ball_result) as total_count
from	deliveries_v02
where	ball_result in ('boundary', 'dot')
group by ball_result;

-- 4.Write a query to fetch total number of boundaries scored by each team from the deliveries_v02 table
-- and order it in descending order of the number of boundaries scored

select	batting_team,
		count(total_runs) as total_no_of_boundaries
from	deliveries_v02
where	ball_result = 'boundary'
group by batting_team
order by total_no_of_boundaries desc;

-- 5. Write a query to fetch the total number of dot balls bowled by each team and order it in descending order
-- of the total number of dot balls bowled.

select	bowling_team,
		count(total_runs) as total_no_of_dot_balls
from	deliveries_v02
where	ball_result	= 'dot'
group by bowling_team
order by total_no_of_dot_balls desc;


-- 6. Write a query to fetch the total number of dismissals by dismissal kinds where dismissal kind is not NA

select	dismissal_kind,
		count(dismissal_kind) as dismissal_count
from	deliveries_v02
where	dismissal_kind != 'NA'
group by dismissal_kind
order by dismissal_count;

-- 7. Write a query to get the top 5 bowlers who conceded maximum extra runs from the deliveries table

select	bowler,
		sum(extra_runs) as extra_runs_total
from	deliveries
group by bowler
order by extra_runs_total desc
limit 5;

-- 8. Write a query to create a table named deliveries_v03 with all the columns of deliveries_v02 and two
-- additional column (named venue and match_date) of venue and date from table matches



create table deliveries_v03
as
select	del.*,
		mat.venue as venue,
		mat.date as match_date
from	deliveries_v02 as del
join	matches as mat
	on del.id	= mat.id;

-- 193468

-- 9.Write a query to fetch the total runs scored for each venue and order it in descending order of total runs
-- scored

select	venue,
		sum(total_runs) as total_runs
from	deliveries_v03
group by venue
order by total_runs desc;


-- 10.Write a query to fetch the year-wise total runs scored at Eden Gardens and order it in the descending order
-- of total runs scored

select	extract(year from match_date) as match_year,
		sum(total_runs) as total_runs
from	deliveries_v03
where	venue	= 'Eden Gardens'
group by match_year
order by total_runs desc;

select * from deliveries_v03 limit 10;








		





