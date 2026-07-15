CREATE DATABASE ECommerceAnalytics

-- Preview raw data
SELECT * FROM Orders;

-- Total row count
SELECT COUNT(*) AS Total_Rows
FROM Orders;

-- Check for duplicate OrderIDs
SELECT OrderID, COUNT(*) AS cnt
FROM Orders
GROUP BY OrderID
HAVING COUNT(*) > 1;

-- Check for NULLs across key columns
SELECT
    COUNT(CASE WHEN CustomerID     IS NULL THEN 1 END) AS null_CustomerID,
    COUNT(CASE WHEN [Date]         IS NULL THEN 1 END) AS null_Date,
    COUNT(CASE WHEN Quantity       IS NULL THEN 1 END) AS null_Quantity,
    COUNT(CASE WHEN UnitPrice      IS NULL THEN 1 END) AS null_UnitPrice,
    COUNT(CASE WHEN ShippingAddress IS NULL THEN 1 END) AS null_ShippingAddress,
    COUNT(CASE WHEN PaymentMethod  IS NULL THEN 1 END) AS null_PaymentMethod,
    COUNT(CASE WHEN CouponCode     IS NULL OR CouponCode = '' THEN 1 END) AS null_CouponCode
FROM Orders;

-- Replace blank/NULL coupon codes with 'No Coupon' (these are orders where no coupon was used)
UPDATE Orders
SET CouponCode = 'No Coupon'
WHERE CouponCode IS NULL OR CouponCode = '';

-- Make sure numeric columns are the right precision
ALTER TABLE Orders ALTER COLUMN UnitPrice DECIMAL(10,2);
ALTER TABLE Orders ALTER COLUMN TotalPrice DECIMAL(12,2);

-- Verify TotalPrice = Quantity * UnitPrice (flag any mismatches)
SELECT OrderID, Quantity, UnitPrice, TotalPrice,
       (Quantity * UnitPrice) AS Calculated_Total
FROM Orders
WHERE ABS(TotalPrice - (Quantity * UnitPrice)) > 0.02;

-- Display cleaned data
SELECT * FROM Orders;
GO

-- ----------------------------------------------------------------
-- 4. KEY PERFORMANCE INDICATORS (KPIs)
-- ----------------------------------------------------------------
SELECT
    SUM(Quantity)              AS Total_Quantity,
    SUM(TotalPrice)            AS Total_Revenue,
    COUNT(OrderID)             AS Total_Orders,
    COUNT(DISTINCT CustomerID) AS Total_Customers,
    SUM(ItemsInCart)           AS Total_Items_In_Cart,
    ROUND(AVG(TotalPrice), 2)  AS Average_Order_Value,
    ROUND(AVG(Quantity), 2)    AS Average_Quantity
FROM Orders;
GO

-- ----------------------------------------------------------------
-- 5. FILTERING
-- ----------------------------------------------------------------

-- Cancelled orders
SELECT OrderID, Product, OrderStatus, TotalPrice
FROM Orders
WHERE OrderStatus = 'Cancelled';

-- Orders paid online
SELECT OrderID, Product, PaymentMethod, OrderStatus, TotalPrice
FROM Orders
WHERE PaymentMethod = 'Online';

-- Orders from Instagram referral
SELECT OrderID, Product, PaymentMethod, OrderStatus, ReferralSource, TotalPrice
FROM Orders
WHERE ReferralSource = 'Instagram';

-- High-value outlier orders (based on IQR upper bound established in EDA: $3,330.41)
SELECT OrderID, Product, TotalPrice
FROM Orders
WHERE TotalPrice > 3330.41
ORDER BY TotalPrice DESC;
GO

-- ----------------------------------------------------------------
-- 6. SORTING
-- ----------------------------------------------------------------

-- Orders sorted by highest total price
SELECT Product, CouponCode, TotalPrice
FROM Orders
ORDER BY TotalPrice DESC;

-- Orders sorted by lowest total price
SELECT Product, ReferralSource, TotalPrice
FROM Orders
ORDER BY TotalPrice ASC;
GO

-- ----------------------------------------------------------------
-- 7. INSIGHTS -- BUSINESS QUESTIONS
-- ----------------------------------------------------------------

-- Total quantity sold per product
SELECT Product, SUM(Quantity) AS Total_Quantity
FROM Orders
GROUP BY Product
ORDER BY Total_Quantity DESC;

-- Best-selling products by revenue (Top 5)
SELECT TOP 5 Product, ROUND(SUM(TotalPrice), 1) AS Revenue
FROM Orders
GROUP BY Product
ORDER BY Revenue DESC;

-- Monthly revenue trend
SELECT FORMAT([Date], 'MMM') AS Month_Name, ROUND(SUM(TotalPrice), 1) AS Revenue
FROM Orders
GROUP BY FORMAT([Date], 'MMM'), MONTH([Date])
ORDER BY MONTH([Date]);

-- Revenue by referral source (which channel drives the most revenue?)
SELECT ReferralSource, ROUND(SUM(TotalPrice), 1) AS Revenue
FROM Orders
GROUP BY ReferralSource
ORDER BY Revenue DESC;

-- Most-used coupon code
SELECT CouponCode, COUNT(CouponCode) AS Usage_Count
FROM Orders
GROUP BY CouponCode
ORDER BY Usage_Count DESC;

-- Most-used payment methods
SELECT PaymentMethod, COUNT(OrderID) AS Total_Orders
FROM Orders
GROUP BY PaymentMethod
ORDER BY Total_Orders DESC;

-- Order status breakdown
SELECT OrderStatus, COUNT(*) AS Total_Orders
FROM Orders
GROUP BY OrderStatus
ORDER BY Total_Orders DESC;

-- Revenue by payment method
SELECT PaymentMethod, SUM(TotalPrice) AS Total_Revenue
FROM Orders
GROUP BY PaymentMethod
ORDER BY Total_Revenue DESC;

-- Products with more than 100 orders
SELECT Product, COUNT(OrderID) AS Total_Orders
FROM Orders
GROUP BY Product
HAVING COUNT(OrderID) > 100
ORDER BY Total_Orders DESC;

-- Top 3 products by revenue
SELECT TOP 3 Product, SUM(TotalPrice) AS Total_Revenue
FROM Orders
GROUP BY Product
ORDER BY Total_Revenue DESC;

-- Top 10 customers by total spend
SELECT TOP 10 CustomerID, SUM(TotalPrice) AS Total_Spend, COUNT(OrderID) AS Total_Orders
FROM Orders
GROUP BY CustomerID
ORDER BY Total_Spend DESC;

-- Coupon usage rate (share of orders that used any coupon)
SELECT
    COUNT(CASE WHEN CouponCode <> 'No Coupon' THEN 1 END) * 100.0 / COUNT(*) AS Coupon_Usage_Rate_Pct
FROM Orders;

-- Revenue per customer and orders per customer
SELECT
    ROUND(SUM(TotalPrice) / COUNT(DISTINCT CustomerID), 2) AS Revenue_Per_Customer,
    ROUND(COUNT(OrderID) * 1.0 / COUNT(DISTINCT CustomerID), 2) AS Orders_Per_Customer
FROM Orders;
GO

SELECT * FROM Orders