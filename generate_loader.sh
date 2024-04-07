#!/bin/bash

# 输入文件路径
input_file="func12.4.txt"

output=$(sed -n 's/CUDA_ENTRY_ENUM(\(.*\)),/{.name = "\1"},/p' "$input_file")
echo "$output"

echo ""

output=$(sed -n 's/NVML_ENTRY_ENUM(\(.*\)),/{.name = "\1"},/p' "$input_file")
echo "$output"
