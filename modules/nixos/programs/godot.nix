{ config, lib, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.godot_4 ];
}