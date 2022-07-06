#!/usr/bin/env bash

#################################
#	Install Basic Packages      #
#################################

## Author	: Thibault MILLANT

## CHANGELOG :
## - 2021.03.10 : Script creation

#################################################
#   Upgrade and Basic package installation      #
#################################################
apt update && apt upgrade -y && apt dist-upgrade -y && apt install -y htop vim git
