create table kha2.accounts
(
    account_id serial primary key,
    owner_name varchar(100),
    balance    numeric(10, 2)
);

insert into kha2.accounts (owner_name, balance)
values ('A', 500.00),
       ('B', 300.00);

create or replace procedure kha2.funds_tranfer(
    p_owner_name_sender varchar(100),
    p_owner_receiver varchar(100),
    amount numeric(10, 2)
)
    language plpgsql
as
$$
declare
    cnt_owner_name int;
begin
    begin
        --Kiem tra tai khoan co hay khong
        select count(owner_name)
        into cnt_owner_name
        from kha2.accounts acc
        where acc.owner_name in (p_owner_name_sender, p_owner_receiver);


        if cnt_owner_name != 2 then
            raise exception 'So tai khoan khong chinh xac';
        end if;

        --Kiem tra so du
        if (select balance from kha2.accounts acc where acc.owner_name = p_owner_name_sender) < amount then
            raise exception 'So du trong tai khoan khong du de thuc hien chuyen tien';
        end if;

        update kha2.accounts set balance = accounts.balance - amount where accounts.owner_name = p_owner_name_sender;
        update kha2.accounts set balance = accounts.balance + amount where accounts.owner_name = p_owner_receiver;

    exception
        when others then
            rollback;
            raise;
    end;
end;
$$;

call kha2.funds_tranfer('A','B', 200.00 );