
## Проектная работа по модулю "SQL и получение данных"
#### Нетология, курс "Дата-инженер с нуля до middle"
#### Селезенев Антон, группа DEG-17

Задание на выполнение работ в файле _"ТЗ. Итоговая работа по модулю "SQL"_.

**Инструменты:** PostgreSQL 12.11, DBeaver Community 22.1.3, Ubuntu 20.04.4 LTS.

**Результат работы:**
+ SQL-запросы, отвечающие требованиям заданий итоговой работы

**1. В работе использовался локальный тип подключения.**
<p align="center">
  <img width="500" height="225" src="https://thumb.cloud.mail.ru/weblink/thumb/xw1/5Txw/kaCcfPvf1">
</p>

**2. ER-диаграмма базы данных.**
<p align="center">
  <img width="500" height="400" src="https://thumb.cloud.mail.ru/weblink/thumb/xw1/RH6S/ZCwnndevG">
</p>

**3. Краткое описание базы данных.**

База данных состоит из 8 таблиц:  
&nbsp;&nbsp;&nbsp;&nbsp;• aircrafts  
&nbsp;&nbsp;&nbsp;&nbsp;• airports  
&nbsp;&nbsp;&nbsp;&nbsp;• boarding_passes  
&nbsp;&nbsp;&nbsp;&nbsp;• bookings  
&nbsp;&nbsp;&nbsp;&nbsp;• flights  
&nbsp;&nbsp;&nbsp;&nbsp;• seats  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket_flights  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket  
И 2 представлений:  
&nbsp;&nbsp;&nbsp;&nbsp;• flights_v  
&nbsp;&nbsp;&nbsp;&nbsp;• routes (материализованное)

**4. Развернутый анализ базы данных.**

Основная схема – bookings.

<p align="center">
  Таблица aircrafts (самолеты)
</p>

Таблица содержит 3 атрибута:  
&nbsp;&nbsp;&nbsp;&nbsp;• aircraft_code (bpchar(3)) – код самолета;  
&nbsp;&nbsp;&nbsp;&nbsp;• model (text) – модель самолета;  
&nbsp;&nbsp;&nbsp;&nbsp;• range (int4) – максимальная дальность полета, км.  
В таблице имеются ограничения атрибутов:  
&nbsp;&nbsp;&nbsp;&nbsp;• aircrafts_pkey – ограничение первичного ключа на атрибут aircraft_code;  
&nbsp;&nbsp;&nbsp;&nbsp;• aircrafts_range_check – ограничение-проверка значения range (range > 0);  
&nbsp;&nbsp;&nbsp;&nbsp;• все атрибуты таблицы имеют ограничение NOT NULL.  
Индексы в таблице:  
&nbsp;&nbsp;&nbsp;&nbsp;• aircrafts_pkey – индекс по первичному ключу (aircraft_code).  
В срезе на 13.10.2016 г. таблица содержит 9 записей.

<p align="center">
  Таблица airports (аэропорты)
</p>

Таблица содержит 6 атрибутов:  
&nbsp;&nbsp;&nbsp;&nbsp;• airport_code (bpchar(3)) – код аэропорта;  
&nbsp;&nbsp;&nbsp;&nbsp;• airport_name (text) – название аэропорта;  
&nbsp;&nbsp;&nbsp;&nbsp;• city (text) – город;  
&nbsp;&nbsp;&nbsp;&nbsp;• longitude (float8) – координаты аэропорта: долгота;  
&nbsp;&nbsp;&nbsp;&nbsp;• latitude (float8) – координаты аэропорта: широта;  
&nbsp;&nbsp;&nbsp;&nbsp;• timezone (text) – временная зона аэропорта.  
В таблице имеются ограничения атрибутов:  
&nbsp;&nbsp;&nbsp;&nbsp;• airports_pkey – ограничение первичного ключа на атрибут airport_code;  
&nbsp;&nbsp;&nbsp;&nbsp;• все атрибуты таблицы имеют ограничение NOT NULL.  
Индексы в таблице:  
&nbsp;&nbsp;&nbsp;&nbsp;• airports_pkey – индекс по первичному ключу (airport_code).  
В срезе на 13.10.2016 г. таблица содержит 104 записи.

