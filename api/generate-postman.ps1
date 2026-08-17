$ErrorActionPreference = "Stop"

$output = Join-Path $PSScriptRoot "Wearable-Health-API.postman_collection.json"

function AuthHeader {
    @{
        key   = "Authorization"
        value = "Bearer {{token}}"
        type  = "text"
    }
}

function JsonHeader {
    @{
        key   = "Content-Type"
        value = "application/json"
        type  = "text"
    }
}

# ============================================================
# COLLECTION
# ============================================================
# NB: every route except POST /auth/login and the two GET /products
# endpoints requires a valid bearer token (see api/middleware/auth.js).
# Run "POST /auth/login" first — its test script populates {{token}} and
# {{userId}} for every request below.

$collection = @{
    info = @{
        name = "Wearable Health API - Local"
        description = "Generated from the current Wearable Health API."
        schema = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    }

    variable = @(
        @{
            key = "baseUrl"
            value = "http://localhost:3000"
        },
        @{
            key = "userId"
            value = ""
        },
        @{
            key = "token"
            value = ""
        },
        @{
            key = "cartItemId"
            value = ""
        }
    )

    item = @()
}

# ============================================================
# AUTH
# ============================================================

$collection.item += @{
    name = "Auth"
    item = @(
        @{
            name = "POST /auth/login"

            request = @{
                method = "POST"

                header = @(JsonHeader)

                body = @{
                    mode = "raw"
                    raw = @'
{
  "email": "user@example.com",
  "password": "password123",
  "name": "Jordan Lee"
}
'@
                    options = @{
                        raw = @{
                            language = "json"
                        }
                    }
                }

                url = @{
                    raw = "{{baseUrl}}/auth/login"
                    host = @("{{baseUrl}}")
                    path = @("auth", "login")
                }
            }

            event = @(
                @{
                    listen = "test"

                    script = @{
                        type = "text/javascript"

                        exec = @(
                            'pm.test("Status is 200", function () {'
                            '    pm.response.to.have.status(200);'
                            '});'
                            ''
                            'const json = pm.response.json();'
                            ''
                            'pm.test("Token exists", function () {'
                            '    pm.expect(json.token).to.exist;'
                            '});'
                            ''
                            'pm.test("User exists", function () {'
                            '    pm.expect(json.user).to.exist;'
                            '});'
                            ''
                            'if (json.token) {'
                            '    pm.collectionVariables.set("token", json.token);'
                            '}'
                            ''
                            'if (json.user && json.user.id) {'
                            '    pm.collectionVariables.set("userId", json.user.id);'
                            '}'
                        )
                    }
                }
            )
        }
    )
}

# ============================================================
# DEVICES  (auth required)
# ============================================================

$collection.item += @{
    name = "Devices"

    item = @(
        @{
            name = "POST /devices"

            request = @{
                method = "POST"

                header = @(JsonHeader; AuthHeader)

                body = @{
                    mode = "raw"

                    raw = @'
{
  "deviceId": "FITRING-001",
  "name": "Smart Ring 1",
  "userId": "{{userId}}"
}
'@

                    options = @{
                        raw = @{
                            language = "json"
                        }
                    }
                }

                url = @{
                    raw = "{{baseUrl}}/devices"
                    host = @("{{baseUrl}}")
                    path = @("devices")
                }
            }

            event = @(
                @{
                    listen = "test"
                    script = @{
                        type = "text/javascript"
                        exec = @(
                            'pm.test("Status is 201", function () {'
                            '    pm.response.to.have.status(201);'
                            '});'
                        )
                    }
                }
            )
        },

        @{
            name = "GET /devices"

            request = @{
                method = "GET"

                header = @(AuthHeader)

                url = @{
                    raw = "{{baseUrl}}/devices?userId={{userId}}"
                    host = @("{{baseUrl}}")
                    path = @("devices")
                    query = @(
                        @{
                            key = "userId"
                            value = "{{userId}}"
                        }
                    )
                }
            }

            event = @(
                @{
                    listen = "test"
                    script = @{
                        type = "text/javascript"
                        exec = @(
                            'pm.test("Status is 200", function () {'
                            '    pm.response.to.have.status(200);'
                            '});'
                            ''
                            'pm.test("Response is an array", function () {'
                            '    pm.expect(pm.response.json()).to.be.an("array");'
                            '});'
                        )
                    }
                }
            )
        }
    )
}

# ============================================================
# HEALTH  (auth required)
# ============================================================

