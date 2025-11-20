create table kha1.flights
(
    flight_id       serial primary key,
    flight_name     varchar(100),
    available_seats int
);
create table kha1.bookings
(
    booking_id    serial primary key,
    flight_id     int references kha1.flights (flight_id),
    customer_name varchar(100)
);

insert into kha1.flights (flight_name, available_seats)
values ('VN123', 3),
       ('VN456', 2);

create or replace procedure kha1.booking_ticket(
    p_flight_id int,
    p_customer_name varchar(100)
)
    language plpgsql
as
$$
begin
    update kha1.flights set available_seats = flights.available_seats - 1 where flights.flight_id = p_flight_id;
    if not FOUND then
        raise exception 'Khong tim thay ve co ma la: %', p_flight_id;
    end if;
    if (select available_seats from kha1.flights where flight_id = p_flight_id) < 0 then
        raise exception 'Ve da het. Vui long dat ve khac';
    end if;
    insert into kha1.bookings (flight_id, customer_name) values (p_flight_id, p_customer_name);
exception
    when others then
        rollback;
        raise ;
end;
$$;

call kha1.booking_ticket(1, 'Nguyen Van F');