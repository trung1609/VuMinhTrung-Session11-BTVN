create table gioi2.accounts
(
    account_id    serial primary key,
    customer_name varchar(100),
    balance       numeric(12, 2)
);

create table gioi2.transactions
(
    trans_id   serial primary key,
    account_id int references gioi2.accounts (account_id),
    amount     numeric(12, 2),
    trans_type varchar(20),
    created_at timestamp default now()
);

create or replace procedure gioi2.withdraw_money(
    acc_id int,
    amount numeric(12, 2)
)
    language plpgsql
as
$$
declare
    p_balance numeric(12, 2);
begin
    begin
        --Kiem tra tai khoan co dung hay khong
        select balance into p_balance from gioi2.accounts acc where account_id = acc_id;
        if not FOUND then
            raise exception 'Tai khoan khong ton tai';
        end if;

        --Kiem tra so du tai khoan
        if p_balance < amount
        then
            raise exception 'So du tai khoan khong du';
        end if;

        --Tru so du tai khoan
        update gioi2.accounts set balance = accounts.balance - amount where accounts.account_id = acc_id;

        --Ghi log
        insert into gioi2.transactions (account_id, amount, trans_type) values (acc_id, amount, 'Withdraw');

    exception
        when others then
            rollback;
            raise;
    end;
end;
$$;

call gioi2.withdraw_money(1, 5000);

create or replace procedure gioi2.deposit_money(
    acc_id int,
    amount numeric(12, 2)
)
    language plpgsql
as
$$
declare
    p_balance numeric(12, 2);
begin
    begin
        --Kiem tra tai khoan
        select balance into p_balance from gioi2.accounts where account_id = acc_id;
        if not FOUND then
            raise exception 'Tai khoan khong chinh xac';
        end if;

        --Cong tien vao tai khoan
        update gioi2.accounts set balance = p_balance + amount where accounts.account_id = acc_id;

        --Ghi log
        insert into gioi2.transactions (account_id, amount, trans_type) values (acc_id, amount, 'Deposit');
    exception
        when others then
            rollback;
            raise;
    end;
end;
$$;

call gioi2.deposit_money(1, 100000)