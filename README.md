Testing `-l` option
```bash
hyperfine --warmup 10  --shell=none 'wc -l large_test.txt' 'zig-out/bin/zwc -l large_test.txt'
Benchmark 1: wc -l large_test.txt
  Time (mean ± σ):      18.2 ms ±   2.6 ms    [User: 7.4 ms, System: 2.1 ms]
  Range (min … max):    13.4 ms …  26.3 ms    141 runs

Benchmark 2: zig-out/bin/zwc -l large_test.txt
  Time (mean ± σ):      17.6 ms ±   4.7 ms    [User: 3.7 ms, System: 4.4 ms]
  Range (min … max):     8.8 ms …  47.8 ms    340 runs

Summary
  zig-out/bin/zwc -l large_test.txt ran
    1.04 ± 0.31 times faster than wc -l large_test.txt
```

Testing `-m` option
```bash
hyperfine --warmup 10  --shell=none 'wc -m large_test.txt' 'zig-out/bin/zwc -m large_test.txt'
Benchmark 1: wc -m large_test.txt
  Time (mean ± σ):      58.9 ms ±   1.5 ms    [User: 45.4 ms, System: 2.2 ms]
  Range (min … max):    54.5 ms …  62.0 ms    52 runs

Benchmark 2: zig-out/bin/zwc -m large_test.txt
  Time (mean ± σ):      19.5 ms ±   4.9 ms    [User: 2.7 ms, System: 4.9 ms]
  Range (min … max):     7.3 ms …  47.9 ms    305 runs

Summary
  zig-out/bin/zwc -m large_test.txt ran
    3.03 ± 0.77 times faster than wc -m large_test.txt
```

Testing `-c` option
```bash
hyperfine --warmup 10  --shell=none 'wc -c large_test.txt' 'zig-out/bin/zwc -c large_test.txt'
Benchmark 1: wc -c large_test.txt
  Time (mean ± σ):      18.6 ms ±   4.1 ms    [User: 1.6 ms, System: 3.6 ms]
  Range (min … max):     8.6 ms …  36.7 ms    200 runs

Benchmark 2: zig-out/bin/zwc -c large_test.txt
  Time (mean ± σ):      16.5 ms ±   5.1 ms    [User: 2.1 ms, System: 3.3 ms]
  Range (min … max):     9.1 ms …  36.5 ms    168 runs

Summary
  zig-out/bin/zwc -c large_test.txt ran
    1.13 ± 0.43 times faster than wc -c large_test.txt
```

Testing `-w` option
```bash
hyperfine --warmup 10  --shell=none 'wc -w large_test.txt' 'zig-out/bin/zwc -w large_test.txt'
Benchmark 1: wc -w large_test.txt
  Time (mean ± σ):      30.6 ms ±   2.1 ms    [User: 18.7 ms, System: 2.1 ms]
  Range (min … max):    24.5 ms …  41.0 ms    101 runs

Benchmark 2: zig-out/bin/zwc -w large_test.txt
  Time (mean ± σ):      20.3 ms ±   1.8 ms    [User: 8.6 ms, System: 2.3 ms]
  Range (min … max):    14.4 ms …  29.1 ms    192 runs

Summary
  zig-out/bin/zwc -w large_test.txt ran
    1.51 ± 0.17 times faster than wc -w large_test.txt
```
