GETTEXT_PACKAGE = hexchat

all-local:
	@if test -n "$(MSGFMT)"; then \
		for lang in `cat $(srcdir)/LINGUAS`; do \
			if test -f $(srcdir)/$$lang.po; then \
				echo "  MSGFMT $$lang.gmo"; \
				$(MSGFMT) -c -o $$lang.gmo $(srcdir)/$$lang.po || exit 1; \
			fi; \
		done; \
	fi

install-data-local:
	@if test -n "$(MSGFMT)"; then \
		for lang in `cat $(srcdir)/LINGUAS`; do \
			if test -f $$lang.gmo; then \
				dir="$(DESTDIR)$(localedir)/$$lang/LC_MESSAGES"; \
				$(MKDIR_P) "$$dir"; \
				$(INSTALL_DATA) "$$lang.gmo" "$$dir/$(GETTEXT_PACKAGE).mo"; \
			fi; \
		done; \
	fi

uninstall-local:
	@for lang in `cat $(srcdir)/LINGUAS`; do \
		rm -f "$(DESTDIR)$(localedir)/$$lang/LC_MESSAGES/$(GETTEXT_PACKAGE).mo"; \
	done

clean-local:
	-rm -f *.gmo *.mo

EXTRA_DIST = LINGUAS POTFILES POTFILES.skip *.po
