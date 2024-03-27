#!/bin/bash

brew install gsed
printf "%s" "Enter your TFC Organization name: "
read tfcorgname
gsed -i "s/IMPORTANT: Change-to-your-own-TFC-Org/$tfcorgname/g" */terraform.tf