<p align="center">
  Таблица boarding_passes (посадочные талоны)
</p>

Таблица содержит 4 атрибута:  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket_no (bpchar(13)) – номер билета;  
&nbsp;&nbsp;&nbsp;&nbsp;• flight_id (int4) – идентификатор рейса;  
&nbsp;&nbsp;&nbsp;&nbsp;• boarding_no (int4) – номер посадочного талона;  
&nbsp;&nbsp;&nbsp;&nbsp;• seat_no (vachar(4)) – номер места.  
В таблице имеются ограничения атрибутов:  
&nbsp;&nbsp;&nbsp;&nbsp;• boarding_passes_pkey - ограничение составного первичного ключа на атрибуты ticket_no и flight_id;  
&nbsp;&nbsp;&nbsp;&nbsp;• boarding_passes_flight_id_boarding_no_key – ограничение уникальности на атрибуты flight_id и boarding_no;  
&nbsp;&nbsp;&nbsp;&nbsp;• boarding_passes_flight_id_seat_no_key – ограничение уникальности на атрибуты flight_id и seat_no;  
&nbsp;&nbsp;&nbsp;&nbsp;• boarding_passes_ticket_no_fkey – ограничение внешнего ключа на атрибуты ticket_no и flight_no, ссылается на атрибуты с аналогичными именами таблицы ticket_flights;  
&nbsp;&nbsp;&nbsp;&nbsp;• все атрибуты таблицы имеют ограничение NOT NULL.  
Индексы в таблице:  
&nbsp;&nbsp;&nbsp;&nbsp;• boarding_passes_pkey – индекс по первичному ключу (ticket_no + flight_id);  
&nbsp;&nbsp;&nbsp;&nbsp;• boarding_passes_flight_id_t – индекс по flight_id и boarding_no;  
&nbsp;&nbsp;&nbsp;&nbsp;• boarding_passes_flight_id_s – индекс по flight_id и seat_no.  
В срезе на 13.10.2016 г. таблица содержит 579 686 записей.

<p align="center">
  Таблица bookings (бронирования)
</p>

Таблица содержит 3 атрибута:  
&nbsp;&nbsp;&nbsp;&nbsp;• book_ref (bpchar(6)) – номер бронирования;  
&nbsp;&nbsp;&nbsp;&nbsp;• book_date (timestamptz) – дата бронирования;  
&nbsp;&nbsp;&nbsp;&nbsp;• total_amount (numeric(10, 2)) – полная сумма бронирования.  
В таблице имеются ограничения атрибутов:  
&nbsp;&nbsp;&nbsp;&nbsp;• bookings_pkey – ограничение первичного ключа на атрибут book_ref;  
&nbsp;&nbsp;&nbsp;&nbsp;• все атрибуты таблицы имеют ограничение NOT NULL.  
Индексы в таблице:  
&nbsp;&nbsp;&nbsp;&nbsp;• bookings_pkey – индекс по первичному ключу (book_ref).  
В срезе на 13.10.2016 г. таблица содержит 262 788 записей.

<p align="center">
  Таблица flights(рейсы)
</p>

