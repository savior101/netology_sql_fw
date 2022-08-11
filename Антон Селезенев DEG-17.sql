set search_path to bookings;


-- 1. В каких городах больше одного аэропорта?

/* Производим группировку по названию города из airports с подсчетом количества строк в группе,
 * затем выводим все строки, где это количество строк больше 1.
 */
--explain analyze -- cost = 5, avg time = 0.149ms
select
	city "Город"
	, count(*) "Количество аэропортов"
from airports
group by city
having count(*) > 1;

---------------------
/* Вывод:
 * 
 * Ульяновск	2
 * Москва		3
 * 
 * Итого: 2 строки
 */ 


-- 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
-- Обязательно применение подзапроса.

/* Первым подзапросом выясняем максимальную дальность полета, вторым - aircraft_code самолета с 
 * максимальной дальностью полета, фильтруем соединенные таблицы airports и flights по полученному aircraft_code,
 * после чего группируем по аэропорту отправления, из которых (в которые) существуют рейсы такого самолета.
 * Группировка по имени аэропорта и городу необходима, чтобы вывести их в select.
 */
--explain analyze -- cost = 896, avg time = 6.309ms
select
	f.departure_airport "Код аэропорта"
	, a.airport_name "Название аэропорта"
	, a.city "Город"
from airports a
join flights f on f.departure_airport = a.airport_code
where aircraft_code = (
	select a.aircraft_code 
	from aircrafts a
	where a."range" = (
		select max(range)
		from aircrafts
	)
)
group by
	f.departure_airport
	, a.airport_name
	, a.city;

---------------------
/* Вывод:
 * 
 * VKO	Внуково		Москва
 * OVB	Толмачёво	Новосибирск
 * DME	Домодедово	Москва
 * SVX	Кольцово	Екатеринбург
 * SVO	Шереметьево	Москва
 * AER	Сочи		Сочи
 * PEE	Пермь		Пермь
 * 
 * Итого: 7 строк
 */

/* P.S. через представление flights_v получается примерно такой же по стоимости запрос, но все равно чуть дороже.
*/ 
 
 
-- 3. Вывести 10 рейсов с максимальным временем задержки вылета
-- Обязательно применение оператора LIMIT

/* Считаем задержку времени вылета для каждого рейса, который совершил вылет,
 * сортируем в порядке убывания задержки и ограничиваем 10 записями.
 */
--explain analyze -- cost = 1212, avg time = 19.710ms
select
	f.flight_id "ID рейса"
	, f.flight_no "№ рейса"
	, f.actual_departure::timestamp - f.scheduled_departure::timestamp "Задержка вылета"
from flights f
where f.actual_departure is not null
order by f.actual_departure::timestamp - f.scheduled_departure::timestamp desc
limit 10;

---------------------
/* Вывод:
 * 
 * 14750	PG0589	04:37:00
 * 1408		PG0164	04:28:00
 * 24253	PG0364	04:27:00
 * 22778	PG0568	04:20:00
 * 2852		PG0454	04:18:00
 * 21684	PG0096	04:18:00
 * 11426	PG0166	04:16:00
 * 9891		PG0278	04:16:00
 * 13645	PG0564	04:14:00
 * 4781		PG0669	04:08:00
 * 
 * Итого: 10 строк
 */

/* P.S. через CTE получается точно такой же результат, с такой же стоимостью;
 * row_number по окну дает выше стоимость, выдает другой результат, т.к. нумерует в другом порядке;
 * через представление flights_v тоже получается дороже.
 */ 


-- 4. Были ли брони, по которым не были получены посадочные талоны?
-- Выбрать верный тип JOIN

/* После бронирования пассажир покупает билет, затем после прохождения регистрации получает пасадочный талон.
 * Следовательно, для извелечения необходимых данных надо объединить все записи бронирования с билетами
 * и пасадочными талонами, исключив всех, кто произвел бронь, но еще не купил билет и не получил
 * посадочный талон (в нашем случае все, кто произвел бронь, билет купил).
 */
