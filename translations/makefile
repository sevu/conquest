# Script to update the files.
# I type "make" in a terminal to run it.

translations:
	wmlxgettext --domain=wesnoth-Conquest --directory=.. --recursive -o wesnoth-Conquest.pot
	msgmerge -U wesnoth-Conquest/de.po wesnoth-Conquest.pot

europe: de/LC_MESSAGES/wesnoth-Conquest_Europe.mo

de/LC_MESSAGES/wesnoth-Conquest_Europe.mo: de/LC_MESSAGES/wesnoth-Conquest_Europe.po
	msgfmt -o de/LC_MESSAGES/wesnoth-Conquest_Europe.mo de/LC_MESSAGES/wesnoth-Conquest_Europe.po

de/LC_MESSAGES/wesnoth-Conquest_Europe.po: wesnoth-Conquest_Europe.pot
	msgmerge -U de/LC_MESSAGES/wesnoth-Conquest_Europe.po wesnoth-Conquest_Europe.pot

wesnoth-Conquest_Europe.pot: ../scenarios/Europe.cfg ../scenarios/AI_TEST_EUROPE.cfg ../scenarios/World.cfg
	wmlxgettext --domain=wesnoth-Conquest_Europe --directory=.. scenarios/Europe.cfg scenarios/AI_TEST_EUROPE.cfg scenarios/World.cfg -o wesnoth-Conquest_Europe.pot