Таблица содержит 10 атрибутов:  
&nbsp;&nbsp;&nbsp;&nbsp;• flight_id (serial4) – идентификатор рейса; значение по умолчанию – значения счетчика flights_flight_id_seq;  
&nbsp;&nbsp;&nbsp;&nbsp;• flight_no (bpchar(6)) – номер рейса;  
&nbsp;&nbsp;&nbsp;&nbsp;• sheduled_departure (timestamptz) – время вылета по расписанию;  
&nbsp;&nbsp;&nbsp;&nbsp;• scheduled_arrival (timestamptz) – время прилета по расписанию;  
&nbsp;&nbsp;&nbsp;&nbsp;• departure_airport (bpchar(3)) – аэропорт отправления;  
&nbsp;&nbsp;&nbsp;&nbsp;• arrival_airport (bpchar(3)) – аэропорт прибытия;  
&nbsp;&nbsp;&nbsp;&nbsp;• status (varchar(20)) – статус рейса;  
&nbsp;&nbsp;&nbsp;&nbsp;• aircraft_code (bpchar(3)) – код самолета;  
&nbsp;&nbsp;&nbsp;&nbsp;• actual_departure (timestamptz) – фактическое время вылета;  
&nbsp;&nbsp;&nbsp;&nbsp;• actual_arrival (timestamptz) – фактическое время прилета.  
В таблице имеются ограничения атрибутов:  
&nbsp;&nbsp;&nbsp;&nbsp;• flights_pkey – ограничение суррогатного первичного ключа на атрибут flight_id;  
&nbsp;&nbsp;&nbsp;&nbsp;• flights_flight_no_scheduled_departure_key – ограничение уникальности по атрибутам flight_no и scheduled_departure;  
&nbsp;&nbsp;&nbsp;&nbsp;• flights_check – ограничение-проверка значения пары scheduled_arrival и scheduled_departure (scheduled_arrival > scheduled_departure);  
&nbsp;&nbsp;&nbsp;&nbsp;• flights_check1 – ограничение-проверка значения пары actual_arrival и actual_departure ((actual_arrival IS NOT NULL) OR ((actual_departure IS NOT NULL) AND (actual_arrival IS NOT NULL) AND (actual_arrival > actual_departure)))  
&nbsp;&nbsp;&nbsp;&nbsp;• flights_status_check – ограничение-проверка значения status (может быть только любым из статусов: On Time (рейс доступен для регистрации за сутки до плановой даты вылета и не задержан), Delayed (рейс доступен для регистрации за сутки до вылета, но задержан), Departed (самолет вылетел, находится в воздухе), Arrival (самолет прибыл в пункт назначения), Scheduled (рейс доступен для бронирования), Cancelled (рейс отменен));  
&nbsp;&nbsp;&nbsp;&nbsp;• flights_aircraft_code_fkey – ограничение внешнего ключа на атрибут aircraft_code, ссылается на aircraft_code таблицы aircrafts;  
&nbsp;&nbsp;&nbsp;&nbsp;• flights_arrival_airport_fkey – ограничение внешнего ключа на атрибут arrival_airport, ссылается на airport_code таблицы airports;  
&nbsp;&nbsp;&nbsp;&nbsp;• flights_departure_airport_fkey – ограничение внешнего ключа на атрибут departure_airport, ссылкается на airport_code таблицы airports;  
&nbsp;&nbsp;&nbsp;&nbsp;• flight_id, flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code имеют ограничение NOT NULL.  
&nbsp;&nbsp;&nbsp;&nbsp;• actual_departure, actual_arrival имеют ограничение NULL (могут принимать значение NULL).  
Индексы в таблице:  
&nbsp;&nbsp;&nbsp;&nbsp;• flights_pkey – индекс по первичному ключу (flight_id)  
&nbsp;&nbsp;&nbsp;&nbsp;• flights_flight_no_scheduled_departure_key – индекс по flight_no и scheduled_departure.  
В срезе на 13.10.2016 г. таблица содержит 33 121 запись.

<p align="center">
  Таблица seats (места в самолете)
</p>

