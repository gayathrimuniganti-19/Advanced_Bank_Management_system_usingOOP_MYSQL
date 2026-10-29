-- 00_run_all.sql : run everything in the right order from the mysql client:
--   cd database
--   mysql -u root -p < 00_run_all.sql
-- (SOURCE is a mysql client command, so this does not work in Workbench's query tab.)
SOURCE 01_create_database.sql;
SOURCE 02_create_tables.sql;
SOURCE 03_insert_data.sql;
SOURCE 05_views.sql;
SOURCE 07_functions.sql;
SOURCE 06_procedures.sql;
SOURCE 08_triggers.sql;
SOURCE 09_indexes.sql;