--explain analyze -- cost = 35570, avg time = 1703.617ms
select count(distinct b.book_ref) "Кол-во броней"
	from bookings b
	left join tickets t on t.book_ref = b.book_ref
	left join boarding_passes bp on bp.ticket_no = t.ticket_no
where t.ticket_no is null or bp.boarding_no is null;

---------------------
/* Вывод:
 * 
 * 91388
 * 
 * Итого: 1 строка
 */


-- 5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого 
-- аэропорта на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже 
-- вылетело из данного аэропорта на этом или более ранних рейсах в течение дня.
-- Обязательно использование оконной функции и подзапросов или/и CTE

/*
 * Разделяем на 2 логики, раскидываем по CTE:
 * 1. Считаем количество занятых мест (выданных пасадочных билетов, при которых самолет вылетел из аэропрта) 
 * на каждый полет с привязкой к самолету. Также нам нужны aircaft_code для с соединения с seats и flight_id
 * для соединения со второй логикой.
 * 2. Считаем в окне количество вылетевших пассажиров (выданных пасадочных билетов, при которых самолет вылетел 
 * из аэропррта) на каждый аэропорт с накоплением внутри дня для каждого flight_id. Для этого нужна группировка по аэропорту,
 * дню вылета и сортировка внутри дня по времени вылета в порядке возрастания. Также нам нужен flight_id для соединения
 * с первой логикой.
 * В основном запросе извлекаем данные из 1 логики, считаем процентное отношение свободных мест в самолете на каждый полет 
 * к общему числу мест в самолете. Для этого нужно соединить с таблицей seats по коду самолета.
 * Соединяем подзапрос со второй логикой по flight_id и выводим необходимую информацию.
 */
--explain analyze -- cost = 76524, avg time = 3206.128ms
with bs_t as
(
	select 
		f.flight_id
		, count(f.flight_id) bs
		, f.aircraft_code
	from flights f
	join boarding_passes bp on bp.flight_id = f.flight_id 
	where f.actual_departure is not null
	group by f.flight_id
),
ac_t as
(
	select
		distinct
		f.flight_id
		, count(f.flight_id) over (partition by f.departure_airport, f.actual_departure::date order by f.actual_departure) accum
	from flights f 
	join boarding_passes bp on bp.flight_id = f.flight_id
	where f.actual_departure is not null
)
select 
	perc_t.flight_id
	, perc_t.frs "Свободных мест, %"
	, ac_t.accum "Пассажиров вылетело из аэропорта"
from (
	select 
		bs_t.flight_id
		, (count(s.seat_no) - bs_t.bs) * 100 / count(s.seat_no) frs
	from seats s 
	join bs_t on bs_t.aircraft_code = s.aircraft_code
	group by
		bs_t.flight_id
		, bs_t.bs
	) perc_t
join ac_t on ac_t.flight_id = perc_t.flight_id

---------------------
/* Вывод:
 * 
 * 1	53	173
 * 2	40	2635
 * 3	42	229
 * 17	40	2608
 * 18	43	312
 * 21	50	153
 * 22	99	1517
 * 25	32	2513
 * 26	47	1597
 * 27	45	2739
 * .............
 * 
 * Итого: 11 478 строк
 */
 

-- 6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.
-- Обязательно использование подзапроса или оконной функции, оператора ROUND 

/*
 * Находим количество полетов каждого самолета, сгруппировав записи flights по aircraft_code,
 * находим количество всех полетов, вычисляем процентное отношение полетов каждого самолета
 * к общему количеству полетов: предварительно преобразовываем результаты в numeric, окргуляем до 3х знаков
 * после запятой и умножаем на 100, чтобы получить %.
 */
--explain analyze -- cost = 2192, avg time = 42.269ms
select 
	f.aircraft_code
	, count(f.flight_id) "Кол-во полетов самолета"
	, round((count(f.flight_id) * 1. / t.allf * 1.), 3) * 100 "Отношение к общему числу полетов, %"
