.PHONY: check package
check:
	python3 -m unittest discover -s tests -v
	bash -n bin/install
	/usr/lib/qt6/bin/qmllint contents/ui/*.qml

package: check
	python3 scripts/package.py
