use TradeTracker;
select *
From Sheet2$;

-- Separate Date and time column to date and time separate using excel and extract date on from TradeDate
ALTER TABLE Sheet2$
Add TradeDateConverted Date;

Update Sheet2$
SET TradeDateConverted = CONVERT(Date,TradeDate)

--Create Identity Column
alter table Sheet2$
add SrNo int identity(1,1)

--------------------------------------SOLUTION TO NULL SYMBOL------------------------------------------------------
--Select only required column with SymbolPopulated

SELECT 
	SrNo, AcctID 
	,(SELECT TOP 1 Symbol FROM Sheet2$ a WHERE a.SrNo = 
	(SELECT MAX(b.SrNo) FROM Sheet2$ b WHERE b.SrNo <= c.SrNo AND b.Symbol IS NOT NULL) ) as SymbolNonNull  
	, TradeDateConverted, Type, Quantity, Price, Proceeds,Comm	     
FROM Sheet2$ as C

--Create New Table with Symbol Populated
DROP Table if exists SymbolPopulated
Create Table SymbolPopulated
(
SN numeric,
AcctID nvarchar(255),
Symbol nvarchar(255),
TradeDate date,
BuySell nvarchar(255),
Quantity numeric,
Price float,
Proceeds float,
Comm float
)
Insert into SymbolPopulated
 SELECT 
	SrNo, AcctID 
	,(SELECT TOP 1 Symbol FROM Sheet2$ a WHERE a.SrNo = 
	(SELECT MAX(b.SrNo) FROM Sheet2$ b WHERE b.SrNo <= c.SrNo AND b.Symbol IS NOT NULL) )  
	, TradeDateConverted, Type, Quantity, Price, Proceeds,Comm
		     
FROM Sheet2$ as C

Select * 
From SymbolPopulated


--------------------------------------SOLUTION TO NULL TradeDate------------------------------------------------------

SELECT 
	SN, AcctID 
	,(SELECT TOP 1 TradeDate FROM SymbolPopulated a WHERE a.SN = 
	(SELECT MAX(b.SN) FROM SymbolPopulated b WHERE b.SN <= c.SN AND b.TradeDate IS NOT NULL) ) as TradeDateNonNull  
	, TradeDate, BuySell, Quantity, Price, Proceeds,Comm	     
FROM SymbolPopulated as C

--Create New Table with Symbol And TradeDate Populated
DROP Table if exists SymbolAndTradeDatePopulated
Create Table SymbolAndTradeDatePopulated
(
SN numeric,
AcctID nvarchar(255),
Symbol nvarchar(255),
TradeDate date,
BuySell nvarchar(255),
Quantity numeric,
Price float,
Proceeds float,
Comm float
)
Insert into SymbolAndTradeDatePopulated
 SELECT 
	SN, AcctID , Symbol
	,(SELECT TOP 1 TradeDate FROM SymbolPopulated a WHERE a.SN = 
	(SELECT MAX(b.SN) FROM SymbolPopulated b WHERE b.SN <= c.SN AND b.TradeDate IS NOT NULL) )
	, BuySell, Quantity, Price, Proceeds,Comm	     
FROM SymbolPopulated as C

Select * 
From SymbolAndTradeDatePopulated


--------------------------------------SOLUTION TO NULL BuySell or Type------------------------------------------------------

SELECT 
	SN, AcctID 
	,(SELECT TOP 1 BuySell FROM SymbolAndTradeDatePopulated a WHERE a.SN = 
	(SELECT MAX(b.SN) FROM SymbolAndTradeDatePopulated b WHERE b.SN <= c.SN AND b.BuySell IS NOT NULL) ) as BuySellNonNull  
	, TradeDate, BuySell, Quantity, Price, Proceeds,Comm	     
FROM SymbolAndTradeDatePopulated as C

--Create New Table with Symbol And TradeDate Populated
DROP Table if exists AllPopulated
Create Table AllPopulated
(
SN numeric,
AcctID nvarchar(255),
Symbol nvarchar(255),
TradeDate date,
BuySell nvarchar(255),
Quantity numeric,
Price float,
Proceeds float,
Comm float
)
Insert into AllPopulated
 SELECT 
	SN, AcctID , Symbol, TradeDate
	,(SELECT TOP 1 BuySell FROM SymbolAndTradeDatePopulated a WHERE a.SN = 
	(SELECT MAX(b.SN) FROM SymbolAndTradeDatePopulated b WHERE b.SN <= c.SN AND b.BuySell IS NOT NULL) )  
   , Quantity, Price, Proceeds,Comm	     
FROM SymbolAndTradeDatePopulated as C

Select * 
From AllPopulated


-- Select the row that has brought and sold
Select *
From AllPopulated
Where AcctID like '%Total%'
and Quantity != 0
;


--Create Final Table selecting on Account ID with Total-------------------
DROP Table if exists Table1
Create Table Table1
(
SN numeric,
AcctID nvarchar(255),
Symbol nvarchar(255),
TradeDate date,
BuySell nvarchar(255),
Quantity numeric,
Price float,
Proceeds float,
Comm float
)

