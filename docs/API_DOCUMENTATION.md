# SuperMart Pro API Documentation

## Overview

The SuperMart Pro API provides a comprehensive RESTful interface for inventory management operations. All endpoints require authentication unless otherwise specified.

## Base URL

```
Development: http://localhost:8000/api/
Production: https://api.supermart.pro/api/
```

## Authentication

### JWT Token Authentication

All authenticated requests must include a JWT token in the Authorization header:

```http
Authorization: Bearer <access_token>
```

### Obtaining Tokens

**Endpoint:** `POST /api/auth/login/`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "your_password"
}
```

**Response:**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "store_manager",
    "stores": [
      {"id": 1, "name": "Main Store"}
    ]
  }
}
```

### Refreshing Tokens

**Endpoint:** `POST /api/auth/token/refresh/`

**Request:**
```json
{
  "refresh": "<refresh_token>"
}
```

**Response:**
```json
{
  "access": "<new_access_token>"
}
```

---

## Products API

### List Products

**Endpoint:** `GET /api/products/products/`

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `page` | integer | Page number (default: 1) |
| `page_size` | integer | Items per page (default: 20, max: 100) |
| `search` | string | Search in name, SKU, barcode |
| `category` | integer | Filter by category ID |
| `store` | integer | Filter by store ID |
| `status` | string | Filter by status: `active`, `inactive`, `discontinued` |
| `low_stock` | boolean | Filter low stock items |
| `expiring` | boolean | Filter expiring items |
| `ordering` | string | Sort field: `name`, `-created_at`, `price`, etc. |

**Response:**
```json
{
  "count": 150,
  "next": "http://localhost:8000/api/products/products/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Organic Milk",
      "sku": "MILK-001",
      "barcode": "1234567890123",
      "description": "Fresh organic whole milk",
      "category": {
        "id": 1,
        "name": "Dairy"
      },
      "supplier": {
        "id": 1,
        "name": "Farm Fresh Supplies"
      },
      "price": "4.99",
      "cost_price": "3.50",
      "quantity": 50,
      "min_stock_level": 10,
      "max_stock_level": 100,
      "reorder_point": 20,
      "unit": "L",
      "expiry_date": "2025-02-15",
      "batch_number": "BATCH-2025-001",
      "status": "active",
      "image": "http://localhost:8000/media/products/milk.jpg",
      "freshness_score": 85,
      "days_until_expiry": 45,
      "is_low_stock": false,
      "created_at": "2025-01-01T10:00:00Z",
      "updated_at": "2025-01-15T14:30:00Z"
    }
  ]
}
```

### Create Product

**Endpoint:** `POST /api/products/products/`

**Required Fields:**
```json
{
  "name": "Organic Milk",
  "sku": "MILK-001",
  "category": 1,
  "price": "4.99",
  "quantity": 50
}
```

**Optional Fields:**
```json
{
  "barcode": "1234567890123",
  "description": "Fresh organic whole milk",
  "supplier": 1,
  "cost_price": "3.50",
  "min_stock_level": 10,
  "max_stock_level": 100,
  "reorder_point": 20,
  "unit": "L",
  "expiry_date": "2025-02-15",
  "batch_number": "BATCH-2025-001",
  "status": "active",
  "store": 1
}
```

### Get Product

**Endpoint:** `GET /api/products/products/{id}/`

### Update Product

**Endpoint:** `PATCH /api/products/products/{id}/`

### Delete Product

**Endpoint:** `DELETE /api/products/products/{id}/`

### Bulk Operations

**Bulk Update:** `POST /api/products/products/bulk_update/`

```json
{
  "ids": [1, 2, 3],
  "data": {
    "status": "inactive"
  }
}
```

**Bulk Delete:** `POST /api/products/products/bulk_delete/`

```json
{
  "ids": [1, 2, 3]
}
```

---

## Stock Management

### Record Stock Movement

**Endpoint:** `POST /api/products/stock-movements/`

**Request:**
```json
{
  "product": 1,
  "store": 1,
  "movement_type": "in",  // in, out, adjustment, transfer, return
  "quantity": 50,
  "unit_cost": "3.50",
  "reference_number": "PO-2025-001",
  "notes": "Regular stock replenishment"
}
```

### Get Stock History

**Endpoint:** `GET /api/products/stock-movements/`

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `product` | integer | Filter by product ID |
| `store` | integer | Filter by store ID |
| `movement_type` | string | Filter by type |
| `date_from` | date | Start date (YYYY-MM-DD) |
| `date_to` | date | End date (YYYY-MM-DD) |

