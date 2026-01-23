# modules/nixos/boot/default.nix
# ==============================================================================
# NixOS boot policy: loader selection, kernel params, initrd bits for each host.
# Centralizes GRUB/EFI settings and boot-time toggles.
#
# Goals:
# - Keep boot configuration declarative and centralized (not per-host ad-hoc edits)
# - Support both physical (UEFI) and virtual machines (BIOS / disk device)
# - Enable os-prober (optional) for auto-discovery of other OS installs
# - Provide a deterministic, zero-surprise dual-boot path via EFI chainloading
#
# Notes:
# - os-prober can be unreliable with BTRFS subvol installs (rootflags/subvol=@ issues).
# - EFI chainloading avoids kernel/initrd path issues entirely by delegating boot
#   details to the other OS' own bootloader in the ESP.
#
# Important:
# - Do NOT chainload NixOS -> NixOS GRUB from within NixOS GRUB.
#   That is self-chainloading and can cause confusing loops or add no value.
#   NixOS entries are already managed by GRUB itself.
# ==============================================================================

{ lib, inputs, system, config, pkgs, ... }:

let
  isPhysicalMachine = config.my.host.isPhysicalHost;
  isVirtualMachine  = config.my.host.isVirtualHost;

  # ---------------------------------------------------------------------------
  # ESPs and EFI targets
  # ---------------------------------------------------------------------------

  # Primary ESP (EFI System Partition) UUID as seen from NixOS (mounted at /boot).
  # Verified:
  #   /dev/nvme1n1p1  vfat  UUID="CE59-4A9A"  mounted at /boot
  espUuid = "CE59-4A9A";

  # Where CachyOS installed its EFI binary inside the primary ESP.
  # Verified on your machine:
  #   /boot/EFI/cachyos/grubx64.efi
  cachyEfiPath = "/EFI/cachyos/grubx64.efi";

  # Secondary ESP (sda1) UUID (vfat).
  # Verified:
  #   /dev/sda1  vfat  UUID="9730-D976"
  sdaEspUuid = "9730-D976";

  # NixOS-related EFI binaries that live on the secondary ESP.
  # These are chainload targets, so the paths must exist on sda1.
  nixosEfiPathSda     = "/EFI/NixOS-boot/grubx64.efi";
  systemdBootPathSda  = "/EFI/systemd/systemd-bootx64.efi";
in
{
  # ----------------------------------------------------------------------------
  # Boot loader policy
  # ----------------------------------------------------------------------------
  boot.loader = {
    grub = {
      enable = true;

      # VM vs Physical disk target:
      # - VMs often want an actual device (e.g. /dev/vda) for BIOS installs.
      # - Physical UEFI systems should use "nodev" and install to the ESP.
      device = lib.mkForce (if isVirtualMachine then "/dev/vda" else "nodev");

      # UEFI only on physical machines.
      efiSupport = isPhysicalMachine;

      # Allow GRUB to run os-prober and add other OS installs automatically.
      # (Still keep deterministic chainload entries below.)
      useOSProber = lib.mkDefault true;

      configurationLimit = 10;

      # GRUB gfx settings
      gfxmodeEfi  = "1920x1200";
      gfxmodeBios = if isVirtualMachine then "1920x1080" else "1920x1200";

      # GRUB theme (from flake input)
      theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;

      # ------------------------------------------------------------------------
      # Deterministic dual-boot entries (recommended)
      #
      # Why:
      # - Avoids os-prober pitfalls on BTRFS subvolume installs (missing rootflags)
      # - Avoids kernel/initramfs path mismatches ("/boot/..." not found)
      # - Delegates all boot details to the other OS' own EFI bootloader
      #
      # What we include:
      # - CachyOS chainload via the primary ESP (nvme1n1p1, /boot)
      # - NixOS boot targets living on the secondary ESP (sda1):
      #     - GRUB EFI
      #     - systemd-boot EFI
      #
      # What we explicitly do NOT include:
      # - "NixOS (EFI chainload)" -> /EFI/NixOS/grubx64.efi on the same ESP.
      #   That is self-chainloading from within NixOS GRUB and can loop / is redundant.
      # ------------------------------------------------------------------------
      extraEntries = lib.mkIf isPhysicalMachine ''
        menuentry "CachyOS (EFI chainload)" {
          insmod part_gpt
          insmod fat
          search --no-floppy --fs-uuid --set=root ${espUuid}
          chainloader ${cachyEfiPath}
        }

        menuentry "NixOS (sda1 · EFI chainload)" {
          insmod part_gpt
          insmod fat
          search --no-floppy --fs-uuid --set=root ${sdaEspUuid}
          chainloader ${nixosEfiPathSda}
        }

        menuentry "NixOS (sda1 · systemd-boot)" {
          insmod part_gpt
          insmod fat
          search --no-floppy --fs-uuid --set=root ${sdaEspUuid}
          chainloader ${systemdBootPathSda}
        }
      '';
    };

    # EFI settings for physical machines
    efi = lib.mkIf isPhysicalMachine {
      canTouchEfiVariables = true;
      efiSysMountPoint     = "/boot";
    };
  };

  # ----------------------------------------------------------------------------
  # Packages
  #
  # os-prober is not always installed by default on NixOS.
  # If you rely on GRUB auto-discovery of other OS installs, keep this.
  # If you only use EFI chainloading, this is optional.
  # ----------------------------------------------------------------------------
  environment.systemPackages = lib.mkIf isPhysicalMachine [
    pkgs.os-prober
  ];
}
