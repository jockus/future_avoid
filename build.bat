@echo off
rem odin\odin run generate_sine.odin
odin\odin build tools\mod_extract.odin -out:tools\mod_extract.exe && tools\mod_extract assets/title.mod assets/title.instr

rem odin\odin build src -out:build/cart.wasm -target:freestanding_wasm32 -no-entry-point -disable-assert -no-bounds-check -no-crt -extra-linker-flags:"--import-memory -zstack-size=8192 --initial-memory=65536 --max-memory=65536 --global-base=6560 --lto-O3 --gc-sections --strip-all" && w4 run-native build/cart.wasm
odin\odin build src -out:build/cart.wasm -target:freestanding_wasm32 -no-entry-point -disable-assert -no-bounds-check -no-crt -extra-linker-flags:"--import-memory -zstack-size=8192 --initial-memory=65536 --max-memory=65536 --global-base=6560 --lto-O3 --gc-sections --strip-all" && w4 run build/cart.wasm