---

## Expiry Management

### Get Expiring Products

**Endpoint:** `GET /api/products/products/expiring_soon/`

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `days` | integer | Days threshold (default: 7) |
| `store` | integer | Filter by store ID |

**Response:**
```json
{
  "summary": {
    "total_expiring": 15,
    "critical": 3,
    "warning": 7,
    "notice": 5,
    "estimated_loss": "245.50"
  },
  "products": [
    {
      "id": 1,
      "name": "Organic Milk",
      "expiry_date": "2025-01-20",
      "days_until_expiry": 5,
      "quantity": 10,
      "price": "4.99",
      "potential_loss": "49.90",
      "urgency": "critical",
      "suggested_action": "Consider marking down by 30%"
    }
  ]
}
```

---

## Analytics API

### Dashboard Metrics

**Endpoint:** `GET /api/products/smart-analytics/dashboard_metrics/`

**Response:**
```json
{
  "total_products": 1250,
  "active_products": 1180,
  "total_value": "125000.00",
  "expiring_soon": 23,
  "low_stock": 15,
  "out_of_stock": 5,
  "today_sales": "4580.50",
  "week_sales": "28500.00",
  "month_sales": "125000.00",
  "waste_rate": "2.3",
  "inventory_turnover": "4.5",
  "freshness_score": 87
}
```

### AI Demand Forecast

**Endpoint:** `GET /api/products/smart-analytics/demand_forecast/`

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `product_id` | integer | Product ID (optional) |
| `category_id` | integer | Category ID (optional) |
| `days` | integer | Forecast period (default: 30) |

**Response:**
```json
{
  "forecast_period": "30 days",
  "predictions": [
    {
      "product_id": 1,
      "product_name": "Organic Milk",
      "current_stock": 50,
      "predicted_demand": 120,
      "confidence": 0.85,
      "recommended_order": 100,
      "recommended_order_date": "2025-01-25"
    }
  ],
  "category_trends": [
    {
      "category": "Dairy",
      "trend": "increasing",
      "growth_rate": "5.2%"
    }
  ]
}
```

### AI Recommendations

**Endpoint:** `GET /api/products/smart-analytics/ai_recommendations/`

**Response:**
```json
{
  "recommendations": [
    {
      "type": "reorder",
      "priority": "high",
      "title": "Restock Organic Milk",
      "description": "Stock level below reorder point",
      "action": "Order 100 units",
      "product_id": 1,
      "potential_impact": "Prevent stockout"
    },
    {
      "type": "markdown",
      "priority": "medium",
      "title": "Mark down expiring yogurt",
      "description": "15 units expiring in 3 days",
      "action": "Apply 25% discount",
      "product_id": 5,
      "potential_impact": "Recover $45 from potential waste"
    }
  ]
}
```

---

## Multi-Store Management

### List Stores

**Endpoint:** `GET /api/products/stores/`

### Store Transfer

**Endpoint:** `POST /api/products/store-transfers/`

**Request:**
```json
{
  "from_store": 1,
  "to_store": 2,
  "items": [
    {
      "product": 1,
      "quantity": 20
    },
    {
      "product": 2,
      "quantity": 15
    }
  ],
  "notes": "Emergency stock transfer"
}
```

---

## Error Responses

### Standard Error Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "price": ["Ensure this value is greater than 0."]
    }
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `AUTHENTICATION_FAILED` | 401 | Invalid or expired token |
| `PERMISSION_DENIED` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 400 | Invalid input data |
| `RATE_LIMITED` | 429 | Too many requests |
| `SERVER_ERROR` | 500 | Internal server error |

---

## Rate Limiting

| Endpoint Type | Anonymous | Authenticated |
|---------------|-----------|---------------|
| General API | 100/hour | 1000/hour |
| Authentication | 20/hour | 50/hour |
| Analytics | N/A | 200/hour |
| Bulk Operations | N/A | 50/hour |

---

## Webhooks

Configure webhooks to receive real-time notifications:

**Endpoint:** `POST /api/webhooks/`

**Events:**
- `product.created`
- `product.updated`
- `stock.low`
- `stock.out`
- `expiry.warning`
- `order.created`
- `transfer.completed`

---

## SDK & Libraries

- **Python**: `pip install supermart-pro-sdk`
- **JavaScript**: `npm install @supermart/api-client`
- **Flutter**: `flutter pub add supermart_api`

---

## Support

- **API Status**: https://status.supermart.pro
- **Documentation**: https://docs.supermart.pro
- **Support**: api-support@supermart.pro