Таблица содержит 3 атрибута:  
&nbsp;&nbsp;&nbsp;&nbsp;• aircraft_code (bpchar(3)) – код самолета;  
&nbsp;&nbsp;&nbsp;&nbsp;• seat_no (varchar(4)) – номер места;  
&nbsp;&nbsp;&nbsp;&nbsp;• fare_conditions (varchar(10)) – класс обслуживания.  
В таблице имеются ограничения атрибутов:  
&nbsp;&nbsp;&nbsp;&nbsp;• seats_pkey – ограничение составного первичного ключа на атрибуты aircraft_code и seat_no;  
&nbsp;&nbsp;&nbsp;&nbsp;• seats_fare_conditions_check – ограничение-проверка значения fare_conditions (может быть только любым из классов обслуживания: Economy, Comfort, Business);  
&nbsp;&nbsp;&nbsp;&nbsp;• seats_aircraft_code_fkey – ограничение внешнего ключа на атрибут aircraft_code, ссылается на aircraft_code таблицы aircrafts. Атрибут ON DELETE CASCADE указывает, что при удалении записей из aircrafts будут удалены соответствующие записи из seats;  
&nbsp;&nbsp;&nbsp;&nbsp;• все атрибуты таблицы имеют ограничение NOT NULL.  
Индексы в таблице:  
&nbsp;&nbsp;&nbsp;&nbsp;• seats_pkey – индекс по первичному ключу (aircraft_code + seat_no).  
В срезе на 13.10.2016 г. таблица содержит 1339 записей.

<p align="center">
  Таблица ticket_flights (перелеты)
</p>

Таблица содержит 4 атрибута:  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket_no (bpchar(3)) – номер билета;  
&nbsp;&nbsp;&nbsp;&nbsp;• flight_id (int4) – идентификатор рейса;  
&nbsp;&nbsp;&nbsp;&nbsp;• fare_conditions (varchar(10)) – класс обслуживания;  
&nbsp;&nbsp;&nbsp;&nbsp;• amount (numeric(10,2)) – стоимость перелета.  
В таблице имеются ограничения атрибутов:  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket_flights_pkey – ограничение составного первичного ключа по атрибутам ticket_no и flight_id;  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket_flights_amount_check – ограничение-проверка для значения amount (amount >=0);  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket_flights_fare_conditions_check - ограничение-проверка значения fare_conditions (может быть только любым из классов обслуживания: Economy, Comfort, Business);  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket_flights_flight_id_key – ограничение внешнего ключа на flight_id, ссылается на flight_id таблицы flights;  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket_flights_ticket_no_fkey – ограничение внешнего ключа на ticket_no, ссылается на ticket_no таблицы tickets;  
&nbsp;&nbsp;&nbsp;&nbsp;• все атрибуты таблицы имеют ограничение NOT NULL.  
Индексы в таблице:  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket_flights_pkey – индекс по первичному ключу (ticket_no + flight_id).  
В срезе на 13.10.2016 г. таблица содержит 1 045 726 записей.

<p align="center">
  Таблица tickets (билеты)
</p>

Таблица содержит 5 атрибутов:  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket_no (bpchar(13)) – номер билета;  
&nbsp;&nbsp;&nbsp;&nbsp;• book_ref (bpchar(6)) -  номер бронирования;  
&nbsp;&nbsp;&nbsp;&nbsp;• passenger_id (varchar(20)) – идентификатор пассажира;  
&nbsp;&nbsp;&nbsp;&nbsp;• passenger_name (text) – имя пассажира;  
&nbsp;&nbsp;&nbsp;&nbsp;• contact_data (jsonb) – контактные данные пассажира.  
В таблице имеются ограничения атрибутов:  
&nbsp;&nbsp;&nbsp;&nbsp;• tickets_pkey – ограничение первичного ключа по атрибуту ticket_no;  
&nbsp;&nbsp;&nbsp;&nbsp;• tickets_book_ref_fkey – ограничение внешнего ключа book_ref, ссылается на book_ref таблицы bookings;  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket_no, book_ref, passenger_id, passenger_name имеют ограничение NOT NULL;  
&nbsp;&nbsp;&nbsp;&nbsp;• contact_data имеет ограничение NULL (может принимать значение NULL).  
Индексы в таблице:  
&nbsp;&nbsp;&nbsp;&nbsp;• ticket_flights_pkey – индекс по первичному ключу (ticket_no + flight_id).  
В срезе на 13.10.2016 г. таблица содержит 366 733 записи.

<p align="center">
  Представление flights_v
</p>

