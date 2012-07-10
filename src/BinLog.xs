#include "xshelper.h"
#undef do_open
#undef do_close
#undef io
#include "binlog_api.h"
#include "value.h"
#include <iostream>

#define XS_DEBLESS(src, type, dst) \
    type dst; \
    if ( sv_isobject( src ) && ( SvTYPE( SvRV( src ) ) == SVt_PVMG ) ) { \
        dst = (type)SvIV( (SV*)SvRV( src ) ); \
    } else { \
        warn( #src " is not a blessed SV reference" ); \
        XSRETURN_UNDEF; \
    }

#define XS_BLESS(src, klass) \
    sv_bless(newRV_noinc(sv_2mortal(newSViv(PTR2IV(src)))), gv_stashpv(klass, TRUE))

#define BLXS_MAKE_ACCESSOR_STR(type, accessor) \
    XS_DEBLESS(sv_self, type, event); \
    mXPUSHp(event->accessor.c_str(), event->accessor.size());

#define BLXS_MAKE_ACCESSOR_INT(type, accessor) \
    XS_DEBLESS(sv_self, type, event); \
    mXPUSHi(event->accessor);

#define BLXS_MAKE_ACCESSOR_INTARRAY(type, accessor) \
    XS_DEBLESS(sv_self, type, event); \
    std::vector<uint8_t>::iterator iter; \
    for (iter=event->accessor.begin(); iter!=event->accessor.end(); ++iter) { \
        mXPUSHi(*iter); \
    } \
    XSRETURN(event->accessor.size());

namespace BLXS {
    class Row_event_set_iter {
    public:
        Row_event_set_iter(
            SV *row_event_sv,
            SV *table_map_event_sv,
            mysql::Row_event* row_event,
            mysql::Table_map_event* table_map_event)
            : row_event_sv_(row_event_sv)
            , table_map_event_sv_(table_map_event_sv)
            , rows_(row_event, table_map_event)
            , is_first_time_(true) {
            SvREFCNT_inc_void_NN(row_event_sv_);
            SvREFCNT_inc_void_NN(table_map_event_sv_);
            iter_ = rows_.begin();
        }
        ~Row_event_set_iter() {
            SvREFCNT_dec(row_event_sv_);
            SvREFCNT_dec(table_map_event_sv_);
        }
        SV *next() {
            if (!is_first_time_ && iter_ == rows_.end()) {
                return &PL_sv_undef;
            } else {
                mysql::Row_of_fields * fields = new mysql::Row_of_fields(*iter_);
                is_first_time_ = false;
                ++iter_;
                return XS_BLESS(fields, "MySQL::BinLog::Row_of_fields");
            }
        }
    private:
        SV *row_event_sv_;
        SV *table_map_event_sv_;
        mysql::Row_event_set rows_;
        mysql::Row_event_set::iterator iter_;
        bool is_first_time_;
    };
    class Row_of_fields_iter {
    public:
        Row_of_fields_iter(
            SV * row_of_fields_sv,
            mysql::Row_of_fields* row_of_fields)
            :
              row_of_fields_sv_(row_of_fields_sv)
            , row_of_fields_(row_of_fields)
            , is_first_time_(true) {
            SvREFCNT_inc_void_NN(row_of_fields_sv_);
            iter_ = row_of_fields_->begin();
        }
        ~Row_of_fields_iter() {
            SvREFCNT_dec(row_of_fields_sv_);
        }
        SV *next() {
            if (!is_first_time_ && iter_ == row_of_fields_->end()) {
                return &PL_sv_undef;
            } else {
                mysql::Value *value = new mysql::Value(*iter_);
                is_first_time_ = false;
                ++iter_;
                return XS_BLESS(value, "MySQL::BinLog::Value");
            }
        }
    private:
        SV *row_of_fields_sv_;
        mysql::Row_of_fields *row_of_fields_;
        mysql::Row_of_fields::iterator iter_;
        bool is_first_time_;
    };
}

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog

void
new(const char *klass, SV * sv_driver)
PPCODE:
    XS_DEBLESS(sv_driver, mysql::system::Binary_log_driver*, driver);
    mysql::Binary_log * n = new mysql::Binary_log(driver);
    XPUSHs(XS_BLESS(n, "MySQL::BinLog"));
    XSRETURN(1);

void
set_position(SV *sv_self, int i)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Binary_log*, binlogdriver);
    if (binlogdriver->set_position(i) != ERR_OK) {
        croak("Can't reposition the binary log reader.");
    }
    XSRETURN_UNDEF;

