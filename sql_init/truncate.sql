set @str= (select group_concat(concat('truncate table ', table_name, ';') separator ' ') from information_schma.tables where table_schema= 'wwsg2');
prepare stmt from @str;
execute stmt;
deallocate prepare stmt;