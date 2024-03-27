#!/bin/bash

printf "%s" "Enter your TFC Organization name: "
read tfcorgname
sed -i "s/IMPORTANT: Change-to-your-own-TFC-Org/$tfcorgname/g" */terraform.tf