$collection.item += @{
    name = "Health"

    item = @(
        @{
            name = "POST /health/readings"

            request = @{
                method = "POST"

                header = @(JsonHeader; AuthHeader)

                body = @{
                    mode = "raw"

                    raw = @'
{
  "userId": "{{userId}}",
  "readings": [
    {
      "deviceId": "FITRING-001",
      "timestamp": "2026-08-17T10:00:00Z",
      "heartRate": 72,
      "spo2": 98,
      "steps": 1200
    }
  ]
}
'@

                    options = @{
                        raw = @{
                            language = "json"
                        }
                    }
                }

                url = @{
                    raw = "{{baseUrl}}/health/readings"
                    host = @("{{baseUrl}}")
                    path = @("health", "readings")
                }
            }

            event = @(
                @{
                    listen = "test"
                    script = @{
                        type = "text/javascript"
                        exec = @(
                            'pm.test("Status is 201", function () {'
                            '    pm.response.to.have.status(201);'
                            '});'
                        )
                    }
                }
            )
        },

        @{
            name = "GET /health/readings"

            request = @{
                method = "GET"

                header = @(AuthHeader)

                url = @{
                    raw = "{{baseUrl}}/health/readings?userId={{userId}}&page=1&limit=50"
                    host = @("{{baseUrl}}")
                    path = @("health", "readings")
                    query = @(
                        @{
                            key = "userId"
                            value = "{{userId}}"
                        },
                        @{
                            key = "page"
                            value = "1"
                        },
                        @{
                            key = "limit"
                            value = "50"
                        }
                    )
                }
            }
        },

        @{
            name = "GET /health/summary"

            request = @{
                method = "GET"

                header = @(AuthHeader)

                url = @{
                    raw = "{{baseUrl}}/health/summary?userId={{userId}}"
                    host = @("{{baseUrl}}")
                    path = @("health", "summary")
                    query = @(
                        @{
                            key = "userId"
                            value = "{{userId}}"
                        }
                    )
                }
            }
        }
    )
}

# ============================================================
# PRODUCTS  (public — no Authorization header)
# ============================================================

$collection.item += @{
    name = "Products"

    item = @(
        @{
            name = "GET /products"

            request = @{
                method = "GET"

                url = @{
                    raw = "{{baseUrl}}/products"
                    host = @("{{baseUrl}}")
                    path = @("products")
                }
            }
        },

        @{
            name = "GET /products/:id"

            request = @{
                method = "GET"

                url = @{
                    raw = "{{baseUrl}}/products/PRODUCT_ID"
                    host = @("{{baseUrl}}")
                    path = @("products", "PRODUCT_ID")
                }
            }
        }
    )
}

# ============================================================
# CART  (auth required)
# ============================================================

$collection.item += @{
    name = "Cart"

    item = @(
        @{
            name = "POST /cart"

            request = @{
                method = "POST"

                header = @(JsonHeader; AuthHeader)

                body = @{
                    mode = "raw"

                    raw = @'
{
  "userId": "{{userId}}",
  "productId": "PRODUCT_ID",
  "quantity": 1
}
'@

                    options = @{
                        raw = @{
                            language = "json"
                        }
                    }
                }

                url = @{
                    raw = "{{baseUrl}}/cart"
                    host = @("{{baseUrl}}")
                    path = @("cart")
                }
            }

            event = @(
                @{
                    listen = "test"
                    script = @{
                        type = "text/javascript"
                        exec = @(
                            'const json = pm.response.json();'
                            ''
                            'if (json.id) {'
                            '    pm.collectionVariables.set("cartItemId", json.id);'
                            '}'
                        )
                    }
                }
            )
        },

        @{
            name = "GET /cart"

            request = @{
                method = "GET"

                header = @(AuthHeader)

                url = @{
                    raw = "{{baseUrl}}/cart?userId={{userId}}"
                    host = @("{{baseUrl}}")
                    path = @("cart")
                    query = @(
                        @{
                            key = "userId"
                            value = "{{userId}}"
                        }
                    )
                }
            }
        },

        @{
            name = "PATCH /cart/:id"

            request = @{
                method = "PATCH"

                header = @(JsonHeader; AuthHeader)

                body = @{
                    mode = "raw"

                    raw = @'
{
  "quantity": 3
}
'@

                    options = @{
                        raw = @{
                            language = "json"
                        }
                    }
                }

                url = @{
                    raw = "{{baseUrl}}/cart/{{cartItemId}}"
                    host = @("{{baseUrl}}")
                    path = @("cart", "{{cartItemId}}")
                }
            }
        },

        @{
            name = "DELETE /cart/:id"

            request = @{
                method = "DELETE"

                header = @(AuthHeader)

                url = @{
                    raw = "{{baseUrl}}/cart/{{cartItemId}}"
                    host = @("{{baseUrl}}")
                    path = @("cart", "{{cartItemId}}")
                }
            }
        }
    )
}

# ============================================================
# ORDERS  (auth required)
# ============================================================

$collection.item += @{
    name = "Orders"

    item = @(
        @{
            name = "POST /orders"

            request = @{
                method = "POST"

                header = @(JsonHeader; AuthHeader)

                body = @{
                    mode = "raw"

                    raw = @'
{
  "userId": "{{userId}}"
}
'@

                    options = @{
                        raw = @{
                            language = "json"
                        }
                    }
                }

                url = @{
                    raw = "{{baseUrl}}/orders"
                    host = @("{{baseUrl}}")
                    path = @("orders")
                }
            }
        },

        @{
            name = "GET /orders"

            request = @{
                method = "GET"

                header = @(AuthHeader)

                url = @{
                    raw = "{{baseUrl}}/orders?userId={{userId}}"
                    host = @("{{baseUrl}}")
                    path = @("orders")
                    query = @(
                        @{
                            key = "userId"
                            value = "{{userId}}"
                        }
                    )
                }
            }
        }
    )
}

# ============================================================
# WRITE FILE
# ============================================================

$json = $collection | ConvertTo-Json -Depth 30

[System.IO.File]::WriteAllText(
    $output,
    $json,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Postman collection generated successfully" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output:"
Write-Host $output
Write-Host ""
