BEGIN;
CREATE TABLE Instrument
(
    Id   int,
    Name varchar(255)
);
CREATE TABLE Trade
(
    Id           int,
    InstrumentId int,
    DateEn       timestamptz,
    Open         decimal,
    High
                 decimal,
    Low          decimal,
    Close        decimal
);
INSERT INTO Instrument
values (1, 'AAPL'),
       (2, 'GOOGL');
INSERT INTO Trade
VALUES (1, 1, '2020-01-01', 1001, 2001, 301, 401),
       (2, 1, '2020-01-02', 1002, 2002, 302, 402),
       (3, 1, '2020-01-03', 1003, 2003, 303, 403),
       (4, 2, '2020-01-01', 1004, 2004, 304, 404),
       (5, 2, '2020-01-03', 1005, 2005, 305, 405),
       (6, 5, '2020-01-01', 1006, 2006, 306, 406),
       (7, 1, '2021-01-01', 1007, 2007, 307, 407);
COMMIT;