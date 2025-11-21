create table xuatsac1.customers
(
    customer_id serial primary key,
    name        varchar(100),
    balance     numeric(12, 2)
);
create table xuatsac1.products
(
    product_id serial primary key,
    name       varchar(100),
    stock      int,
    price      numeric(10, 2)
);
create table xuatsac1.orders
(
    order_id     serial primary key,
    customer_id  int references xuatsac1.customers (customer_id),
    total_amount numeric(12, 2),
    created_at   timestamp   default now(),
    status       varchar(20) default 'Pending'
);
create table xuatsac1.order_items
(
    item_id    serial primary key,
    order_id   int references xuatsac1.orders (order_id),
    product_id int references xuatsac1.products (product_id),
    quantity   int,
    subtotal   numeric(10, 2)
);

create or replace procedure xuatsac1.order(
    p_customer_id int,
    p_items jsonb
)
    language plpgsql
as
$$
declare
    rec          jsonb;
    amount       numeric(12, 2);
    p_product_id int;
    p_stock      int;
    p_quantity   int;
    p_subtotal   numeric(12, 2);
    p_total      numeric(12, 2) := 0;
    p_order_id   int;
    p_price      numeric(12, 2);
begin
    begin
        --Tinh tong tien don hang
        for rec in select * from jsonb_array_elements(p_items)
            loop
                p_product_id := (rec ->> 'product_id')::int;
                p_quantity := (rec ->> 'quantity')::int;
                select price into p_price from xuatsac1.products where product_id = p_product_id;
                p_total := p_total + (p_price * p_quantity);
            end loop;
        --Kiem tra so du
        if (select balance from xuatsac1.customers c where customer_id = p_customer_id) < p_total then
            raise exception 'So du khong du de mua don hang';
        end if;
        --Tao don hang
        insert into xuatsac1.orders (customer_id, total_amount)
        values (p_customer_id, p_total)
        returning orders.order_id into p_order_id;

        --Lap qua tung san pham trong json
        for rec in select * from jsonb_array_elements(p_items)
            loop
                p_product_id := (rec ->> 'product_id')::int;
                p_quantity := (rec ->> 'quantity')::int;
                --Kiem tra don hang con hang khong
                select p.stock into p_stock from xuatsac1.products p where product_id = p_product_id;
                if p_stock < p_quantity then
                    raise exception 'Hang trong kho khong du';
                end if;

                --Giam ton kho
                update xuatsac1.products p set stock = p_stock - p_quantity where product_id = p_product_id;

                --Them vao order_items
                select price into p_price from xuatsac1.products p where product_id = p_product_id;
                p_subtotal := p_price * p_quantity;
                insert into xuatsac1.order_items (order_id, product_id, quantity, subtotal)
                values (p_order_id, p_product_id, p_quantity, p_subtotal);
            end loop;
        --Tru tien khach hang
        update xuatsac1.customers
        set balance = customers.balance - p_total
        where customers.customer_id = p_customer_id;

        --Cap nhat status
        update xuatsac1.orders set status = 'COMPLETED' where orders.order_id = p_order_id;
    exception
        when others then
            rollback;
            raise;

    end;
end;
$$;

call xuatsac1."order"(
        2,
        '[
          {
            "product_id": 1,
            "quantity": 2
          },
          {
            "product_id": 3,
            "quantity": 1
          }
        ]'
     )