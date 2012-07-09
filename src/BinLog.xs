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
    binlogdriver->set_position(i);
    XSRETURN_UNDEF;

void
connect(SV *sv_self)
PPCODE:
    XS_DEBLESS(sv_self, mysql::Binary_log*, binlogdriver);
    binlogdriver->connect();
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
        case mysql::USER_VAR_EVENT:
            XPUSHs(XS_BLESS(event, "MySQL::BinLog::Binary_log_event::User_var"));
            //PerlIO_printf(PerlIO_stderr(), "OOO %d\n", event->get_event_type());
        default:
            XPUSHs(XS_BLESS(event, "MySQL::BinLog::Binary_log_event"));
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
    XPUSHi(event->get_event_type());

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

