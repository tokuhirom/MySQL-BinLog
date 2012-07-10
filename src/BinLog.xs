#include "xshelper.h"
#undef do_open
#undef do_close
#undef io
#include "binlog_api.h"

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
    dTARG;
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
    dTARG;
    XS_DEBLESS(sv_self, mysql::Binary_log_event*, event);
    mXPUSHi(event->get_event_type());

void
get_event_type_str(SV *sv_self)
PPCODE:
    dTARG;
    XS_DEBLESS(sv_self, mysql::Binary_log_event*, event);
    const char *event_type_str = mysql::system::get_event_type_str(event->get_event_type());
    mXPUSHp(event_type_str, strlen(event_type_str));

void
header(SV *sv_self)
PPCODE:
    dTARG;
    XS_DEBLESS(sv_self, mysql::Binary_log_event*, event);
    XPUSHs(XS_BLESS(event->header(), "MySQL::BinLog::Log_event_header"));

void
DESTROY(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Binary_log_event*, event);
    delete event;
    sv_setiv(SvRV(sv_self), 0); // set NULL

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Log_event_header

void
marker(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->marker);

void
timestamp(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->timestamp);

void
type_code(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->type_code);

void
server_id(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->server_id);

void
event_length(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->event_length);

void
next_position(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->next_position);

void
flags(SV * sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Log_event_header*, header);
    mXPUSHi(header->flags);

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Binary_log_event::Query

void
query(SV *sv_self)
PPCODE:
    dTARG;
    // PerlIO_printf(PerlIO_stderr(), "QQQ\n");

    XS_DEBLESS(sv_self, mysql::Query_event*, event);
    SV * ret = newSVpv(event->query.c_str(), event->query.size());
    mXPUSHs(ret);
    XSRETURN(1);

void
db_name(SV *sv_self)
PPCODE:
    dTARG;
    // PerlIO_printf(PerlIO_stderr(), "QQQ\n");

    XS_DEBLESS(sv_self, mysql::Query_event*, event);
    SV * ret = newSVpv(event->db_name.c_str(), event->db_name.size());
    mXPUSHs(ret);
    XSRETURN(1);

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Binary_log_event::Incident

void
message(SV *sv_self)
PPCODE:
    dTARG;
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
    dTARG;
    // PerlIO_printf(PerlIO_stderr(), "QQQ\n");

    XS_DEBLESS(sv_self, mysql::Rotate_event*, event);
    SV * ret = newSVpv(event->binlog_file.c_str(), event->binlog_file.size());
    mXPUSHs(ret);
    XSRETURN(1);

void
binlog_pos(SV *sv_self)
PPCODE:
    dTARG;
    // PerlIO_printf(PerlIO_stderr(), "QQQ\n");

    XS_DEBLESS(sv_self, mysql::Rotate_event*, event);
    mXPUSHi(event->binlog_pos);
    XSRETURN(1);

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Binary_log_event::User_var

void
name(SV *sv_self)
PPCODE:
    dTARG;
    // PerlIO_printf(PerlIO_stderr(), "QQQ\n");

    XS_DEBLESS(sv_self, mysql::User_var_event*, event);
    SV * ret = newSVpv(event->name.c_str(), event->name.size());
    mXPUSHs(ret);
    XSRETURN(1);

void
value(SV *sv_self)
PPCODE:
    dTARG;
    // PerlIO_printf(PerlIO_stderr(), "QQQ\n");

    XS_DEBLESS(sv_self, mysql::User_var_event*, event);
    SV * ret = newSVpv(event->value.c_str(), event->value.size());
    mXPUSHs(ret);
    XSRETURN(1);

MODULE = MySQL::BinLog    PACKAGE = MySQL::BinLog::Binary_log_event::Table_map
