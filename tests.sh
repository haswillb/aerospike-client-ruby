#!/bin/bash

# vanilla
echo "100% write"
time bundle exec ruby /tools/benchmark/benchmark.rb -h 192.168.99.100 -k 100

echo "50% read 50% write"
time bundle exec ruby /tools/benchmark/benchmark.rb -h 192.168.99.100 -k 100 -w RW,50

echo "50% read 50% update"
time bundle exec ruby /tools/benchmark/benchmark.rb -h 192.168.99.100 -k 100 -w RU,50
