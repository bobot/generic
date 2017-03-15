.PHONY: all

include targets.mk

PUBLISH=../gh-pages

all: $(MD_FILES)

targets.mk:
	echo "MD_FILES=`ls *.org | sed -e 's/\.org/.md/g'` " > targets.mk

%.md : %.org
	pandoc $< -o $(PUBLISH)/$@
