# hello-world 

## Database Constraints (for DB_HW_Sushi)

## Database Constraints (for DB_HW_Sushi)

**Customer**
- `email` UNIQUE
- `phone` NOT NULL

**Orders**
- `total_price` CHECK(total_price > 0)
- `order_time` NOT NULL

**Items**
- `price` CHECK(price > 0)

**Deliveries**
- `delivery_fee` CHECK(delivery_fee >= 0)
- `delivery_status` DEFAULT 'Pending'

**Payment**
- `payment_method` NOT NULL
- `payment_status` DEFAULT 'Pending'
