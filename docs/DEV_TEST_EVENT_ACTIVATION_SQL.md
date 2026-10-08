# DEV Test Event Activation SQL

This runbook makes representative activities available for development waiver
testing. It is intended for the shared DEV database or a restored local DEV
database only.

Do not run this against Production without explicit approval. These statements
change event visibility, registration dates, capacity, and active status.

## Important table names

The application uses:

- `tblcamp_class_group` for camp/class groups.
- `tblcamp_class` for both camp sessions and fitness classes.

There is no `tblcamp_group` table in the tested database.

These statements update existing rows; they do not insert new events.

## Activities used for testing

The tested DEV records were:

| Activity | Table | ID | Group |
| --- | --- | ---: | ---: |
| Santa’s Workshop | `tblcamp_class` | `455` | `55` |
| Kids’ Night Out | `tblcamp_class` | `456` | `55` |
| Child Fitness | `tblcamp_class` | `447` | `7` |
| Adult Fitness | `tblcamp_class` | `448` | `37` |

The store ID used during testing was `2`.

## Inspect the current records first

```sql
SELECT id, fk_store_id, fk_group_id, is_camp, active,
       theme, short_description,
       date_reg_start, date_reg_ends,
       date_display_start, date_display_end,
       max_no_in_class, no_enrolled
FROM tblcamp_class
WHERE id IN (447, 448, 455, 456)
ORDER BY id;

SELECT id, fk_store_id, is_camp, name, active,
       date_display_start, date_display_end
FROM tblcamp_class_group
WHERE id IN (7, 37, 55)
ORDER BY id;
```

## Activate the test groups and events

Run this while connected to the DEV database:

```sql
START TRANSACTION;

-- Holiday Camps group: Santa's Workshop and Kids' Night Out.
UPDATE tblcamp_class_group
SET active = 1,
    date_display_start = '2026-01-01',
    date_display_end = '2026-12-31'
WHERE id = 55
  AND fk_store_id = 2
  AND is_camp = 1;

-- Santa's Workshop and Kids' Night Out.
UPDATE tblcamp_class
SET active = 1,
    date_reg_start = '2026-01-01',
    date_reg_ends = '2026-12-31',
    date_display_start = '2026-01-01',
    date_display_end = '2026-12-31'
WHERE id IN (455, 456)
  AND fk_store_id = 2
  AND fk_group_id = 55
  AND is_camp = 1;

-- Child Fitness and Adult Fitness groups.
UPDATE tblcamp_class_group
SET active = 1,
    date_display_start = '2026-01-01',
    date_display_end = '2026-12-31'
WHERE id IN (7, 37)
  AND fk_store_id = 2
  AND is_camp = 0;

-- Child Fitness and Adult Fitness classes.
UPDATE tblcamp_class
SET active = 1,
    date_reg_start = '2026-01-01',
    date_reg_ends = '2026-12-31',
    date_display_start = '2026-01-01',
    date_display_end = '2026-12-31'
WHERE id IN (447, 448)
  AND fk_store_id = 2
  AND is_camp = 0;

COMMIT;
```

## Verify the result

```sql
SELECT id, fk_store_id, fk_group_id, is_camp, active,
       theme, short_description,
       date_reg_start, date_reg_ends,
       date_display_start, date_display_end,
       max_no_in_class, no_enrolled
FROM tblcamp_class
WHERE id IN (447, 448, 455, 456)
ORDER BY id;

SELECT id, fk_store_id, is_camp, name, active,
       date_display_start, date_display_end
FROM tblcamp_class_group
WHERE id IN (7, 37, 55)
ORDER BY id;
```

The events must be active, their display dates must include today, and their
registration dates must not have ended. The class capacity must also exceed
`no_enrolled`.

## If a transaction must be cancelled

Before `COMMIT`, inspect the updates and use:

```sql
ROLLBACK;
```

After testing, restore the original dates, active flags, and capacity if the
DEV database is expected to represent historical production-like data rather
than an always-available test catalog.

