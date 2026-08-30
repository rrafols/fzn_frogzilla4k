# "Frogzilla" - Fuzzion, 2004 - WebGL port
#
# There is no build: the intro is ES modules, served as they are.  These
# targets are the tooling around it.
#
#   make bundle     flatten it into one file that opens without a server
#   make pack       the same file, minified and roadrolled as small as it goes
#   make pack-verify  check the minified build computes what the source does
#   make serve      serve the repository and print the URL
#   make verify     render the thirteen reference frames and compare them
#                   (SWIFT=1 to rasterise in software rather than on the GPU)
#   make audio      mix the tune in node and compare it with song.wav
#   make bench      time 120 frames and print where the frame goes
#                   (LO=17000 HI=86000 to time just the city)
#   make shot N=3   render one frame to build/shotN.png (DIFF=1 for the delta)
#   make data       regenerate src/data.js from ../../common/data

COMMON := ../../common
PORT   ?= 8000
N      ?= 0
LO     ?= 200
HI     ?= 102200

.PHONY: bundle pack pack-verify serve verify audio bench shot data clean

# index.html and src/ already depend on nothing outside this directory, so the
# port copies anywhere as it is - but ES modules will not load over file://.
# This inlines them into a single build/frogzilla.html that opens by double-clicking.
bundle: | build
	@python3 tools/bundle.py

# terser and roadroller come from npx, so the first run needs the network.
pack: | build
	@python3 tools/pack.py

pack-verify: | build
	@python3 tools/pack.py --check
	@node tools/check_packed.mjs

serve:
	@echo "http://127.0.0.1:$(PORT)/ports/webgl/         the intro"
	@echo "http://127.0.0.1:$(PORT)/ports/webgl/verify.html   the comparison"
	@cd ../.. && python3 -m http.server $(PORT) --bind 127.0.0.1

# Needs the macOS port's reference frames: run `make verify` in
# ../macos-x86_64 first, which leaves them in its build/linked/.
# Renders on the GPU, as the reference frames were.  SWIFT=1 rasterises in
# software instead - reproducible anywhere, but a third rasteriser, and the
# glow multiplies its disagreements by six; see tools/headless.mjs.
verify:
	@node tools/headless.mjs

audio:
	@node tools/check_audio.mjs

# Throughput, not what the intro feels like: no rAF, and every frame drawn as
# fast as it will go.  The vertex pipeline is in JS - that is what keeps the
# arithmetic identical to the macOS port - so drawFrame is the number to watch.
bench:
	@PAGE='tools/bench.html?lo=$(LO)&hi=$(HI)' node tools/headless.mjs

shot: | build
	@node tools/headless.mjs shot $(N) build/shot$(N).png

data:
	@python3 tools/extract_data.py

build:
	@mkdir -p build

clean:
	rm -rf build
