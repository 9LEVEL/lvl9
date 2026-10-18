#!/bin/sh
# Sessão RDP: XFCE num D-Bus próprio, para não brigar com a sessão do console.
if test -r /etc/default/locale; then
	set -a; . /etc/default/locale; set +a
fi
if test -r /etc/profile; then
	. /etc/profile
fi
if test -r ~/.profile; then
	. ~/.profile
fi
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-run-session -- /etc/X11/Xsession startxfce4