Содержит информацию из таблицы flights, дополненную данными из таблицы airports:  
&nbsp;&nbsp;&nbsp;&nbsp;• scheduled_departure_local – время вылета по расписанию, местное время в пункте отправления;  
&nbsp;&nbsp;&nbsp;&nbsp;• scheduled_arrival_local – время прилета по расписанию, местное время в пункте прибытия;  
&nbsp;&nbsp;&nbsp;&nbsp;• scheduled_duration – планируемая продолжительность полета;  
&nbsp;&nbsp;&nbsp;&nbsp;• departure_airport_name – название аэропорта отправления;  
&nbsp;&nbsp;&nbsp;&nbsp;• departure_city – город отправления;  
&nbsp;&nbsp;&nbsp;&nbsp;• arrival_airport_name – название аэропорта прибытия;  
&nbsp;&nbsp;&nbsp;&nbsp;• arrival_city – город прибытия;  
&nbsp;&nbsp;&nbsp;&nbsp;• actual_departure_local – фактическое время вылета, местное время в пункте отправления;  
&nbsp;&nbsp;&nbsp;&nbsp;• actual_arrival_local – фактическое время прилета, местное время в пункте прибытия;  
&nbsp;&nbsp;&nbsp;&nbsp;• actual_duration – фактическая продолжительность полета.

<p align="center">
  Материализованное представление routes 
</p>

Содержит информацию из таблицы flights, дополненную данными из таблицы airports:  
&nbsp;&nbsp;&nbsp;&nbsp;• departure_airport_name – название аэропорта отправления;  
&nbsp;&nbsp;&nbsp;&nbsp;• departure_city – город отправления;  
&nbsp;&nbsp;&nbsp;&nbsp;• arrival_airport_name – название аэропорта прибытия;  
&nbsp;&nbsp;&nbsp;&nbsp;• arrival_city – город прибытия;  
&nbsp;&nbsp;&nbsp;&nbsp;• duration – планируемая продолжительность полета;  
&nbsp;&nbsp;&nbsp;&nbsp;• days_of_week – дни недели, когда выполняются рейсы.  
В срезе на 13.10.2016 г. содержит 710 записей.

<p align="center">
  Функция bookings.now()
</p>

Функция-аналог now() для данной БД. bookings.now() = 2016-10-13 17:00:00 по московскому времени. Возвращает timestamptz.

**Бизнес-задачи, которые можно решить с помощью базы данных авиаперелетов:**
 + Анализ эффективности использования самолета на каждом маршруте по дальности полета. Можно оптимизировать маршруты, а также организовывать новые в города, не имеющие прямых рейсов (при соблюдении других условий).
 + Анализ эффективности использования самолета на каждом маршруте по количеству занятых мест. Основываясь на исторических данных также можно выявить спрос на определенные направления в разрезе временных диапазонов (корректировать частоту полетов в зависимости от времени года / праздничных / выходных дней и т.д.).
 + Анализ спроса в общем, на определенных маршрутах и, в частности, в зависимости от класса обслуживания. Такие данные дадут небольшое понимание портрета клиента, по ним можно проводить анализ ценовой политики, а также на их основе можно менять тип самолета на маршруте.
 + База данных содержит контактную информацию о клиенте, совершившем бронирование. Номер телефона и e-mail можно использовать для оповещения о переносе рейса, рекламных и акционных предложениях. Также можно дополнить портрет клиента по половому признаку (проанализировав по имени и фамилии), в том числе в разрезе класса обслуживания. Портет клиента помогает более точно проводить рекламные кампании.
 + Данные о запланированном и фактическом времени вылета / прибытия помогут выявить частоту и длительность задержек рейсов, что может повлиять на принятие решений в поиске узких мест в организационной и технической части управления. Например, увеличение частоты задержек на рейсе может говорить о техническом состоянии воздушного судна.
 + Организация расписания рейсов.

**5. Запросы согласно заданиям второй части итоговой работы в файле _Антон Селезенев DEG-17.sql._**
