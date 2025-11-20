create table gioi1.products
(
    product_id   serial primary key,
    product_name varchar(100),
    stock        int,
    price        numeric(10, 2)
);
create table gioi1.orders
(
    order_id      serial primary key,
    customer_name varchar(100),
    total_amount  numeric(10, 2),
    create_at     timestamp default now()
);

create table gioi1.order_items
(
    order_item_id serial primary key,
    order_id      int references gioi1.orders (order_id),
    product_id    int references gioi1.products (product_id),
    quantity      int,
    subtotal      numeric(10, 2)
);
insert into gioi1.products (product_name, stock, price)
values ('SP1', 20, 2000),
       ('SP2', 15, 1000);

create or replace procedure gioi1.order(
    p_customer_name varchar(100),
    p_items jsonb
)
    language plpgsql
as
$$
declare
    p_order_id   int;
    rec          jsonb;
    p_product_id int;
    p_quantity   int;
    p_stock      int;
    p_total      numeric(10, 2) := 0;
    p_price      numeric(10, 2);
    p_subtotal   numeric(10, 2);
begin
    begin
        --Tao don hang rong
        insert into gioi1.orders (customer_name, total_amount)
        values (p_customer_name, 0)
        returning orders.order_id into p_order_id;
        --Lap qua tung san pham trong Json
        for rec in select * from jsonb_array_elements(p_items)
            loop
                -- ep ve kieu so
                p_product_id := (rec ->> 'product_id')::int;
                p_quantity := (rec ->> 'quantity'):: int;
                --Lay gia va ton kho
                select stock, price
                into p_stock, p_price
                from gioi1.products p
                where p.product_id = p_product_id for update;
                --Kiem tra ton kho
                if p_stock < p_quantity then
                    raise exception 'So hang trong kho khong du cho product id = %', p_product_id;
                end if;
                --Tru so luong trong kho
                update gioi1.products set stock = p_stock - p_quantity where products.product_id = p_product_id;
                --Tinh tien cua moi don hang
                p_subtotal := p_price * p_quantity;
                --Them vao chi tiet san pham
                insert into gioi1.order_items (order_id, product_id, quantity, subtotal)
                values (p_order_id, p_product_id, p_quantity, p_subtotal);

                --Cap nhat tong tien
                p_total := p_total + p_subtotal;
            end loop;
        --Cap nhat tong tien
        update gioi1.orders o set total_amount = p_total where o.order_id = p_order_id;
        --Neu loi thi rollback
    exception
        when others then
            rollback;
            raise;
    end;
end;
$$;

call gioi1.order(
        'Nguyen Van B',
        '[
          {
            "product_id": 1,
            "quantity": 2
          },
          {
            "product_id": 2,
            "quantity": 2
          }
        ]'::jsonb
     )