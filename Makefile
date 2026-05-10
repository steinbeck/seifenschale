SCAD       := seifenschale.scad
OPENSCAD   := openscad
BUILD      := build
IMG_SIZE   := 1200,900
COLORSCHEME := Tomorrow

CAM_ASSEMBLED := 0,30,30,60,0,30,400
CAM_EXPLOSION := 0,30,60,60,0,30,500
CAM_PRINT     := -5,20,30,55,0,30,650

RENDERS := $(BUILD)/assembled.png $(BUILD)/explosion.png $(BUILD)/print.png
STLS    := $(BUILD)/wandhalterung.stl $(BUILD)/schale.stl $(BUILD)/gitter.stl $(BUILD)/print.stl

.PHONY: all renders stls clean check
all: renders stls

renders: $(RENDERS)
stls:    $(STLS)

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/assembled.png: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q -o $@ \
		-D 'mode="assembled"' \
		--imgsize=$(IMG_SIZE) --colorscheme=$(COLORSCHEME) \
		--camera=$(CAM_ASSEMBLED) $<

$(BUILD)/explosion.png: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q -o $@ \
		-D 'mode="explosion"' \
		--imgsize=$(IMG_SIZE) --colorscheme=$(COLORSCHEME) \
		--camera=$(CAM_EXPLOSION) $<

$(BUILD)/print.png: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q -o $@ \
		-D 'mode="print"' \
		--imgsize=$(IMG_SIZE) --colorscheme=$(COLORSCHEME) \
		--camera=$(CAM_PRINT) $<

$(BUILD)/wandhalterung.stl: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q --export-format binstl -o $@ -D 'mode="print"' -D 'part="wandhalterung"' $<

$(BUILD)/schale.stl: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q --export-format binstl -o $@ -D 'mode="print"' -D 'part="schale"' $<

$(BUILD)/gitter.stl: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q --export-format binstl -o $@ -D 'mode="print"' -D 'part="gitter"' $<

$(BUILD)/print.stl: $(SCAD) | $(BUILD)
	$(OPENSCAD) -q --export-format binstl -o $@ -D 'mode="print"' -D 'part="all"' $<

check: stls
	bash tests/run_checks.sh

clean:
	rm -rf $(BUILD)
