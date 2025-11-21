CREATE TABLE xuatsac2.accounts
(
    account_id SERIAL PRIMARY KEY,
    owner_name VARCHAR(100),
    balance    NUMERIC(12, 2),
    status     VARCHAR(10) DEFAULT 'ACTIVE'
);
create TABLE xuatsac2.transactions
(
    trans_id     SERIAL PRIMARY KEY,
    from_account INT ,
    to_account   INT,
    amount       NUMERIC(12, 2),
    status       VARCHAR(20) DEFAULT 'PENDING',
    created_at   TIMESTAMP   DEFAULT NOW()
);


INSERT INTO xuatsac2.accounts (owner_name, balance, status)
VALUES ('Nguyen Van A', 5000.00, 'ACTIVE'),
       ('Tran Thi B', 7500.00, 'ACTIVE'),
       ('Le Van C', 12000.00, 'ACTIVE');

create or replace procedure xuatsac2.funds_tranfer(
    acc_no_sender int,
    acc_no_receive int,
    p_amount numeric(10, 2)
)
    language plpgsql
as
$$
declare
    p_balance  numeric(10, 2);
    p_status   varchar(10);
    p_trans_id int;
begin
    begin
        --Khoa tai khoan
        perform 1
        from xuatsac2.accounts acc
        where acc.account_id in (acc_no_sender, acc_no_receive) for update;
        --Kiem tra tai khoan
        if not FOUND then
            raise exception 'Tai khoan khong chinh xac';
        end if;
        --Kiem tra trang thai tai khoan va so du
        select status, balance into p_status, p_balance from xuatsac2.accounts acc where account_id = acc_no_sender;
        if p_status != 'ACTIVE' then
            raise exception 'Tai khoan nguoi gui khong con hoat dong';
        end if;
        if p_balance < p_amount then
            raise exception 'So du khong du';
        end if;
        --Giam tien tai khoan gui
        update xuatsac2.accounts set balance = balance - p_amount where accounts.account_id = acc_no_sender;

        --Ghi log giao dich
        insert into xuatsac2.transactions (from_account, to_account, amount)
        values (acc_no_sender, acc_no_receive, p_amount)
        returning trans_id into p_trans_id;

        --Tang tien tai khoan nhan
        update xuatsac2.accounts set balance = balance + p_amount where accounts.account_id = acc_no_receive;

        --Cap nhat status
        update xuatsac2.transactions set status = 'COMPLETED' where transactions.trans_id = p_trans_id;
    exception
        when others then
            rollback;
            raise;
    end;
end;
$$;

call xuatsac2.funds_tranfer(2,3, 1000);