void
get_position(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Binary_log*, binlogdriver);
    int pos = binlogdriver->get_position();
    mXPUSHi(pos);

void
connect(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Binary_log*, binlogdriver);
    if (binlogdriver->connect()) {
        croak("Can't connect to the master.");
    }
    XSRETURN_UNDEF;

void
wait_for_next_event(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Binary_log*, binlogdriver);

    mysql::Binary_log_event *event;
    int result = binlogdriver->wait_for_next_event(&event);
    if (result == ERR_EOF) {
        XSRETURN_UNDEF;
    } else {
        // PerlIO_printf(PerlIO_stderr(), "OOO %d\n", event->get_event_type());

        switch (event->get_event_type()) {
        case mysql::QUERY_EVENT:
            XPUSHs(XS_BLESS(event, "MySQL::BinLog::Binary_log_event::Query"));
            break;
        case mysql::INCIDENT_EVENT:
            XPUSHs(XS_BLESS(event, "MySQL::BinLog::Binary_log_event::Incident"));
            break;
        case mysql::ROTATE_EVENT:
            XPUSHs(XS_BLESS(event, "MySQL::BinLog::Binary_log_event::Rotate"));
            break;
        case mysql::USER_VAR_EVENT:
            XPUSHs(XS_BLESS(event, "MySQL::BinLog::Binary_log_event::User_var"));
            //PerlIO_printf(PerlIO_stderr(), "OOO %d\n", event->get_event_type());
            break;
        case mysql::WRITE_ROWS_EVENT:
        case mysql::UPDATE_ROWS_EVENT:
        case mysql::DELETE_ROWS_EVENT:
            XPUSHs(XS_BLESS(event, "MySQL::BinLog::Binary_log_event::Row"));
            break;
        case mysql::TABLE_MAP_EVENT:
            XPUSHs(XS_BLESS(event, "MySQL::BinLog::Binary_log_event::Table_map"));
            //PerlIO_printf(PerlIO_stderr(), "OOO %d\n", event->get_event_type());
            break;
        default:
            XPUSHs(XS_BLESS(event, "MySQL::BinLog::Binary_log_event"));
            break;
        }
        XSRETURN(1);
    }

void
DESTROY(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Binary_log*, binlogdriver);
    delete binlogdriver;
    sv_setiv(SvRV(sv_self), 0); // set NULL

void
create_transport(const char *url)
PPCODE:
    mysql::system::Binary_log_driver * driver = mysql::system::create_transport(url);
    if (!driver) {
        croak("Cannot parse driver");
    }
    XPUSHs(sv_bless(newRV_noinc(sv_2mortal(newSViv(PTR2IV(driver)))), gv_stashpv("MySQL::BinLog::Binary_log_driver", TRUE)));
    XSRETURN(1);

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Binary_log_event

void
get_event_type(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Binary_log_event*, event);
    mXPUSHi(event->get_event_type());

void
get_event_type_str(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Binary_log_event*, event);
    const char *event_type_str = mysql::system::get_event_type_str(event->get_event_type());
    mXPUSHp(event_type_str, strlen(event_type_str));

void
DESTROY(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Binary_log_event*, event);
    delete event;
    sv_setiv(SvRV(sv_self), 0); // set NULL

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Log_event_header

void
_marker(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->marker);

void
_timestamp(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->timestamp);

void
_type_code(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->type_code);

void
_server_id(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->server_id);

void
_event_length(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->event_length);

void
_next_position(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->next_position);

void
_flags(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->flags);

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Binary_log_event::Query

void
query(SV *sv_self)
PPCODE:
    // PerlIO_printf(PerlIO_stderr(), "QQQ\n");

    XS_DEBLESS(sv_self, mysql::Query_event*, event);
    SV * ret = newSVpv(event->query.c_str(), event->query.size());
    mXPUSHs(ret);
    XSRETURN(1);

void
db_name(SV *sv_self)
PPCODE:
    // PerlIO_printf(PerlIO_stderr(), "QQQ\n");

    XS_DEBLESS(sv_self, mysql::Query_event*, event);
    SV * ret = newSVpv(event->db_name.c_str(), event->db_name.size());
    mXPUSHs(ret);
    XSRETURN(1);

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Binary_log_event::Incident

