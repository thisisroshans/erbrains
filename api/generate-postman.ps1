$ErrorActionPreference = "Stop"

$output = Join-Path $PSScriptRoot "Wearable-Health-API.postman_collection.json"

function JsonRequest {
    param(
        [string]$Method,
        [string]$Path,
        [string]$Body = $null,
        [array]$Tests = @()
    )

    $request = @{
        method = $Method
        header = @(
            @{
                key = "Content-Type"
                value = "application/json"
                type = "text"
            }
        )
        url = @{
            raw = "{{baseUrl}}$Path"
            host = @("{{baseUrl}}")
            path = ($Path.TrimStart("/") -split "/")
        }
    }

    if ($Body) {
        $request.body = @{
            mode = "raw"
            raw = $Body
            options = @{
                raw = @{
                    language = "json"
                }
            }
        }
    }

    $item = @{
        name = "$Method $Path"
        request = $request
    }

    if ($Tests.Count -gt 0) {
        $item.event = @(
            @{
                listen = "test"
                script = @{
                    type = "text/javascript"
                    exec = $Tests
                }
            }
        )
    }

    return $item
}

# ============================================================
# COLLECTION
# ============================================================

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

                header = @(
                    @{
                        key = "Content-Type"
                        value = "application/json"
                    }
                )

                body = @{
                    mode = "raw"
                    raw = @'
{
  "email": "user@example.com",
  "password": "password123"
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
# DEVICES
# ============================================================

$collection.item += @{
    name = "Devices"

    item = @(
        @{
            name = "POST /devices"

            request = @{
                method = "POST"

                header = @(
                    @{
                        key = "Content-Type"
                        value = "application/json"
                    }
                )

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
# HEALTH
# ============================================================

$collection.item += @{
    name = "Health"

    item = @(
        @{
            name = "POST /health/readings"

            request = @{
                method = "POST"

                header = @(
                    @{
                        key = "Content-Type"
                        value = "application/json"
                    }
                )

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
# PRODUCTS
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
# CART
# ============================================================

$collection.item += @{
    name = "Cart"

    item = @(
        @{
            name = "POST /cart"

            request = @{
                method = "POST"

                header = @(
                    @{
                        key = "Content-Type"
                        value = "application/json"
                    }
                )

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
        },

        @{
            name = "GET /cart"

            request = @{
                method = "GET"

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
        }
    )
}

# ============================================================
# ORDERS
# ============================================================

$collection.item += @{
    name = "Orders"

    item = @(
        @{
            name = "POST /orders"

            request = @{
                method = "POST"

                header = @(
                    @{
                        key = "Content-Type"
                        value = "application/json"
                    }
                )

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