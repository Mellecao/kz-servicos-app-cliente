# API Endpoints — KZ Serviços (Supabase REST)

Base URL: `{SUPABASE_URL}/rest/v1`

All requests require headers:
- `apikey: {SUPABASE_ANON_KEY}` (or service_role key)
- `Authorization: Bearer {JWT_TOKEN}`
- `Content-Type: application/json`
- `Prefer: return=representation` (for INSERT/UPDATE to return the created/updated row)

## Authentication

| Method | URL | Description |
|--------|-----|-------------|
| POST | `/auth/v1/signup` | Cadastrar usuário |
| POST | `/auth/v1/token?grant_type=password` | Login (email + password) |
| POST | `/auth/v1/logout` | Logout |
| POST | `/auth/v1/recover` | Reset password |
| GET | `/auth/v1/user` | Get authenticated user |
| PUT | `/auth/v1/user` | Update user metadata |

## REST API (PostgREST)

All tables follow the same pattern: `GET /rest/v1/{table}`, `POST /rest/v1/{table}`, `PATCH /rest/v1/{table}?id=eq.{uuid}`, `DELETE /rest/v1/{table}?id=eq.{uuid}`

### Users
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/users?select=*` | List users |
| GET | `/rest/v1/users?id=eq.{uuid}` | Get user by ID |
| GET | `/rest/v1/users?role=eq.client` | List clients |
| GET | `/rest/v1/users?role=eq.admin` | List admins |
| POST | `/rest/v1/users` | Create user (requires auth.users first) |
| PATCH | `/rest/v1/users?id=eq.{uuid}` | Update user |

### Service Categories
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/service_categories?select=*` | List categories |
| GET | `/rest/v1/service_categories?service_type=eq.trip` | Trip categories |
| GET | `/rest/v1/service_categories?service_type=eq.other_service` | Other service categories |
| POST | `/rest/v1/service_categories` | Create category (admin) |
| PATCH | `/rest/v1/service_categories?id=eq.{uuid}` | Update category (admin) |

### Provider Profiles
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/provider_profiles?select=*,users(*),service_categories(*)` | List with relations |
| GET | `/rest/v1/provider_profiles?status=eq.pending` | Pending providers |
| POST | `/rest/v1/provider_profiles` | Create profile |
| PATCH | `/rest/v1/provider_profiles?id=eq.{uuid}` | Update (status, bank info, etc.) |

### Driver Profiles
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/driver_profiles?select=*,provider_profiles(*,users(*))` | List with relations |
| POST | `/rest/v1/driver_profiles` | Create driver profile |
| PATCH | `/rest/v1/driver_profiles?id=eq.{uuid}` | Update (availability, CNH, etc.) |

### Vehicles
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/vehicles?driver_profile_id=eq.{uuid}` | List by driver |
| POST | `/rest/v1/vehicles` | Create vehicle |
| PATCH | `/rest/v1/vehicles?id=eq.{uuid}` | Update vehicle |
| DELETE | `/rest/v1/vehicles?id=eq.{uuid}` | Delete vehicle |

### Addresses
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/addresses?id=eq.{uuid}` | Get address |
| POST | `/rest/v1/addresses` | Create address |

### Trips
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/trips?select=*,pickup_address:addresses!pickup_address_id(*),dropoff_address:addresses!dropoff_address_id(*),service_categories(*),users!client_id(*)` | List with relations |
| GET | `/rest/v1/trips?status=eq.open` | Trips by status |
| GET | `/rest/v1/trips?client_id=eq.{uuid}` | Trips by client |
| POST | `/rest/v1/trips` | Create trip |
| PATCH | `/rest/v1/trips?id=eq.{uuid}` | Update trip (status, price, etc.) |

### Trip Children
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/trip_children?trip_id=eq.{uuid}` | List by trip |
| POST | `/rest/v1/trip_children` | Add child |

### Trip Luggage
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/trip_luggage?trip_id=eq.{uuid}` | List by trip |
| POST | `/rest/v1/trip_luggage` | Add luggage |

### Service Requests
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/service_requests?select=*,service_categories(*),addresses(*),users!client_id(*)` | List with relations |
| GET | `/rest/v1/service_requests?status=eq.open` | Open requests |
| POST | `/rest/v1/service_requests` | Create request |
| PATCH | `/rest/v1/service_requests?id=eq.{uuid}` | Update request |

### Chat Rooms
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/chat_rooms?select=*,chat_messages(*)` | List with messages |
| GET | `/rest/v1/chat_rooms?trip_id=eq.{uuid}` | Room by trip |
| GET | `/rest/v1/chat_rooms?service_request_id=eq.{uuid}` | Room by service request |
| POST | `/rest/v1/chat_rooms` | Create room |

### Chat Messages
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/chat_messages?chat_room_id=eq.{uuid}&order=created_at.asc` | Messages in room |
| POST | `/rest/v1/chat_messages` | Send message |
| PATCH | `/rest/v1/chat_messages?id=eq.{uuid}` | Mark as read |

### Notifications
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/notifications?user_id=eq.{uuid}&order=created_at.desc` | User notifications |
| GET | `/rest/v1/notifications?is_read=eq.false` | Unread notifications |
| PATCH | `/rest/v1/notifications?id=eq.{uuid}` | Mark as read |

### Driver Locations
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/driver_locations?driver_profile_id=eq.{uuid}` | Get location |
| POST | `/rest/v1/driver_locations` | Set initial location |
| PATCH | `/rest/v1/driver_locations?driver_profile_id=eq.{uuid}` | Update location |

### Ratings
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/ratings?rated_id=eq.{uuid}` | Ratings for user |
| GET | `/rest/v1/ratings?trip_id=eq.{uuid}` | Ratings for trip |
| POST | `/rest/v1/ratings` | Create rating |

### System Settings (admin only)
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/rest/v1/system_settings` | List all settings |
| GET | `/rest/v1/system_settings?key=eq.{key}` | Get by key |
| POST | `/rest/v1/system_settings` | Create setting |
| PATCH | `/rest/v1/system_settings?key=eq.{key}` | Update setting |

## Supabase Realtime (WebSocket)

Subscribe to changes on these tables:

```typescript
// Driver location tracking
supabase.channel('driver-location')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'driver_locations',
    filter: `driver_profile_id=eq.${driverProfileId}`,
  }, (payload) => { /* handle */ })
  .subscribe();

// Chat messages
supabase.channel('chat')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'chat_messages',
    filter: `chat_room_id=eq.${chatRoomId}`,
  }, (payload) => { /* handle */ })
  .subscribe();

// Notifications
supabase.channel('notifications')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'notifications',
    filter: `user_id=eq.${userId}`,
  }, (payload) => { /* handle */ })
  .subscribe();
```

## Postman Collection

Import `docs/KZ_Servicos_Supabase_API.postman_collection.json` into Postman.

### Variables to configure:
| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Public anon key |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (server only) |
| `ACCESS_TOKEN` | JWT from login |
| `USER_ID`, `TRIP_ID`, etc. | IDs for testing |
