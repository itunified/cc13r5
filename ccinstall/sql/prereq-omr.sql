alter profile default limit password_verify_function null;
alter system set session_cached_cursors=200 scope=spfile;
alter system set "_allow_insert_with_update_check"=TRUE scope=both;