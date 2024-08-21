#!/bin/sh

mkdir -p build results

hyperfine --export-json results/gcc.json -N --warmup 10 'gcc -g -o build/main-c-gcc src/main.c'
hyperfine --export-json results/clang.json -N --warmup 10 'clang -g -o build/main-c-clang src/main.c'
hyperfine --export-json results/g++.json -N --warmup 10 'g++ -g -o build/main-cpp-g++ src/main.cpp'
hyperfine --export-json results/clang++.json -N --warmup 10 'clang++ -g -o build/main-cpp-clang++ src/main.cpp'
hyperfine --export-json results/rust-llvm.json -N --warmup 10 'rustc -o build/main-rust-llvm src/main.rs'
hyperfine --export-json results/rust-cranelift.json -N --warmup 10 'rustc -Zcodegen-backend=cranelift -o build/main-rust-cranelift src/main.rs'

cd build
hyperfine --export-json ../results/zig-llvm.json -N --warmup 10 'zig build-exe --name main-zig-llvm ../src/main.zig'
hyperfine --export-json ../results/zig-zig.json -N --warmup 10 'zig build-exe -fno-llvm --name main-zig-zig ../src/main.zig'
cd ..

results=""
count=0

csv_header() {
    printf ","
    i=1
    for f in $results; do
        run="${f%.json}"

        [ $i -lt $count ] && printf "%s," $run || printf "%s\n" $run

        i=$(( i + 1 ))
    done
}

csv_metric() {
    printf "%s," "$1"
    i=1
    for f in $results; do
        value=$(jq -r ".results[0].$1" results/$f)

        [ $i -lt $count ] && printf "%f," $value || printf "%f\n" $value

        i=$(( i + 1 ))
    done
}

results=$(ls results)
count=$(ls -1 results | wc -l)

csv_header
csv_metric "mean"
csv_metric "median"
csv_metric "stddev"