Insert into Table1
Select *
From AllPopulated
Where AcctID like '%Total%'
and Quantity != 0
;

Select *
From Table1


alter table Table1
add SrNo int identity(1,1)
---------------------------------------------------------Self Joining table to bring buy and sell on single row.---------------


--making sure that trade date and symbol matches, and quantity is equal but opposite in sign, additionally Serial No difference is -1
SELECT *
  FROM Table1 AS l
  LEFT JOIN Table1 AS r ON
  l.Symbol = r.Symbol  and l.BuySell<>r.BuySell and l.Quantity = -r.Quantity and l.SrNo - r.SrNo = -1 --and l.TradeDate = r.TradeDate  because sell date and buy date can be different
  Where r.AcctID is not Null	
  ;


--Selecting only required columns [ Symbol, Quantity, BuyPrice,BuyComm, BuyDate, SellPrice, SelComm, SellDate]
SELECT l.Symbol, l.Quantity, l.Price as BuyPrice, l.Comm as BuyComm, l.TradeDate as BuyDate 
		,r.Price as SellPrice, r.Comm as SelComm, r.TradeDate  as SellDate
  FROM Table1 AS l
  LEFT JOIN Table1 AS r ON
  l.Symbol = r.Symbol  and l.BuySell<>r.BuySell and l.Quantity = -r.Quantity and l.SrNo - r.SrNo = -1 --and l.TradeDate = r.TradeDate  because sell date and buy date can be different
  Where r.AcctID is not Null	
  ;

  --Creating Table2 with required information before making any calculations

  DROP Table if exists Table2
Create Table Table2
(
Symbol nvarchar(255),
Quantity numeric,
BuyPrice float,
BuyComm float,
BuyDate date,
SellPrice float,
SellComm float,
SellDate date,
)

Insert into Table2
SELECT l.Symbol, l.Quantity, l.Price as BuyPrice, l.Comm as BuyComm, l.TradeDate as BuyDate 
		,r.Price as SellPrice, r.Comm as SelComm, r.TradeDate  as SellDate
  FROM Table1 AS l
  LEFT JOIN Table1 AS r ON
  l.Symbol = r.Symbol  and l.BuySell<>r.BuySell and l.Quantity = -r.Quantity and l.SrNo - r.SrNo = -1 --and l.TradeDate = r.TradeDate  because sell date and buy date can be different
  Where r.AcctID is not Null	
 ;

Select *
From Table2

--------------------------------------------------------------------------------
 ------ --Use of Mathematics and Statistics
  Select *, 
  Datediff(DAY,SellDate,BuyDate) as TradeLength, 
  (SellPrice- BuyPrice)*Quantity*100 as PnL,
  (BuyComm + SellComm) as TotalComm, ((SellPrice- BuyPrice)*Quantity*100+(BuyComm + SellComm)) as NetPnL
  From Table2
  --Create Table3 with LengthofTrade, PnL , TotalComm, NetPnL included.
DROP Table if exists Table3
Create Table Table3
(
Symbol nvarchar(255),
Quantity numeric,
BuyPrice float,
BuyComm float,
BuyDate date,
SellPrice float,
SellComm float,
SellDate date,
TradeLength numeric,
PnL decimal(10,2),
TotalComm decimal(10,2),
NetPnL decimal(10,2)

)

Insert into Table3
Select *, 
  Datediff(DAY,SellDate,BuyDate) as TradeLength, 
  (SellPrice- BuyPrice)*Quantity*100 as PnL,
  (BuyComm + SellComm) as TotalComm, ((SellPrice- BuyPrice)*Quantity*100+(BuyComm + SellComm)) as NetPnL
  From Table2 ;

Select *
From Table3

--extract ticker
Select 
LEFT(Symbol,CHARINDEX(' ', Symbol) - 1)
From Table3
--put call separated
Select
RIGHT(Symbol,1)
From Table3;

--Adding new columns to add Ticker and PutCall

ALTER TABLE Table3
Add Ticker Nvarchar(255);
Update Table3
SET Ticker = LEFT(Symbol,CHARINDEX(' ', Symbol) - 1)


ALTER TABLE Table3
Add PutCall Nvarchar(255);
Update Table3
SET PutCall = RIGHT(Symbol,1)

------





----------------Create Table4 with Ticker Symbol and Call Put Separated



--

DROP Table if exists FinalTable
Create Table FinalTable
(
Symbol nvarchar(255),
Ticker nvarchar(255),
PutCall nvarchar(255),
Quantity numeric,
BuyPrice float,
BuyComm float,
BuyDate date,
SellPrice float,
SellComm float,
SellDate date,
TradeLength numeric,
PnL decimal(10,2),
TotalComm decimal(10,2),
NetPnL decimal(10,2)

)

Insert into FinalTable
Select  Symbol, Ticker, PutCall, Quantity, BuyPrice,BuyComm, BuyDate,SellPrice,SellComm,SellDate,TradeLength,PnL,TotalComm,NetPnL 
From Table3;


Select *
From FinalTable




