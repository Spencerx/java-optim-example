#!/bin/bash

mkdir -p results/usage/

# echo "Analysing..."
# cn --auto --config ~/.continue/anthropic.yaml --format json --verbose -p < tools/prompts/analyse.txt | tee results/usage/analyse-cn.json
# #./tools/claude-usage/claude-usage results/usage/analyse.json > results/usage/analyse-agg.json
# echo "Analyse done."

echo "Optimising..."
#cn --auto --config continuedev/mistral --format json -p < tools/prompts/optimise.txt | tee results/usage/optimise-cn.json
cn --auto --config ~/.continue/config.yaml --format json -p < tools/prompts/optimise.txt | tee results/usage/optimise-cn.json
echo "Optimisation done."
