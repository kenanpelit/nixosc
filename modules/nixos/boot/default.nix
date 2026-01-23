# modules/nixos/boot/default.nix
# ==============================================================================
# NixOS boot policy: loader selection, kernel params, initrd bits for each host.
# Centralizes GRUB/EFI settings and boot-time toggles.
#
# Goals:
# - Keep boot configuration declarative and centralized (not per-host ad-hoc edits)
# - Support both physical (UEFI) and virtual machines (BIOS / disk device)
# - Prefer deterministic, zero-surprise dual-boot via EFI chainloading
#
# Notes:
# - os-prober is often a trap. We keep it disabled and rely on explicit entries.
# - EFI chainloading avoids kernel/initrd path mismatches by delegating boot
#   details to the other OS' own bootloader in its ESP.
#
# Important:
# - Do NOT chainload NixOS -> NixOS GRUB from within NixOS GRUB.
#   NixOS entries are already managed by GRUB itself.
#
# Reality check (your machine, current state):
# - This NixOS is running from nvme0n1 (see lsblk: /boot = nvme0n1p1, / = nvme0n1p2)
# - CachyOS has a dedicated ESP on /dev/sda1 with:
#     UUID="6880-73B3"
#     /EFI/cachyos/grubx64.efi
# - There is also an ESP on nvme1n1p1 used by CachyOS in some setups; keep it
#   as an optional chainload target only if you really need it.
# ==============================================================================

{ lib, inputs, system, config, pkgs, ... }:

let
  isPhysicalMachine = config.my.host.isPhysicalHost;
  isVirtualMachine  = config.my.host.isVirtualHost;

  # ---------------------------------------------------------------------------
  # ESPs and EFI targets
  # ---------------------------------------------------------------------------

  # NixOS primary ESP mounted at /boot (from your current lsblk).
  # Note: we don't hardcode its UUID here because NixOS already knows /boot and
  # GRUB entries for NixOS generations are handled automatically.

  # CachyOS on SATA disk (sda) — dedicated ESP (recommended target).
  # Verified:
  #   /dev/sda1  vfat  UUID="6880-73B3"
  #   /EFI/cachyos/grubx64.efi
  cachySdaEspUuid = "6880-73B3";
  cachySdaEfiPath = "/EFI/cachyos/grubx64.efi";
  cachySdaFallbackPath = "/EFI/boot/bootx64.efi";

  # Optional: CachyOS living on nvme1 ESP (only enable if you explicitly want it).
  # Fill this UUID from NixOS with:
  #   sudo blkid /dev/nvme1n1p1
  #
  # Example:
  #   nvme1EspUuid = "CE59-4A9A";
  nvme1EspUuid = "CE59-4A9A";
  #nvme1EspUuid = null; # set to a string UUID if/when needed
  cachyNvmeEfiPath = "/EFI/cachyos/grubx64.efi";
in
{
  # ----------------------------------------------------------------------------
  # Boot loader policy
  # ----------------------------------------------------------------------------
  boot.loader = {
    grub = {
      enable = true;

      # VM vs Physical disk target:
      device = lib.mkForce (if isVirtualMachine then "/dev/vda" else "nodev");

      # UEFI only on physical machines.
      efiSupport = isPhysicalMachine;

      # Deterministic only: keep os-prober off.
      useOSProber = false;

      configurationLimit = 10;

      # GRUB gfx settings
      gfxmodeEfi  = "1920x1200";
      gfxmodeBios = if isVirtualMachine then "1920x1080" else "1920x1200";

      # GRUB theme (from flake input)
      theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;

      # ------------------------------------------------------------------------
      # Deterministic chainload entries
      # ------------------------------------------------------------------------
      extraEntries = lib.mkIf isPhysicalMachine (
        ''
          menuentry "CachyOS-Rog (sda1 · GRUB chainload)" {
            insmod part_gpt
            insmod fat
            search --no-floppy --fs-uuid --set=root ${cachySdaEspUuid}
            chainloader ${cachySdaEfiPath}
          }
        ''
        +
        (lib.optionalString (nvme1EspUuid != null) ''
          menuentry "CachyOS-Lenovo (nvme1 ESP · GRUB chainload)" {
            insmod part_gpt
            insmod fat
            search --no-floppy --fs-uuid --set=root ${nvme1EspUuid}
            chainloader ${cachyNvmeEfiPath}
          }
        '')
      );
    };

    # EFI settings for physical machines
    efi = lib.mkIf isPhysicalMachine {
      canTouchEfiVariables = true;
      efiSysMountPoint     = "/boot";
    };
  };

  # ----------------------------------------------------------------------------
  # Packages
  # ----------------------------------------------------------------------------
  environment.systemPackages = lib.mkIf isPhysicalMachine [ ];
}