from flights f, 
	(select count(flight_id) allf from flights) t
group by
	f.aircraft_code
	, t.allf

---------------------
/* Вывод:
 * 
 * SU9	8504	25.7
 * 319	1239	3.7
 * 763	1221	3.7
 * 773	610		1.8
 * 321	1952	5.9
 * CN1	9273	28.0
 * 733	1274	3.8
 * CR2	9048	27.3
 * 
 * Итого: 8 строк
 * 
 * 25.7% + 3.7% + 3.7% + 1.8% + 5.9% + 28.0% + 3.8% + 27.3% = 99.9%
 */

/*
 * P.S. самолет 320	Airbus A320-200 не совершал полеты, поэтому не попадает в запрос
 */


-- 7. Были ли города, в которые можно добраться бизнес-классом дешевле, чем эконом-классом в рамках перелета?
-- Обязательно использование CTE

/*
 * Разбиваем логику по CTE:
 * 1. Находим каждую уникальную стоимость билета по классу внутри полета. Сразу ограничим выборку только бизнес и
 * эконом-классами (даст уменьшение стоимости запроса примерно на 3%).
 * 2. Находим минимальную стоимость билета в бизнес-классе каждого полета.
 * 3. Находим максимальную стоимость билета в эконом-классе каждого полета.
 * Соединяем данные 2 и 3 логики по flight_id при условии, что минимальная стоимость билета бизнес-класса будет ниже
 * максимальной стоимости билета эконом-класса.
 * Через таблицу flights получаем данные по городу прибытия для таких рейсов.
 */

--explain analyze -- cost = 95079, avg time = 1018.338ms
with allp as (
	select 
		flight_id
		, fare_conditions
		, amount 
	from ticket_flights
	where fare_conditions = 'Business' or fare_conditions = 'Economy'
	group by
		flight_id
		, fare_conditions
		, amount
),
mnb as (
	select
		flight_id
		, min(amount) mn
		from allp
		where fare_conditions = 'Business'
		group by flight_id 
),
mxe as (
	select
		flight_id
		, max(amount) mx
		from allp
		where fare_conditions = 'Economy'
		group by flight_id 
)
select
	mnb.flight_id
	, a.airport_code "Аэропорт прибытия" 
	, a.city "Город прибытия" 
from mnb
join mxe on mxe.flight_id = mnb.flight_id
join flights f on f.flight_id = mxe.flight_id
join airports a on a.airport_code = f.arrival_airport 
where mnb.mn < mxe.mx

---------------------
/* Вывод:
 * 
 * Итого: 0 строк
 */


-- 8. Между какими городами нет прямых рейсов?
-- Обязательно использование декартового произведения в предложении FROM; создание представлений; использование EXCEPT.

/*
 * В первом представлении создаем запрос на вывод всех уникальных возможных комбинаций аэропортов с привязкой к городу.
 * Для этого производим декартово произведение таблицы airports самой с собой, а условием выбираем уникальные значения.
 * Во втором представлении создаем запрос на вывод всех уникальных комбинаций аэропортов, между которыми производятся
 * перелеты, с привязкой к городам.
 * В основном запросе из всех возможных комбинаций вычитаем те, которые существуют фактически и извлекаем
 * уникальные значения городов - это те комбинации городов, между которыми отсутствуют перелеты, а значит нет прямых рейсов.
 */

create view all_combs_airports as
	select
		a1.airport_code aa1
		, a1.city ac1
		, a2.airport_code aa2
		, a2.city ac2
	from
		airports a1
		, airports a2
	where a1.airport_code < a2.airport_code

create view all_combs_airports_flights as
	select
		f.departure_airport aa1
		, a1.city ac1
		, f.arrival_airport aa2
		, a2.city ac2
	from flights f
	join airports a1 on a1.airport_code = f.departure_airport
	join airports a2 on a2.airport_code = f.arrival_airport 
	where f.departure_airport < f.arrival_airport 
	group by
		f.departure_airport
		, f.arrival_airport
		, a1.city
		, a2.city