void
message(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Incident_event*, event);
    SV * ret = newSVpv(event->message.c_str(), event->message.size());
    mXPUSHs(ret);
    XSRETURN(1);

void
type(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Incident_event*, event);
    mXPUSHi(event->type);

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Binary_log_event::Rotate

void
binlog_file(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Rotate_event*, event);
    SV * ret = newSVpv(event->binlog_file.c_str(), event->binlog_file.size());
    mXPUSHs(ret);
    XSRETURN(1);

void
binlog_pos(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Rotate_event*, event);
    mXPUSHi(event->binlog_pos);
    XSRETURN(1);

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Binary_log_event::User_var

void
name(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::User_var_event*, event);
    SV * ret = newSVpv(event->name.c_str(), event->name.size());
    mXPUSHs(ret);
    XSRETURN(1);

void
value(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::User_var_event*, event);
    SV * ret = newSVpv(event->value.c_str(), event->value.size());
    mXPUSHs(ret);
    XSRETURN(1);

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Binary_log_event::Table_map

void
table_id(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_INT(mysql::Table_map_event*, table_id);

void
flags(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_INT(mysql::Table_map_event*, flags);

void
db_name(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_STR(mysql::Table_map_event*, db_name);

void
table_name(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_STR(mysql::Table_map_event*, table_name);

void
columns(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_INTARRAY(mysql::Table_map_event*, columns);

void
metadata(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_INTARRAY(mysql::Table_map_event*, metadata); 

void
null_bits(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_INTARRAY(mysql::Table_map_event*, null_bits);

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Binary_log_event::Row

void
table_id(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_INT(mysql::Row_event*, table_id);

void
flags(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_INT(mysql::Row_event*, flags);

void
columns_len(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_INT(mysql::Row_event*, columns_len);

void
null_bits_len(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_INT(mysql::Row_event*, null_bits_len);

void
columns_before_image(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_INTARRAY(mysql::Row_event*, columns_before_image);

void
used_columns(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_INTARRAY(mysql::Row_event*, used_columns);

void
row(SV *sv_self)
PPCODE:
    BLXS_MAKE_ACCESSOR_INTARRAY(mysql::Row_event*, row);

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Row_event_set

void
_begin(SV *sv_row_event, SV *sv_table_map_event)
PPCODE:
    XS_DEBLESS(sv_row_event, mysql::Row_event*, row_event);
    XS_DEBLESS(sv_table_map_event, mysql::Table_map_event*, table_map_event);
    BLXS::Row_event_set_iter *iter = new BLXS::Row_event_set_iter(sv_row_event, sv_table_map_event, row_event, table_map_event);
    XPUSHs(XS_BLESS(iter, "MySQL::BinLog::Row_event_set::iterator"));

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Row_event_set::iterator

void
next(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, BLXS::Row_event_set_iter*, iter);
    XPUSHs(iter->next());

void
DESTROY(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, BLXS::Row_event_set_iter*, iter);
    delete iter;
    sv_setiv(SvRV(sv_self), 0); // set NULL

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Row_of_fields

void
size(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Row_of_fields*, fields);
    mXPUSHi(fields->size());

void
begin(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Row_of_fields*, fields);
    BLXS::Row_of_fields_iter *iter = new BLXS::Row_of_fields_iter(sv_self, fields);
    XPUSHs(XS_BLESS(iter, "MySQL::BinLog::Row_of_fields::iterator"));

void
DESTROY(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Row_of_fields*, fields);
    delete fields;
    sv_setiv(SvRV(sv_self), 0); // set NULL

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Row_of_fields::iterator

void
next(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, BLXS::Row_of_fields_iter*, iter);
    XPUSHs(iter->next());

void
DESTROY(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Row_of_fields::iterator*, iter);
    delete iter;
    sv_setiv(SvRV(sv_self), 0); // set NULL

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Value

void
DESTROY(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Value*, val);
    delete val;
    sv_setiv(SvRV(sv_self), 0); // set NULL

void
type(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Value*, val);
    mXPUSHi(val->type());

void
length(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Value*, val);
    mXPUSHi(val->length());

void
is_null(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Value*, val);
    XPUSHs(val->is_null() ? &PL_sv_yes : &PL_sv_no);

void
as_string(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Value*, val);
    mysql::Converter converter;
    std::string key;
    converter.to(key, *val);
    mXPUSHp(key.c_str(), key.size());

