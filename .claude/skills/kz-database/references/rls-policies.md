# RLS Policies — KZ Serviços Database

All tables have RLS enabled. Policies use `auth.uid()` and `public.get_user_role()`.

## Helper Functions

```sql
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS user_role AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;
```

```sql
-- Quebra o ciclo entre trips_select e trip_driver_candidates_select.
-- SECURITY DEFINER bypassa RLS nas tabelas internas, evitando recursão.
CREATE OR REPLACE FUNCTION public.is_trip_candidate_for_current_user(p_trip_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.trip_driver_candidates tdc
    JOIN public.driver_profiles dp ON dp.id = tdc.driver_profile_id
    JOIN public.provider_profiles pp ON pp.id = dp.provider_profile_id
    WHERE tdc.trip_id = p_trip_id
      AND pp.user_id = auth.uid()
  );
$$;
```

## Policy Summary by Table

### users
| Policy | Operation | Who |
|--------|-----------|-----|
| `users_select` | SELECT | Active users visible to all authenticated; own profile always visible; admin sees all |
| `users_update_own` | UPDATE | Own profile only (`id = auth.uid()`) |
| `users_update_admin` | UPDATE | Admin can update any user |
| `users_insert` | INSERT | Own ID (`id = auth.uid()`) or admin |

### service_categories
| Policy | Operation | Who |
|--------|-----------|-----|
| `service_categories_select` | SELECT | All authenticated |
| `service_categories_admin` | ALL | Admin only |

### provider_profiles
| Policy | Operation | Who |
|--------|-----------|-----|
| `provider_profiles_select` | SELECT | All authenticated |
| `provider_profiles_insert` | INSERT | Own user_id or admin |
| `provider_profiles_update_own` | UPDATE | Own user_id |
| `provider_profiles_update_admin` | UPDATE | Admin |

### driver_profiles
| Policy | Operation | Who |
|--------|-----------|-----|
| `driver_profiles_select` | SELECT | All authenticated |
| `driver_profiles_insert` | INSERT | Owner of provider_profile or admin |
| `driver_profiles_update` | UPDATE | Owner of provider_profile or admin |

### vehicles
| Policy | Operation | Who |
|--------|-----------|-----|
| `vehicles_select` | SELECT | All authenticated |
| `vehicles_insert` | INSERT | Owner of driver_profile (via provider_profile.user_id) or admin |
| `vehicles_update` | UPDATE | Owner or admin |
| `vehicles_delete` | DELETE | Owner or admin |

### vehicle_photos
| Policy | Operation | Who |
|--------|-----------|-----|
| `vehicle_photos_select` | SELECT | All authenticated |
| `vehicle_photos_insert` | INSERT | Owner of vehicle or admin |
| `vehicle_photos_update` | UPDATE | Owner or admin |
| `vehicle_photos_delete` | DELETE | Owner or admin |

### addresses
| Policy | Operation | Who |
|--------|-----------|-----|
| `addresses_select` | SELECT | All authenticated |
| `addresses_insert` | INSERT | All authenticated |

### trips
| Policy | Operation | Who |
|--------|-----------|-----|
| `trips_select` | SELECT | client_id, driver (via driver_profile), candidate (via `is_trip_candidate_for_current_user`), or admin |
| `trips_insert` | INSERT | Client only (`client_id = auth.uid()` AND `role = 'client'`) |
| `trips_update` | UPDATE | Participants or admin |

### trip_children, trip_luggage
Policies follow the parent `trips` table — access based on trip ownership.

### trip_status_history
| Policy | Operation | Who |
|--------|-----------|-----|
| `trip_status_history_select` | SELECT | Trip participants or admin |
| `trip_status_history_insert` | INSERT | All authenticated (trigger-driven) |

### trip_driver_candidates
| Policy | Operation | Who |
|--------|-----------|-----|
| `trip_driver_candidates_select` | SELECT | Trip client, trip's confirmed driver, the candidate driver themselves, or admin |
| `trip_driver_candidates_insert` | INSERT | Admin only |
| `trip_driver_candidates_update` | UPDATE | Own driver or admin |
| `trip_driver_candidates_delete` | DELETE | Admin only |

### service_requests
| Policy | Operation | Who |
|--------|-----------|-----|
| `service_requests_select` | SELECT | client_id, provider (via provider_profile), or admin |
| `service_requests_insert` | INSERT | Client only (`client_id = auth.uid()` AND `role = 'client'`) |
| `service_requests_update` | UPDATE | Participants or admin |

### service_request_status_history
| Policy | Operation | Who |
|--------|-----------|-----|
| `sr_status_history_select` | SELECT | Service request participants or admin |
| `sr_status_history_insert` | INSERT | All authenticated (trigger-driven) |

### chat_rooms
| Policy | Operation | Who |
|--------|-----------|-----|
| `chat_rooms_select` | SELECT | client_id, provider_id, or admin |
| `chat_rooms_insert` | INSERT | Participants or admin |

### chat_messages
| Policy | Operation | Who |
|--------|-----------|-----|
| `chat_messages_select` | SELECT | Participants of chat_room |
| `chat_messages_insert` | INSERT | sender_id = auth.uid() AND is participant |
| `chat_messages_update` | UPDATE | Participants (for marking read) |

### notifications
| Policy | Operation | Who |
|--------|-----------|-----|
| `notifications_select` | SELECT | Own user_id only |
| `notifications_update` | UPDATE | Own user_id only |
| `notifications_insert` | INSERT | All authenticated (system/service role) |

### user_devices
| Policy | Operation | Who |
|--------|-----------|-----|
| `user_devices_all` | ALL | Own user_id only |

### driver_locations
| Policy | Operation | Who |
|--------|-----------|-----|
| `driver_locations_select` | SELECT | Driver owner, client of active trip, or admin |
| `driver_locations_insert` | INSERT | Driver owner only |
| `driver_locations_update` | UPDATE | Driver owner only |

### private_comments
| Policy | Operation | Who |
|--------|-----------|-----|
| `private_comments_select` | SELECT | author_id or admin |
| `private_comments_insert` | INSERT | Providers only (author_id = auth.uid()) |
| `private_comments_update_admin` | UPDATE | Admin only (for admin_response) |

### ratings
| Policy | Operation | Who |
|--------|-----------|-----|
| `ratings_select` | SELECT | All authenticated |
| `ratings_insert` | INSERT | Participants of the trip/service_request |

### provider_category_services
| Policy | Operation | Who |
|--------|-----------|-----|
| `provider_category_services_select` | SELECT | All authenticated |
| `provider_category_services_insert` | INSERT | Own provider or admin |
| `provider_category_services_delete` | DELETE | Own provider or admin |

### system_settings
| Policy | Operation | Who |
|--------|-----------|-----|
| `system_settings_select` | SELECT | Admin only |
| `system_settings_admin` | ALL | Admin only |

## Common RLS Debugging

1. **Error 42501**: "new row violates row-level security policy" — the authenticated user doesn't have permission. Check if the JWT is valid and the user's role matches the policy.
2. **Empty results**: RLS silently filters rows. If a query returns nothing, the user may not have SELECT permission.
3. **Service role bypass**: Use `SUPABASE_SERVICE_ROLE_KEY` on the server to bypass RLS completely (e.g., for admin operations like creating users).