--explain analyze -- cost = 1779.26, avg time = 71.709ms
select
	distinct
	ac1 "Город 1"
	, ac2 "Город 2"
from (
	select *
	from all_combs_airports
	except
	select *
	from all_combs_airports_flights
) comb
order by 1, 2

---------------------
/* Вывод:
 * 
 * Абакан	Анадырь
 * Абакан	Астрахань
 * Абакан	Барнаул
 * Абакан	Белгород
 * Абакан	Белоярский
 * Абакан	Благовещенск
 * Абакан	Братск
 * Абакан	Брянск
 * Абакан	Бугульма
 * Абакан	Владивосток
 * .............
 * 
 * Итого: 4904 строк
 */


-- 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной 
-- дальностью перелетов  в самолетах, обслуживающих эти рейсы.
-- Обязательно использование оператора RADIANS или SIND/COSD; использование CASE

/*
 * В подзапросе находим все фактические уникальные маршруты между городами (по аналогии с частью из предыдущего задания),
 * обогощаем данными о координатах аэропортов, кодом самолета, который летает по данному маршруту и
 * максимальной дальностью полета самолета. Т.к. тригонометрические функции принимают на вход данные в
 * радианах, заранее переводим координаты из градусов в радианы.
 * В основном запросе выводим данные из подзапроса, считаем расстояние между аэропортами по формуле кратчайшего
 * расстояния между точками на земной повехности с использованием среднего радиуса Земли, а также
 * сравниваем максимальную дальность полета самолета и расстоянием между аэропортами.
 */
--explain analyze -- cost = 2409.24, avg time = 66.045ms
select
	t.aa1 "Аэропорт 1"
	, t.ac1 "Город 1"
	, t.aa2 "Аэропорт 2"
	, t.ac2 "Город 2"
	, t.aircraft_code "Код самолета"
	, t.rng "Макс. дальность полета, км"
	, round(acos(sin(t.lta) * sin(t.ltb) + cos(lta) * cos(ltb) * cos(lga - lgb)) * 6371) "Расст. м/у аэропортами, км"
	, case
		when t.rng > round(acos(sin(t.lta) * sin(t.ltb) + cos(lta) * cos(ltb) * cos(lga - lgb)) * 6371) then 'Да'
		else 'Нет'
	end "Самолет долетит?"
from 
(	
	select
	distinct
		f.departure_airport aa1
		, a1.city ac1
		, radians(a1.latitude) lta
		, radians(a1.longitude) lga 
		, f.arrival_airport aa2
		, a2.city ac2
		, radians(a2.latitude) ltb
		, radians(a2.longitude) lgb
		, f.aircraft_code
		, a."range" rng
	from flights f
	join airports a1 on a1.airport_code = f.departure_airport
	join airports a2 on a2.airport_code = f.arrival_airport
	join aircrafts a on a.aircraft_code = f.aircraft_code 
	where f.departure_airport < f.arrival_airport 
) t

---------------------
/* Вывод:
 * 
 * JOK	Йошкар-Ола		VKO	Москва				CN1	1200	670		Да
 * OMS	Омск			SVO	Москва				SU9	3000	2240	Да
 * DME	Москва			JOK	Йошкар-Ола			CN1	1200	637		Да
 * SGC	Сургут			UIK	Усть-Илимск			CR2	2700	1658	Да
 * OMS	Омск			VKT	Воркута				CR2	2700	1475	Да
 * DME	Москва			MRV	Минеральные Воды	733	4200	1297	Да
 * STW	Ставрополь		SVO	Москва				CR2	2700	1252	Да
 * AER	Сочи			SVO	Москва				773	11100	1404	Да
 * PES	Петрозаводск	TJM	Тюмень				CR2	2700	1813	Да
 * SLY	Салехард		VKO	Москва				CR2	2700	1965	Да
 * .............
 * 
 * Итого: 309 строк
 */









 
 